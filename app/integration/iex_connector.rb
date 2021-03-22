# https://iexcloud.io/console/
# https://iexcloud.io/docs/api
class IexConnector
  include StaticService

  BASE = 'https://cloud.iexapis.com/stable'

  def quote(symbol)                   = get("/stock/#{symbol}/quote")
  def ohlc(symbol)                    = get("/stock/#{symbol}/ohlc")
  def previous(symbol)                = get("/stock/#{symbol}/previous")
  def options(symbol)                 = get("/stock/#{symbol}/options")
  def insider_transactions(symbol)    = get("/stock/#{symbol}/insider-transactions")
  def recommedations(symbol)          = get("/stock/#{symbol}/recommendation-trends")
  def price_target(symbol)            = get("/stock/#{symbol}/price-target")
  def estimates(symbol)               = get("/stock/#{symbol}/estimates", period: 'annual')
  def logo(symbol)                    = get("/stock/#{symbol}/logo")
  def company(symbol)                 = get("/stock/#{symbol}/company")
  def stats(symbol)                   = get("/stock/#{symbol}/stats")
  def day_candle_on(symbol, date)     = get("/stock/#{symbol}/chart/date/#{date.to_s :number}", chartByDay: true)
  def day_candles_for(symbol, period) = get("/stock/#{symbol}/chart/#{period}")
  def last(symbol)                    = get("/last?symbols=#{symbol}")
  def tops(*symbols)                  = get("/tops", { symbols: symbols.join(',').presence }.compact)
  def symbols                         = get("/ref-data/symbols")

  def import_day_candles(instrument, date: nil, period: nil)
    return if date && instrument.candles.day.where(date: date).exists?

    candles_data =
      date ? day_candle_on(instrument.ticker, date) :
      period == 'previous' ? [previous(instrument.ticker)] :
      day_candles_for(instrument.ticker, period)

    return puts "No IEX data on #{date || period} for #{instrument}" if candles_data.none?

    Candle.transaction do
      candles_data.each do |hash|
        date = Date.parse hash['date']
        puts "Import IEX #{date} candle for #{instrument}"
        candle = instrument.candles.find_or_initialize_by interval: 'day', date: date, source: 'iex'
        candle.ticker  = instrument.ticker
        candle.time    = date.to_time :utc
        candle.ongoing = date == Current.date
        candle.open    = hash['open']
        candle.close   = hash['close']
        candle.high    = hash['high']
        candle.low     = hash['low']
        candle.volume  = hash['volume']
        candle.save!
      end
    end
  end

  def import_today_candle(instrument)
    data = quote(instrument.ticker)
    candle = instrument.candles.day.find_or_initialize_by date: Current.date
    return if candle.persisted? && candle.final?

    puts "Import IEX today (#{Current.date}) candle for #{instrument}"
    candle.ticker  = instrument.ticker
    candle.source  = 'iex'
    candle.ongoing = true
    candle.time    = Time.ms data['lastTradeTime']
    candle.open    = data['open']  || data['iexOpen']  # || data['latestPrice']
    candle.close   = data['close'] || data['iexClose'] # || data['latestPrice']
    candle.high    = data['high']                      || data['latestPrice']
    candle.low     = data['low']                       || data['latestPrice']
    candle.volume  = data['latestVolume']
    candle.save!
  rescue e
    puts "IEX today candle import error for #{instrument.ticker}: #{e}".red
  end

  private

  def get(path, params = {})
    response = RestClient.get "#{BASE}#{path}", params: { token: ENV['IEX_SECRET_KEY'] }.merge(params || {})
    JSON.parse response.body
  end

  ExchangeMapping = { NYS: 'NYSE', NAS: 'NASDAQ' }.stringify_keys.tap { |hash| hash.default_proc = -> (h, k) { k } }
end

__END__
IexConnector.company 'X'
IexConnector.stats 'FANG'
IexConnector.quote 'X'
IexConnector.previous 'X'
IexConnector.day_candle_on 'PTN', Date.parse('2021-03-22')
IexConnector.import_day_candle Instrument.get('FANG'), Date.parse('2021-01-04')
IexConnector.import_today_candle Instrument['PVAC']
