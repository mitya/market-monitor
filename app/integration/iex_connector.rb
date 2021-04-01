# https://iexcloud.io/console/
# https://iexcloud.io/docs/api
class IexConnector
  include StaticService

  BASE = 'https://cloud.iexapis.com/stable'

  def stock(symbol, api, params = {}) = get("/stock/#{symbol}/#{api.to_s.dasherize}", params)
  def price(symbol)                   = stock(symbol, 'price')
  def quote(symbol)                   = stock(symbol, 'quote')
  def ohlc(symbol)                    = stock(symbol, 'ohlc')
  def previous(symbol)                = stock(symbol, 'previous')
  def options(symbol)                 = stock(symbol, 'options')
  def insider_transactions(symbol)    = stock(symbol, 'insider-transactions')
  def recommedations(symbol)          = stock(symbol, 'recommendation-trends')
  def price_target(symbol)            = stock(symbol, 'price-target')
  def estimates(symbol)               = stock(symbol, 'estimates', period: 'annual')
  def logo(symbol)                    = stock(symbol, 'logo')
  def company(symbol)                 = stock(symbol, 'company')
  def stats(symbol)                   = stock(symbol, 'stats')
  def advanced_stats!(symbol)         = stock(symbol, 'advanced-stats')
  def day_candle_on(symbol, date)     = stock(symbol, "chart/date/#{date.to_s :number}", chartByDay: true)
  def day_candles_for(symbol, period) = stock(symbol, "chart/#{period}")
  def last(symbol)                    = get("/last?symbols=#{symbol}")
  def tops(*symbols)                  = get("/tops", { symbols: symbols.join(',').presence }.compact)
  def symbols                         = get("/ref-data/symbols")
  def otc_symbols                     = get("/ref-data/otc/symbols")

  def import_day_candles(instrument, date: nil, period: nil)
    return if date && instrument.candles.day.where(date: date).exists?
    return if period = 'previous' && instrument.candles.day.where(date: Current.yesterday).exists?

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
        candle.open    = hash['open']  # || hash['marketOpen']
        candle.close   = hash['close'] # || hash['marketClose']
        candle.high    = hash['high']  # || hash['marketHigh']
        candle.low     = hash['low']   # || hash['marketLow']
        candle.volume  = hash['volume'].to_i.nonzero? || hash['marketVolume']
        candle.save!
      end
    end

  rescue ActiveRecord::NotNullViolation => e
    puts "Missing some data when importing IEX candle for #{instrument} on #{date}: #{e}".red
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
    # puts "GET #{path} #{params}".yellow
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
IexConnector.day_candle_on 'ALTO', Date.parse('2021-01-04')
IexConnector.import_day_candle Instrument.get('FANG'), Date.parse('2021-01-04')
IexConnector.import_today_candle Instrument['PVAC']
