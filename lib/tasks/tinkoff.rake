namespace :tinkoff do
  desc "Adds new & updates old instruments"
  task 'instruments:sync' => :environment do
    Tinkoff.sync_instruments(preview: ENV['ok'] != '1')
  end


  namespace :days do
    desc "Loads day candles for missing latest days & for today"
    envtask :latest do
      Instrument.tinkoff.in_set(ENV['set']).abc.each do |inst|
        Tinkoff.import_latest_day_candles(inst, today: R.true_or_nil?(:today))
      end
    end

    desc "Loads all day candles since 2019 for the 'tickers' specified"
    envtask :year do
      tickers = ENV['tickers'].to_s.split(',')
      Instrument.tinkoff.where(ticker: tickers).abc.each do |inst|
        Tinkoff.import_all_day_candles(inst)
      end
    end
  end


  namespace :prices do
    envtask(:all)  { InstrumentPrice.refresh_from_tinkoff Instrument.tinkoff.in_set(ENV['set']).abc   }
    envtask(:uniq) { InstrumentPrice.refresh_from_tinkoff Instrument.where(currency: %w[RUB EUR]).abc }
  end
  task :prices => 'prices:all'


  namespace :logos do
    envtask :download do
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
  end


  namespace :premium do
    envtask :filter do
      tickers = File.read("db/data/tinkoff-premium.txt").split.map &:upcase
      tickers = tickers.reject { |t| Instrument.tinkoff.exists? ticker: t }
      puts tickers.sort.join(' ')
    end

    envtask :import do
      iex_symbols_file = Pathname.glob('cache/iex/symbols *.json').last
      iex_items = JSON.parse iex_symbols_file.read, object_class: OpenStruct
      tickers = ENV['tickers'].split # File.read("db/data/tinkoff-premium.txt").split.map &:upcase
      tickers.each do |ticker|
        next if Instrument.exists?(ticker: ticker)
        iex_item = iex_items.find { |item| item.symbol == ticker }
        next puts "Skip #{ticker}" unless iex_item
        puts "Create #{ticker}"
        Instrument.create!(
          ticker:   ticker,
          name:     iex_item.name,
          currency: iex_item.currency,
          figi:     iex_item.figi,
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
