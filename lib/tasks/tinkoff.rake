namespace :tinkoff do
  task 'candles:download:range' => :environment do
    Instrument.tinkoff.abc.each do |inst|
      TinkoffConnector.download_candles inst, interval: 'day', since: Date.new(2021, 1, 1), till: Date.new(2021, 3, 13)
    end
  end

  task 'candles:download' => :environment do
    Instrument.tinkoff.in_set(ENV['set']).abc.each do |inst|
      TinkoffConnector.download_day_candles_upto_today inst
    end
  end

  task 'candles:download:ongoing' => :environment do
    Instrument.tinkoff.in_set(ENV['set']).abc.each do |inst|
      TinkoffConnector.download_ongoing_day_candle inst
    end
  end

  task 'candles:import' => :environment do
    TinkoffConnector.import_candles ENV['dir'] || "db/tinkoff-day-#{Date.current.to_s :number}"
  end

  task 'candles:import:ongoing' => :environment do
    TinkoffConnector.import_candles "db/tinkoff-day-#{Date.current.to_s :number}-ongoing"
  end

  task 'prices:refresh' => :environment do
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
rake tinkoff:candles:download
rake tinkoff:candles:import dir=db/tinkoff-day-2021-upto-0312
rake tinkoff:candles:download:range

rake tinkoff:logos:download

rake tinkoff:candles:download:ongoing set=main
rake tinkoff:candles:import:ongoing

rake tinkoff:prices:refresh set=main
