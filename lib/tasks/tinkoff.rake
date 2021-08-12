namespace :tinkoff do
  desc "Adds new & updates old instruments"
  envtask 'instruments:sync' do
    Tinkoff.sync_instruments(preview: ENV['ok'] != '1')
  end

  envtask 'portfolio:sync' do
    Tinkoff.sync_portfolios
  end


  namespace :days do
    envtask :missing do
      instruments = Instrument.tinkoff.select { |inst| inst.yesterday == nil }
      puts "Instruments without candles: #{instruments.map(&:ticker).join(' ')}"
    end

    desc "Loads day candles for missing latest days & for today"
    envtask :latest do
      Instrument.non_usd.in_set(ENV['set']).abc.each do |inst|
        Tinkoff.import_latest_day_candles(inst, today: R.true_or_nil?(:today))
      end
    end

    envtask :special do
      Instrument.non_usd.in_set(ENV['set']).abc.each do |inst|
        Current::SpecialDates.dates_plus.each do |date|
          Tinkoff.import_day_candle(inst, date)
        end
      end
    end

    envtask :previous do
      Instrument.non_usd.in_set(ENV['set']).abc.each do |inst|
        Tinkoff.import_latest_day_candles(inst, today: false)
      end
    end

    desc "Loads all day candles since 2019 for the 'tickers' specified"
    envtask :year do
      instruments = R.instruments_from_env || Instrument.tinkoff
      instruments.tinkoff.abc.each do |inst|
        Tinkoff.import_all_day_candles(inst, years: ENV['years'].to_s.split(',').map(&:to_i).presence || [2019, 2020, 2021])
      end

      # Instrument.tinkoff.usd.abc.each do |inst|
      #   Tinkoff.import_all_day_candles(inst, candle_class: Candle::DayTinkoff, years: ENV['years'].to_s.split(',').map(&:to_i).presence || [2021])
      # end
    end
  end

  namespace :candles do
    envtask 'import:hour' do
      Instrument.main.tinkoff.abc.each { |inst| Tinkoff.import_intraday_candles(inst, 'hour') }
    end

    envtask 'import:5min' do
      Instrument.main.tinkoff.abc.each { |inst| Tinkoff.import_intraday_candles(inst, '5min') }
    end

    envtask 'import:5min:last' do
      dates = [ENV['date'] ? ENV['date'].to_date : Current.today]
      dates = Current.last_n_weeks(2) #  - ['2021-07-02'.to_date]
      dates = [Current.today, Current.yesterday]
      instruments = Instrument.tinkoff.usd.abc
      dates.each do |date|
        Current.parallelize_instruments(instruments, 3) do |inst|
          Tinkoff.load_last_5m_candles(inst, date)
        end
      end
    end
  end


  namespace :prices do
    envtask(:pre)     { Price.refresh_from_tinkoff Instrument.tinkoff.abc }
    envtask(:all)     { Price.refresh_from_tinkoff Instrument.tinkoff.in_set(ENV['set']).abc   }
    envtask(:uniq)    { Price.refresh_from_tinkoff Instrument.where(currency: %w[RUB EUR]).abc }
    envtask(:signals) { Price.refresh_from_tinkoff Instrument.usd.for_tickers PriceSignal.yesterday.outside_bars.up.pluck(:ticker) }
  end
  task :prices => 'prices:all'


  namespace :logos do
    envtask :all do
      dir = Pathname("tmp/tinkoff-logos")
      dir.mkpath
      File.readlines("db/data/tinkoff-logos.txt", chomp: true).each do |url|
        isin = File.basename(url, 'x160.png')
        instrument = Instrument.find_by(isin: isin)
        filename = "#{instrument&.ticker || isin}.png"
        puts "Load #{url} => #{filename}"
        URI.open(url, 'rb') do |remote_file|
          open(dir / filename, 'wb') { |file| file << remote_file.read }
        end
        sleep 1
      end
    end

    envtask :download do
      instruments = R.instruments_from_env || Instrument.tinkoff.where(has_logo: false)
      instruments.abc.each do |inst|
        next if File.exist? "public/logos/#{inst.ticker}.png"

        puts "Load Tinkoff logo for #{inst.ticker}"
        URI.open("https://static.tinkoff.ru/brands/traiding/#{inst.isin}x160.png", 'rb') do |remote_file|
          open("public/logos/#{inst.ticker}.png", 'wb') { |file| file << remote_file.read }
        end

      rescue OpenURI::HTTPError
        puts "Miss Tinkoff logo for #{inst.ticker}".red
      ensure
        inst.check_logo
        sleep 0.5
      end
    end
  end


  namespace :premium do
    envtask :filter do
      tickers = File.read("db/data/tinkoff-premium.txt").split.map &:upcase
      tickers = tickers.reject { |t| Instrument.tinkoff.exists? ticker: t }
      puts tickers.sort.join(' ')
    end

    envtask :import do
      ApiCache.get("cache/iex/symbols #{Date.current.to_s :number}.json") { Iex.symbols }
      iex_items = Iex.all_symbols_cache

      tickers = ENV['tickers'].split # File.read("db/data/tinkoff-premium.txt").split.map &:upcase
      tickers.each do |ticker|
        next if Instrument.exists?(ticker: ticker)
        iex_ticker = Instrument.iex_ticker_for(ticker)
        iex_item = iex_items.find { |item| item.symbol == iex_ticker }
        next puts "Skip #{ticker}" unless iex_item
        puts "Create #{ticker}"
        Instrument.create!(
          ticker:   ticker,
          iex_ticker: ticker,
          name:     iex_item.name,
          currency: iex_item.currency,
          figi:     iex_item.figi,
          type:     Iex.convert_type(iex_item.type),
          exchange: Iex::ExchangeMapping[iex_item.exchange],
          flags:    %w[premium iex],
        )
      end
    end
  end

  task :update => %i[days prices]
end


__END__
rake tinkoff:logos:download
rake tinkoff:premium:filter
rake tinkoff:premium:import
rake tinkoff:candles:import dir=db/tinkoff-day-2021-upto-0312
rake tinkoff:candles:download:range
rake tinkoff:candles:download:ongoing set=main
rake tinkoff:candles:import:ongoing
rake tinkoff:candles:day:all tickers=MTX@DE,FIXP,TGKDP
rake tinkoff:instruments:sync # ok=1

rake tinkoff:candles:day
rake tinkoff:prices # set=main
rake tinkoff:update
rake tinkoff:days:year
rake tinkoff:candles:import:5min:last
