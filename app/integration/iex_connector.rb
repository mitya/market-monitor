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
  def logo(symbol)                    = get("/stock/#{symbol}/logo")
  def company(symbol)                 = get("/stock/#{symbol}/company")
  def stats(symbol)                   = get("/stock/#{symbol}/stats")
  def day_candle_on(symbol, date)     = get("/stock/#{symbol}/chart/date/#{date.to_s :number}", chartByDay: true)
  def day_candles_for(symbol, period) = get("/stock/#{symbol}/chart/#{period}")
  def last(symbol)                    = get("/last?symbols=#{symbol}")
  def tops(*symbols)                  = get("/tops", { symbols: symbols.join(',').presence }.presence)
  def symbols                         = get("/ref-data/symbols")

  def import_day_candles(instrument, date: nil, period: nil)
    return if date && instrument.candles.day.where(date: date).exists?

    candles_data = date ? day_candle_on(instrument.ticker, date) : day_candles_for(instrument.ticker, period)
    return puts "No IEX data for #{instrument} for #{date || period}" if candles_data.none?

    Candle.transaction do
      candles_data.each do |hash|
        date = Date.parse hash['date']
        puts "Import #{instrument} #{date} candle from IEX"
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
IexConnector.day_candle 'X', Date.parse('2021-01-04')
IexConnector.import_day_candle Instrument.get('FANG'), Date.parse('2021-01-04')
