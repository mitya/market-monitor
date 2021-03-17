# https://iexcloud.io/console/
# https://iexcloud.io/docs/api
class IexConnector
  include StaticService

  BASE = 'https://cloud.iexapis.com/stable'

  def quote(symbol) = get("/stock/#{symbol}/quote")
  def last(symbol) = get("/last?symbols=#{symbol}")

  def insider_transactions(symbol) = get("/stock/#{symbol}/insider-transactions")
  def options(symbol) = get("/stock/#{symbol}/options")
  def recommedations(symbol) = get("/stock/#{symbol}/recommendation-trends")
  def logo(symbol) = get("/stock/#{symbol}/logo")
  def company(symbol) = get("/stock/#{symbol}/company")
  def stats(symbol) = get("/stock/#{symbol}/stats")
  def tops(*symbols) = get("/tops?symbols=#{symbols.join(',')}")
  def symbols = get("/ref-data/symbols")
  def day_candle(symbol, date) = get("/stock/#{symbol}/chart/date/#{date.to_s :number}", params: { chartByDay: true })

  def import_day_candle(instrument, date)
    return if instrument.candles.day.where(date: date).exists?

    candles_data = day_candle instrument.ticker, date
    return puts "No IEX data for #{instrument} on #{date}" if candles_data.none?

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

  def get(path, params: {})
    response = RestClient.get "#{BASE}#{path}", params: { token: ENV['IEX_SECRET_KEY'] }.merge(params)
    JSON.parse response.body
  end

  ExchangeMapping = { NYS: 'NYSE', NAS: 'NASDAQ' }.stringify_keys.tap { |hash| hash.default_proc = -> (h, k) { k } }
end

__END__
IexConnector.logo 'BRK.B'
IexConnector.company 'X'
IexConnector.day_candle 'X', Date.parse('2021-01-04')
IexConnector.stats 'FANG'
IexConnector.import_day_candle Instrument.get('FANG'), Date.parse('2021-01-04')
