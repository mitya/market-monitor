namespace :tinkoff do
  desc "Adds new & updates old instruments"
  task 'instruments:sync' => :environment do
    TinkoffConnector.sync_instruments(preview: ENV['ok'] != '1')
  end

  desc "Loads day candles for missing latest days & for today"
  task 'candles:day' => :environment do
    Instrument.tinkoff.in_set(ENV['set']).abc.each do |inst|
      TinkoffConnector.import_latest_day_candles(inst)
    end
  end

  desc "Loads all day candlkes since 2019 for the 'tickers' specified"
  task 'candles:day:all' => :environment do
    tickers = ENV['tickers'].to_s.split(',')
    Instrument.tinkoff.where(ticker: tickers).abc.each do |inst|
      TinkoffConnector.import_all_day_candles(inst)
    end
  end

  # task 'candles:download:range' => :environment do
  #   Instrument.tinkoff.abc.each do |inst|
  #     TinkoffConnector.download_candles inst, interval: 'day', since: Date.new(2021, 1, 1), till: Date.new(2021, 3, 13)
  #   end
  # end
  #
  # task 'candles:download' => :environment do
  #   Instrument.tinkoff.in_set(ENV['set']).abc.each do |inst|
  #     TinkoffConnector.download_day_candles_upto_today inst
  #   end
  # end
  #
  # task 'candles:download:ongoing' => :environment do
  #   Instrument.tinkoff.in_set(ENV['set']).abc.each do |inst|
  #     TinkoffConnector.download_ongoing_day_candle inst
  #   end
  # end
  #
  # task 'candles:import' => :environment do
  #   TinkoffConnector.import_candles ENV['dir'] || "db/tinkoff-day-#{Date.current.to_s :number}"
  # end
  #
  # task 'candles:import:ongoing' => :environment do
  #   TinkoffConnector.import_candles "db/tinkoff-day-#{Date.current.to_s :number}-ongoing"
  # end

  task 'prices' => :environment do
    InstrumentPrice.refresh(set: ENV['set'])
  end

  task 'logos:download' => :environment do
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

__END__
rake tinkoff:candles:import dir=db/tinkoff-day-2021-upto-0312
rake tinkoff:candles:download:range

rake tinkoff:logos:download

rake tinkoff:candles:download:ongoing set=main
rake tinkoff:candles:import:ongoing

rake tinkoff:instruments:sync # ok=1
rake tinkoff:candles:day:all tickers=MTX@DE,FIXP,TGKDP


rake tinkoff:candles:day:latest
rake tinkoff:prices:sync
rake tinkoff:prices:sync set=main
