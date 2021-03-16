class TinkoffConnector
  include StaticService

  def sync_instruments(preview: true)
    file = Pathname("db/data/tinkoff-stocks-#{Date.current.to_s :number}.json")
    file.write `coffee bin/tinkoff.coffee stocks` unless file.exist?

    data = JSON.parse file.read
    problematic_tickers = []
    new_tickers = []
    instruments = data['instruments'].reject { |hash| hash['ticker'].include?('old') }

    instruments.each do |hash|
      if inst = Instrument.find_by_ticker(hash['ticker'])
        if inst.isin != hash['isin']
          puts "#{inst.ticker} ISIN mismatch"
          problematic_tickers << inst.ticker
        end
        if inst.figi != hash['figi']
          puts "#{inst.ticker} FIGI mismatch"
          problematic_tickers << inst.ticker
        end
      else
        puts "#{hash['ticker']} missing!"
        new_tickers << hash['ticker']
      end
    end

    current_tickers = instruments.map { |hash| hash['ticker'] }.to_set
    outdated_tickers = Instrument.tinkoff.reject { |inst| inst.ticker.in? current_tickers }
    puts
    puts "Outdated: #{outdated_tickers}"
    puts "Problematic: #{problematic_tickers + new_tickers}"
    puts

    unless preview
      instruments.
        select { |hash| new_tickers.include? hash['ticker'] }.
        each do |hash|
          puts "Create #{hash['ticker']}"
          Instrument.create! instrument_attrs_from(hash)
        end

      instruments.
        select { |hash| problematic_tickers.include? hash['ticker'] }.
        each do |hash|
          puts "Update #{hash['ticker']}"
          inst = Instrument.get(hash['ticker'])
          inst.candles.delete_all
          inst.price&.destroy
          inst.update! instrument_attrs_from(hash)
        end
    end
  end

  def instrument_attrs_from(hash)
    hash.slice(*%w(ticker figi isin lot currency name type lot)).merge(
      price_step: hash['minPriceIncrement'],
      flags: ['tinkoff'],
    )
  end

  def import_instruments
    data = JSON.parse File.read "db/data/stocks.json"
    Instrument.transaction do
      data['instruments'].sort_by{|h| h['ticker']}.each do |hash|
        next if Instrument.exists? figi: hash['figi']
        next if hash['ticker'].include?('old')
        puts "Import #{hash['ticker']}"
        Instrument.create! instrument_attrs_from(hash)
      end
    end
  end


  def update_current_price(instrument, **opts)
    since, till = 10.minutes.ago.beginning_of_minute, 1.minute.from_now.beginning_of_minute
    response = `coffee bin/tinkoff.coffee candles #{instrument.figi} 1min #{since.xmlschema} #{till.xmlschema}`
    response_json = JSON.parse(response)
    price = response_json.dig 'candles', -1, 'h'
    printf "Refresh price for %-7s %3i candles price=#{price.inspect}\n", instrument.ticker, response_json['candles'].count
    instrument.price.update! value: price if price
  end


  def download_candles(ticker, interval: 'day', since: Candle.last_loaded_date&.tomorrow, till: Date.today.end_of_day, delay: 0.33.second, ongoing: false)
    return if since == till
    instrument = Instrument.get(ticker)
    file = Pathname("db/tinkoff-#{interval}-#{till.to_date.to_s :number}#{'-ongoing' if ongoing}/#{instrument.ticker} #{since.to_s :number} #{till.to_s :number}.json")
    unless file.exist?
      puts "Load Tinkoff #{interval} candles for [#{since.xmlschema} ... #{till.xmlschema}] #{instrument}"
      response = `coffee bin/tinkoff.coffee candles #{instrument.figi} day #{since.xmlschema} #{till.xmlschema}`
      file.dirname.mkpath
      file.write response
      sleep delay
    end
  end

  def download_day_candles_upto_today(ticker, **opts)
    download_candles ticker, interval: 'day', since: Candle.last_loaded_date.tomorrow, till: Date.today, **opts
  end

  def download_ongoing_day_candle(ticker, **opts)
    download_candles ticker, interval: 'day', since: Date.current, till: Date.current.end_of_day, ongoing: true, **opts
  end

  def download_day_candle_for_date(ticker, date, **opts)
    download_candles ticker, interval: 'day', since: date, till: date.end_of_day, **opts
  end


  def import_candles_from_hash(instrument, data)
    interval = data['interval']
    candles = data['candles'].to_a

    # return if instrument.candles.where(interval: interval).where(Candle.arel_table[:time].gteq 1.day.ago.midnight).exists?
    # puts "Import #{candles.count} #{interval} candles for #{instrument}"
    Candle.transaction do
      candles.each do |hash|
        time = Time.parse hash['time']
        puts "Import #{instrument} #{time} #{interval} candle"
        candle = instrument.candles.find_or_initialize_by interval: interval, time: time
        candle.ticker  = instrument.ticker
        candle.source  = 'tinkoff'
        candle.open    = hash['o']
        candle.close   = hash['c']
        candle.high    = hash['h']
        candle.low     = hash['l']
        candle.volume  = hash['v']
        candle.date    = time.to_date
        candle.ongoing = time.to_date == Current.date
        candle.save!
      end
    end
  end

  def import_candles_from_dir(directory)
    Pathname(directory).glob('*.json') do |file|
      data = JSON.parse file.read
      instrument = Instrument.get figi: data['figi']
      import_candles_from_hash instrument, interval, hash
    end
  end

  def import_day_candles(instrument, since:, till:, delay: 0.5)
    data = JSON.parse `coffee bin/tinkoff.coffee candles #{instrument.figi} day #{since.xmlschema} #{till.xmlschema}`
    import_candles_from_hash instrument, data
    sleep delay
  rescue
    puts "Import #{instrument} failed: #{$!}"
  end

  def import_latest_day_candles(instrument)
    return if instrument.candles.day.where('date > ?', 2.weeks.ago).none?
    return if instrument.candles.day.todays.where('updated_at > ?', 3.hours.ago).exists?
    since = instrument.candles.day.final.last_loaded_date.tomorrow
    till = Current.date.end_of_day
    import_day_candles instrument, since: since, till: till
  end

  def import_all_day_candles(instrument)
    import_day_candles instrument, since: Date.parse('2019-01-01'), till: Date.parse('2019-12-31').end_of_day
    import_day_candles instrument, since: Date.parse('2020-01-01'), till: Date.parse('2020-12-31').end_of_day
    import_day_candles instrument, since: Date.parse('2021-01-01'), till: Date.current.end_of_day
  end


  delegate :logger, to: :Rails
end

__END__

TinkoffConnector.load_candles_to_files('AAPL')
TinkoffConnector.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 6, 1), till: Date.new(2020, 12, 31))
TinkoffConnector.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 1, 1), till: Date.new(2020, 12, 31))
TinkoffConnector.update_current_price Instrument.get('AAPL')
Instrument.tinkoff.each { |inst| TinkoffConnector.import_day_candles inst, since: Date.parse('2019-12-31'), till: Date.parse('2019-12-31').end_of_day }
Instrument.tinkoff.each { |inst| TinkoffConnector.import_day_candles inst, since: Date.parse('2020-12-31'), till: Date.parse('2020-12-31').end_of_day }
