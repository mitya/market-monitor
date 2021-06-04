# https://iexcloud.io/console/
# https://iexcloud.io/docs/api
class Iex
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
  def peers(symbol)                   = stock(symbol, 'peers')
  def company(symbol)                 = stock(symbol, 'company')
  def stats(symbol)                   = stock(symbol, 'stats')
  def advanced_stats!(symbol)         = stock(symbol, 'advanced-stats')
  def day_on(symbol, date)            = stock(symbol, "chart/date/#{date.to_s :number}", chartByDay: true)
  def days_for(symbol, period)        = stock(symbol, "chart/#{period}")
  def last(symbol)                    = get("/last?symbols=#{symbol}")
  def tops(*symbols)                  = get("/tops", { symbols: symbols.join(',').presence }.compact)
  def symbols                         = get("/ref-data/symbols")
  def otc_symbols                     = get("/ref-data/otc/symbols")

  def import_day_candles(instrument, date: nil, period: nil)
    return if date && instrument.candles.day.final.where(date: date, source: 'iex').exists?
    return if period == 'previous' && instrument.candles.day.final.where(date: Current.yesterday).exists?

    candles_data =
      date ? day_on(instrument.iex_ticker, date) :
      period == 'previous' ? [previous(instrument.iex_ticker)] :
      days_for(instrument.iex_ticker, period)

    return puts "No IEX data on #{date || period} for #{instrument}".light_yellow if candles_data.none?

    Candle.transaction do
      candles_data.each do |hash|
        date = Date.parse hash['date']
        puts "Import IEX #{date} candle for #{instrument}"
        candle = instrument.candles.find_or_initialize_by interval: 'day', date: date
        candle.source  = 'iex'
        candle.ticker  = instrument.ticker
        candle.time    = date.to_time :utc
        candle.ongoing = date == Current.date && !Current.weekend?
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
  rescue RestClient::NotFound => e
    puts "Import IEX #{date} candle for #{instrument}: #{e}".red
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
  rescue => e
    puts "IEX today candle import error for #{instrument.ticker}: #{e}".red
  end

  def symbols_cache = JSON.parse(Pathname.glob('cache/iex/symbols *.json').last.read, object_class: OpenStruct)
  def otc_symbols_cache = JSON.parse(Pathname.glob('cache/iex/symbols-otc *.json').last.read, object_class: OpenStruct)
  def all_symbols_cache = symbols_cache + otc_symbols_cache

  def convert_type(type)
    TypeMapping[type.to_s.to_sym] || type
  end

  private

  def get(path, params = {})
    # puts "GET #{path} #{params}".yellow
    response = RestClient.get "#{BASE}#{path}", params: { token: ENV['IEX_SECRET_KEY'] }.merge(params || {})
    JSON.parse response.body
  end

  ExchangeMapping = { NYS: 'NYSE', NAS: 'NASDAQ' }.stringify_keys.tap { |hash| hash.default_proc = -> (h, k) { k } }
  TypeMapping = { cs: 'Stock', ps: 'Stock', et: 'Fund' }
end

__END__
Iex.company 'X'
Iex.stats 'FANG'
Iex.quote 'X'
Iex.previous 'X'
Iex.day_on 'ALTO', Date.parse('2021-01-04')
Iex.import_day_candle Instrument.get('FANG'), Date.parse('2021-01-04')
Iex.import_today_candle Instrument['PVAC']
Iex.day_on('ARCH', Date.parse('2021-03-01'))
