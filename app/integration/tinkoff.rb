class Tinkoff
  include StaticService

  OutdatedTickers = %w[
    AGN AIMT AOBC APY AVP AXE BEAT BFYT BMCH CHA CHL CXO CY DLPH DNKN
    ENPL ETFC FTRE HDS HIIQ IMMU LM LOGM LVGO MINI MYL MYOK NBL
    PRSC PRTK RUSP SERV SINA TECD TIF TRCN TSS UTX VAR VRTU WYND
    CHK
  ]

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
    puts "Outdated: #{outdated_tickers.map &:ticker}"
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


  def last_minute_candles(instrument, since = 10.minutes.ago, till = 1.minute.from_now)
    since, till = since.beginning_of_minute, till.beginning_of_minute
    call_js_api "candles #{instrument.figi} 1min #{since.xmlschema} #{till.xmlschema}"
  end

  def update_current_price(instrument, **opts)
    response_json = last_minute_candles instrument, 10.minutes.ago
    candle = response_json.dig 'candles', -1
    price = candle&.dig 'h'
    return puts "No response for #{instrument}: #{response_json}".red if response_json['candles'] == nil
    printf "Refresh Tinkoff price for %-7s %3i candles price=#{price}\n", instrument.ticker, response_json['candles'].count
    instrument.price.update! value: price, last_at: candle['time'], source: 'tinkoff' if price
  end


  def download_candles(ticker, interval: 'day', since: Candle.last_loaded_date&.tomorrow, till: Date.today.end_of_day, delay: 0.1, ongoing: false)
    return if since == till
    instrument = Instrument.get(ticker)
    file = Pathname("db/tinkoff-#{interval}-#{till.to_date.to_s :number}#{'-ongoing' if ongoing}/#{instrument.ticker} #{since.to_s :number} #{till.to_s :number}.json")
    unless file.exist?
      puts "Load Tinkoff #{interval} candles for [#{since.xmlschema} ... #{till.xmlschema}] #{instrument}"
      response = call_js_api "candles #{instrument.figi} day #{since.xmlschema} #{till.xmlschema}", parse: false
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
        puts "Import Tinkoff #{time} #{interval} candle for #{instrument}"
        candle = instrument.candles.find_or_initialize_by interval: interval, time: time
        candle.ticker  = instrument.ticker
        candle.source  = 'tinkoff'
        candle.open    = hash['o']
        candle.close   = hash['c']
        candle.high    = hash['h']
        candle.low     = hash['l']
        candle.volume  = hash['v']
        candle.date    = time.to_date
        candle.ongoing = time.to_date == Current.date && !Current.weekend?
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

  def load_day(instrument, since = Current.date, till = since.to_date.end_of_day)
    call_js_api "candles #{instrument.figi} day #{since.xmlschema} #{till.xmlschema}"
  end

  def import_day_candles(instrument, since:, till:, delay: 0.3)
    data = load_day instrument, since, till
    import_candles_from_hash instrument, data
    sleep delay
  rescue
    puts "Import #{instrument} failed: #{$!}"
  end

  def import_latest_day_candles(instrument, today: true, since: nil)
    return if instrument.candles.day.where('date > ?', 2.weeks.ago).none?
    return if instrument.candles.day.today.where('updated_at > ?', 3.hours.ago).exists?
    since ||= instrument.candles.day.final.last_loaded_date.tomorrow
    till = today ? Current.date.end_of_day : Current.yesterday.end_of_day
    return if till < since
    import_day_candles instrument, since: since, till: till
  end

  def import_all_day_candles(instrument, years: [2019, 2020, 2021])
    import_day_candles instrument, since: Date.parse('2019-01-01'), till: Date.parse('2019-12-31').end_of_day if years.include?(2019)
    import_day_candles instrument, since: Date.parse('2020-01-01'), till: Date.parse('2020-12-31').end_of_day if years.include?(2020)
    import_day_candles instrument, since: Date.parse('2021-01-01'), till: Date.current.end_of_day if years.include?(2021)
  end

  def call_js_api(command, parse: true)
    command = "coffee bin/tinkoff.coffee #{command}"
    puts command.purple if $log_tinkoff
    response = `#{command}`
    parse ? JSON.parse(response) : response
  rescue => e
    puts "Error parsing JSON for #{command}".red
    parse ? { } : ''
  end

  delegate :logger, to: :Rails
end

__END__

Tinkoff.load_candles_to_files('AAPL')
Tinkoff.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 6, 1), till: Date.new(2020, 12, 31))
Tinkoff.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 1, 1), till: Date.new(2020, 12, 31))
Tinkoff.update_current_price Instrument.get('AAPL')
Tinkoff.import_latest_day_candles Instrument['PRGS']
Instrument.tinkoff.each { |inst| Tinkoff.import_day_candles inst, since: Date.parse('2019-12-31'), till: Date.parse('2019-12-31').end_of_day }
Instrument.tinkoff.each { |inst| Tinkoff.import_day_candles inst, since: Date.parse('2020-12-31'), till: Date.parse('2020-12-31').end_of_day }
