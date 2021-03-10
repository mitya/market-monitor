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

  def download_candles(ticker, interval: 'day', since: Date.new(2021, 1, 1), till: Date.tomorrow)
    instrument = Instrument.get(ticker)
    file = Pathname("db/tinkoff-candles-day/#{instrument.ticker} #{till.to_s :number} #{since.to_s :number}.json")
    unless file.exist?
      puts "Load Tinkoff candles for #{instrument}"
      response = `coffee bin/tinkoff.coffee candles #{instrument.figi} day #{since.xmlschema} #{till.xmlschema}`
      file.dirname.mkpath
      file.write response
    end
  end

  def import_candles(directory)
    Pathname(directory).glob('*.json') do |file|
      data = JSON.parse file.read
      instrument = Instrument.get figi: data['figi']
      interval = data['interval']

      # return if instrument.candles.where(interval: interval).where(Candle.arel_table[:time].gteq 1.day.ago.midnight).exists?

      puts "Import #{data['candles'].count} #{interval} candles for #{instrument}"
      Candle.transaction do
        data['candles'].each do |hash|
          instrument.candles.find_or_create_by! interval: hash['interval'], time: Time.parse(hash['time']) do |candle|
            candle.open   = hash['o']
            candle.close  = hash['c']
            candle.high   = hash['h']
            candle.low    = hash['l']
            candle.volume = hash['v']
            candle.ticker = instrument.ticker
            candle.source = 'tinkoff'
          end
        end
      end
    end
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

TinkoffConnector.new.load_candles_to_files('AAPL')
TinkoffConnector.new.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 6, 1), till: Date.new(2020, 12, 31))
TinkoffConnector.new.load_candles_to_files('AAPL', interval: 'day', since: Date.new(2020, 1, 1), till: Date.new(2020, 12, 31))
