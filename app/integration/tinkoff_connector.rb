class TinkoffConnector
  include StaticService

  def import_instruments
    data = JSON.parse File.read "db/data/stocks.json"
    Instrument.transaction do
      data['instruments'].sort_by{|h| h['ticker']}.each do |hash|
        next if Instrument.exists? figi: hash['figi']
        next if hash['ticker'].include?('old')
        puts "Import #{hash['ticker']}"
        Instrument.create! hash.slice(*%w(ticker figi isin lot currency name type lot)).merge(price_step: hash['minPriceIncrement']) do |inst|
          inst.flags = ['tinkoff']
        end
      end
    end
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

  def update_current_price(instrument, **opts)
    since, till = 10.minutes.ago.beginning_of_minute, 1.minute.from_now.beginning_of_minute
    response = `coffee bin/tinkoff.coffee candles #{instrument.figi} 1min #{since.xmlschema} #{till.xmlschema}`
    response_json = JSON.parse(response)
    price = response_json.dig 'candles', -1, 'h'
    printf "Refresh price for %-5s %3i candles price=#{price.inspect}\n", instrument.ticker, response_json['candles'].count
    instrument.price.update! value: price if price
  end

  def import_candles(instrument, data)
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
      import_candles instrument, interval, hash
    end
  end

  def get_candles(instrument, interval: 'day', since: nil, till: nil)
    response = `coffee bin/tinkoff.coffee candles #{instrument.figi} day #{since.xmlschema} #{till.xmlschema}`
    # puts "Load Tinkoff #{interval} candles for [#{since.xmlschema} ... #{till.xmlschema}] #{instrument}"
    JSON.parse response
  end

  def get_candles_and_import(instrument, interval: 'day')
    return if instrument.candles.day.where('date > ?', 2.weeks.ago).none?
    return if instrument.candles.day.todays.where('updated_at > ?', 3.hours.ago).exists?
    since = instrument.candles.day.final.last_loaded_date.tomorrow
    till = Current.date.end_of_day
    data = get_candles instrument, interval: 'day', since: since, till: till
    import_candles instrument, data
    sleep 0.33
  rescue
    puts "Import #{instrument} failed: #{$!}"
  end

  def insider_transactions(ticker)
    get "/stock/#{ticker}/insider-transactions"
  end

  def options(ticker)
    get "/stock/#{ticker}/options"
  end

  def recommedations(ticker)
    get "/stock/#{ticker}/recommendation-trends"
  end

  def last(ticker)
    get "/last?symbols=#{ticker}"
  end

  delegate :logger, to: :Rails
end

__END__

TinkoffConnector.load_candles_to_files('AAPL')
TinkoffConnector.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 6, 1), till: Date.new(2020, 12, 31))
TinkoffConnector.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 1, 1), till: Date.new(2020, 12, 31))
TinkoffConnector.update_current_price Instrument.get('AAPL')
