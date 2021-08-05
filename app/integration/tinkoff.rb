class Tinkoff
  include StaticService

  OutdatedTickers = %w[
    AGN AIMT AOBC APY AVP AXE BEAT BFYT BMCH CHA CHL CXO CY DLPH DNKN ENPL ETFC FTRE HDS HIIQ IMMU LM LOGM LVGO MINI MYL MYOK
    NBL PRSC PRTK RUSP SERV SINA TECD TIF TRCN TSS UTX VAR VRTU WYND ACIA FLIR EV PLT PS VIE
    CBPO MTSC PRSP RP MQ TE
    MNK GSH FTR CTB
    TOT
    VZRZP ALNU
    TCS CLGX MSGN WORK PRAH
    NVTK@GS LKOD@GS OGZD@GS NLMK@GS PHOR@GS SBER@GS SVST@GS SSA@GS MGNT@GS PLZL@GS KAP@GS
    HOME LMNX CCIV ALXN CLNY GTT CNST LB TLND
  ].uniq

  TickerWithSomeDatesMIssing = %w[
    AKBTY CCHGY
  ]

  BadTickers = (OutdatedTickers + TickerWithSomeDatesMIssing).uniq

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
          puts "Diff ISIN - #{inst.ticker} - #{hash['name']} (was #{inst.name})".yellow
          problematic_tickers << inst.ticker
        end
        if inst.figi != hash['figi']
          puts "Diff FIGI - #{inst.ticker} - #{hash['name']} (was #{inst.name})".yellow
          problematic_tickers << inst.ticker
        end
        if inst.premium?
          puts "#{inst.ticker} is on SPB now".yellow
        end
      else
        next if BadTickers.include?(hash['ticker'])
        puts "Miss #{hash['ticker']} - #{hash['name']}".green
        new_tickers << hash['ticker']
      end
    end

    current_tickers = instruments.map { |hash| hash['ticker'] }.to_set
    outdated_tickers = Instrument.tinkoff.reject { |inst| inst.ticker.in? current_tickers }
    puts
    puts "Outdated: #{outdated_tickers.map(&:ticker).sort.join(' ')}"
    puts "Problematic: #{problematic_tickers.sort.join(' ')}"
    puts "New: #{new_tickers.sort.join(' ')}"
    puts

    first_dates = YAML.load_file("db/data/first-dates.yaml")

    unless preview
      instruments.
        select { |hash| new_tickers.include? hash['ticker'] }.
        each do |hash|
          puts "Create #{hash['ticker']}"
          inst = Instrument.create! instrument_attrs_from(hash)
          if first_date = first_dates[hash['ticker']]
            inst.update! first_date: first_date
          end
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

  def last_hour_candles(instrument, since = 1.hour.ago, till = 1.minute.from_now)
    since, till = since.beginning_of_minute, till.beginning_of_minute
    call_js_api "candles #{instrument.figi} hour #{since.xmlschema} #{till.xmlschema}"
  end

  def update_current_price(instrument, **opts)
    instrument = Instrument[instrument]
    response_json = last_hour_candles instrument, 2.hours.ago

    return puts "Refresh Tinkoff price for #{instrument} failed: #{stringify_error response_json}".red if response_json['candles'] == nil
    candles = response_json.dig 'candles'
    candle = candles[-1]

    last = candle&.dig 'c'
    low = candles.map { |c| c['l'] }.min
    volume = candles.map { |c| c['v'] }.sum

    printf "Refresh Tinkoff price for %-7s %3i candles last=#{last}\n", instrument.ticker, candles.count
    instrument.price!.update! value: last, last_at: candle['time'], source: 'tinkoff', low: low, volume: volume if last
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


  def import_candles_from_hash(instrument, data, candle_class: nil)
    interval = data['interval']
    candles = data['candles'].to_a

    # return if instrument.candles.where(interval: interval).where(Candle.arel_table[:time].gteq 1.day.ago.midnight).exists?
    # puts "Import #{candles.count} #{interval} candles for #{instrument}"
    candle_class ||= Candle.interval_class_for(interval)
    return "Missing candles for #{instrument}".red if candle_class == nil

    candle_class.transaction do
      candles.each do |hash|
        time = Time.parse hash['time']
        date = time.to_date
        time = time.to_s(:time) if candle_class == Candle::M5 || candle_class == Candle::M1
        candle = candle_class.find_or_initialize_by instrument: instrument, interval: interval, time: time, date: date
        puts "Import Tinkoff #{date} #{time} #{interval} candle for #{instrument}" if candle.new_record?
        candle.ticker  = instrument.ticker
        candle.source  = 'tinkoff'
        candle.open    = hash['o']
        candle.close   = hash['c']
        candle.high    = hash['h']
        candle.low     = hash['l']
        candle.volume  = hash['v'] > Integer::Max31 ? Integer::Max31 : hash['v']
        candle.date    = date
        candle.ongoing = interval == 'day' && date == Current.date && !Current.weekend?
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

  def import_day_candle(instrument, date, delay: 0.25)
    return if instrument.candles.day.final.tinkoff.where(date: date).exists?
    data = load_day instrument, date - 1, date
    import_candles_from_hash instrument, data
    sleep delay
  rescue
    puts "Import #{instrument} failed: #{$!}"
  end

  def import_day_candles(instrument, since:, till:, delay: 0.25, candle_class: nil)
    data = load_day instrument, since, till
    import_candles_from_hash instrument, data, candle_class: candle_class
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

  def import_all_day_candles(instrument, years: [2019, 2020, 2021], candle_class: nil)
    import_day_candles instrument, since: Date.parse('2019-01-01'), till: Date.parse('2019-12-31').end_of_day, candle_class: candle_class if years.include?(2019)
    import_day_candles instrument, since: Date.parse('2020-01-01'), till: Date.parse('2020-12-31').end_of_day, candle_class: candle_class if years.include?(2020)
    import_day_candles instrument, since: Date.parse('2021-01-01'), till: Date.current.end_of_day,             candle_class: candle_class if years.include?(2021)
  end

  def import_intraday_candles(instrument, interval)
    return if !instrument.tinkoff?
    day_start = instrument.rub? || instrument.eur? ? Current.ru_market_open_time : Current.us_market_open_time
    last_loaded_candle = Candle.interval_class_for(interval).where(instrument: instrument, interval: interval).where('time >= ?', day_start).order(:time).last
    since = last_loaded_candle&.time || day_start
    # return if last_loaded_candle.created_at > interval_duration(interval).ago
    return if since + Candle.interval_duration(interval) > Time.current
    return if !instrument.market_open?

    data = load_intervals instrument, interval, since, Time.current + 1.minute, delay: 0.25
    import_candles_from_hash instrument, data
  end


  def call_js_api(command, parse: true, delay: 0, account: nil)
    command = "coffee bin/tinkoff.coffee #{command}"
    command = "TINKOFF_ACCOUNT=#{account} #{command}" if account
    puts command.purple if $log_tinkoff
    response = `#{command}`
    sleep delay if delay.to_f > 0
    parse ? JSON.parse(response) : response
  rescue => e
    puts "Error parsing JSON for #{command}".red
    parse ? { } : ''
  end

  def load_day(instrument, since = Current.date, till = since.to_date.end_of_day)
    call_js_api "candles #{instrument.figi} day #{since.xmlschema} #{till.xmlschema}"
  end

  def load_intervals(instrument, interval, since, till, delay: 0)
    call_js_api "candles #{instrument.figi} #{interval} #{since.xmlschema} #{till.xmlschema}", delay: delay
  end

  def sync_portfolio(data, account)
    puts "Sync tinkoff portfolio '#{account}'"
    data['positions'].to_a.each do |position|
      ticker = position['ticker']
      next if position['instrumentType'] == 'Currency'
      next puts "Missing #{ticker} (used in portfolio)".red if !Instrument.get(ticker)
      item = PortfolioItem.find_or_create_by(ticker: ticker)
      item.update! "#{account}_lots" => position['balance']
    end
    PortfolioItem.where.not(ticker: data['positions'].map { |p| p['ticker'] }).find_each do |item|
      puts "Missing #{item.instrument} (which is in portfolio)".red unless item.instrument
      next if item.instrument&.premium?
      item.update! "#{account}_lots" => nil
    end
  end

  def sync_portfolios
    sync_portfolio call_js_api("portfolio"), 'tinkoff'
    sync_portfolio call_js_api("portfolio-iis"), 'tinkoff_iis'
    cleanup_portfolio
  end

  def sync_iis
    sync_portfolio call_js_api("portfolio-iis"), 'tinkoff_iis'
  end

  def cleanup_portfolio
    PortfolioItem.find_each.select { |pi| pi.total_lots == 0 }.each &:destroy
  end

  def stringify_error(json)
    error_text = "#{json&.dig('error', 'name')} #{json&.dig('error', 'type')}".strip.presence
    error_text || json
  end

  def load_last_5m_candles(instrument, date)
    return if !instrument.tinkoff?
    return if instrument.rub? || instrument.eur?
    return puts "Last 5m already loaded on #{date} for #{instrument}".yellow if Candle::M5.where(instrument: instrument, date: date, time: '19:55').exists?

    est_midnight = date.in_time_zone Current.est
    data = load_intervals instrument, '5min', est_midnight.change(hour: 15, min: 50), est_midnight.change(hour: 16, min: 00), delay: 0.25
    import_candles_from_hash instrument, data
  end

  def load_trading_5m_candles
    date = Current.date
    instruments = InstrumentSet[:trading].instruments
    instruments.each do |inst|
      last_loaded_candle = Candle::M5.where(ticker: inst.ticker, date: date).order(:time).last
      data = load_intervals inst, '5min', last_loaded_candle&.datetime || Current.date.midnight, Time.current + 5, delay: 0.25
      import_candles_from_hash inst, data
    end
  end

  def book(instrument)
    instrument = Instrument[instrument]
    call_js_api "orderbook #{instrument.figi}"
  end

  def orders
    call_js_api "orders", account: 'iis'
  end

  def operations(since: Current.ru_market_open_time, till: Time.current + 5.seconds)
    call_js_api "operations _ _ #{since.xmlschema} #{till.xmlschema}", account: 'iis'
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

$log_tinkoff = true
Tinkoff.update_current_price('ECHO')
