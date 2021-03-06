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
  def insider_summary(symbol)         = stock(symbol, 'insider-summary')
  def institutional_ownership(symbol) = stock(symbol, 'institutional-ownership')
  def recommedations(symbol)          = stock(symbol, 'recommendation-trends')
  def price_target(symbol)            = stock(symbol, 'price-target')
  def estimates(symbol)               = stock(symbol, 'estimates', period: 'annual')
  def logo(symbol)                    = stock(symbol, 'logo')
  def peers(symbol)                   = stock(symbol, 'peers')
  def company(symbol)                 = stock(symbol, 'company')
  def stats(symbol)                   = stock(symbol, 'stats')
  def advanced_stats!(symbol)         = stock(symbol, 'advanced-stats')
  def splits(symbol)                  = stock(symbol, 'splits/5y')
  def days_for(symbol, period)        = stock(symbol, "chart/#{period}")
  def day_on(symbol, date)            = stock(symbol, "chart/date/#{date.to_date.to_s :number}", chartByDay: true)
  def minutes_on(symbol, date)        = stock(symbol, "chart/date/#{date.to_date.to_s :number}")
  def last(symbol)                    = get("/last?symbols=#{symbol}")
  def tops(*symbols)                  = get("/tops", { symbols: symbols.join(',').presence }.compact)
  def symbols                         = get("/ref-data/symbols")
  def otc_symbols                     = get("/ref-data/otc/symbols")
  def exchanges                       = get("/ref-data/exchanges")
  def exchange_symbols(exchange)      = get("/ref-data/exchange/#{exchange}/symbols") # MIC
  def region_symbols(region)          = get("/ref-data/region/#{region}/symbols") # RU
  def options_chart(code, range: '1d')= get("/options/#{code}/chart", range: range)
  def options_dates                   = get("/ref-data/options/symbols")
  def options_specs(ticker)           = get("/ref-data/options/symbols/#{ticker}")
  def insider_transactions_series(symbol, since: 1.month.ago.to_date) = get("/time-series/INSIDER_TRANSACTIONS/#{symbol}", from: since.to_date)
  def book(ticker)                    = get("/deep/book", symbols: ticker)

  def import_day_candles(instrument, date: nil, period: nil)
    return if date && instrument.candles.day.final.where(date: date, source: 'iex').exists?
    return if date && instrument.missing_dates.exists?(date: date)
    return if period == 'previous' && instrument.candles.day.final.where(date: Current.last_closed_day_as_iex).exists?

    candles_data = case
      when date then day_on(instrument.iex_ticker, date)
      when period == 'previous' then [previous(instrument.iex_ticker)]
      else days_for(instrument.iex_ticker, period)
    end

    if candles_data.none?
      instrument.missing_dates.find_or_create_by! date: date if date
      puts "No IEX data on #{date || period} for #{instrument}".light_yellow
      puts "#{instrument} has #{instrument.missing_dates.count} missing dates".light_cyan if instrument.missing_dates.count > 5
      return
    end

    Candle.transaction do
      candles_data.each do |hash|
        date = Date.parse hash['date']
        puts "Import IEX #{date} candle for #{instrument}"
        candle = instrument.candles.find_or_initialize_by date: date
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
    nil
  rescue RestClient::NotFound => e
    puts "Import IEX #{date} candle for #{instrument}: #{e}".red
    nil
  rescue RestClient::Forbidden => e
    puts "Import IEX #{date} candle for #{instrument}: #{e}".red
    nil
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

  def import_intraday_candles(instrument, date)
    instrument = Instrument[instrument]
    date = date.to_date

    candles_data = ApiCache.get "cache/iex-candles-m1/#{instrument.ticker} #{date}.json" do
      minutes_on instrument.iex_ticker, date
    end

    # candles_data = minutes_on instrument.iex_ticker, date
    return puts "No IEX data on #{date} for #{instrument}".light_yellow if candles_data.none?

    Candle.transaction do
      candles_data.each do |hash|
        date = Date.parse hash['date']
        time = hash['minute']
        next puts "Miss   IEX #{date} #{time} candle for #{instrument}".yellow if hash['marketVolume'].to_i == 0
        puts "Import IEX #{date} #{time} candle for #{instrument}"
        candle = Candle::M1.find_or_initialize_by ticker: instrument.ticker, date: date, time: time
        candle.source  = 'iex'
        candle.ongoing = false
        candle.open    = hash['marketOpen']
        candle.close   = hash['marketClose']
        candle.high    = hash['marketHigh']
        candle.low     = hash['marketLow']
        candle.volume  = hash['marketVolume']
        candle.save!
      end
    end

  end

  def symbols_cache = JSON.parse(Pathname.glob('cache/iex/symbols.json').last.read, object_class: OpenStruct)
  def otc_symbols_cache = JSON.parse(Pathname.glob('cache/iex/symbols-otc.json').last.read, object_class: OpenStruct)
  def all_symbols_cache = symbols_cache + otc_symbols_cache

  def convert_type(type)
    TypeMapping[type.to_s.to_sym] || type
  end

  def tops_csv(*symbols)
    RestClient.get "#{BASE}/tops", params: { token: ENV['IEX_SECRET_KEY'], format: 'csv', symbols: symbols.join(',').presence }.compact
  end

  private

  def get(path, params = {})
    # puts "GET #{path} #{params}".yellow
    response = RestClient.get "#{BASE}#{path}", params: { token: ENV['IEX_SECRET_KEY'] }.merge(params || {})
    JSON.parse response.body
  rescue Net::OpenTimeout
    puts "IEX request timed out for #{path} #{params}".red
    exit
  rescue
    puts "IEX request failed for #{path} #{params}".red
    raise
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
Iex.import_intraday_candles('aapl', '2021-06-17'); nil
Iex.insider_transactions_series('AAPL')
Iex.tops_csv
