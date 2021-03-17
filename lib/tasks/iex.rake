require 'csv'
require 'open-uri'

namespace :iex do
  task :logos => :environment do
    Instrument.usd.each do |inst|
      response = IexConnector.logo(inst.ticker)
      url = response['url'].presence
      puts "Icon for #{inst.ticker}: #{url}"
      open('tmp/icons.csv', 'a') { |f| f.print CSV.generate_line([inst.ticker, url]) }
      sleep 0.5
    end
  end

  task 'logos:download' => :environment do
    Instrument.premium.abc.each do |inst|
      next if File.exist? "public/logos/#{inst.ticker}.png"

      puts "Load #{inst.ticker}"
      URI.open("https://storage.googleapis.com/iexcloud-hl37opg/api/logos/#{inst.ticker}.png", 'rb') do |remote_file|
        open("public/logos/#{inst.ticker}.png", 'wb') { |file| file << remote_file.read }
      end

      sleep 0.5
    rescue OpenURI::HTTPError
      puts "Mising #{inst.ticker}"
      sleep 0.5
    end

    Instrument.find_each &:check_logo
  end

  task :stats => :environment do
    InstrumentInfo.refresh
  end

  task 'ohlc:missing' => :environment do
    ENV['dates'].to_a.split(',').each do |date|
      date = Date.parse(date)
      with_missing_date = Instrument.iex.abc.select { |inst| inst.candles.day.where(date: date).none? }

      puts "Date checked: #{date}"
      puts "With missing date: #{with_missing_date.join(',')}"
      puts "Total missing date #{with_missing_date.count}"
      puts "Total instruments #{Instrument.count}"
      puts "Total candles for #{date} is #{Candle.day.where(date: date).count}"

      next unless ENV['ok'] == '1'

      with_missing_date.each do |inst|
        IexConnector.import_day_candle inst, date
        sleep 0.3
      end
    end
  end

  task 'candles:stats' => :env do
    (1.year.ago.to_date .. Date.current).each do |date|
      puts "Total candles for #{date} is #{Candle.day.where(date: date).count}"
    end
  end

  task 'symbols:load' => :env do
    File.write "db/data/iex-symbols-#{Current.date.to_s :number}.json", IexConnector.symbols.to_json
  end

  task 'symbols:process' => :env do
    items = JSON.parse File.read "db/data/iex-symbols-#{Current.date.to_s :number}.json"
    items.each do |item|
      if instrument = Instrument.get(item['symbol'])
        instrument.update! exchange: IexConnector::ExchangeMapping[item['exchange']], flags: (instrument.flags + ['iex']).uniq
      end
    end
  end

  task 'update' => :env do
    # update candles for premium tickers
    # update prices for premium tickers
  end
end


__END__
rake iex:logos
rake iex:logos:download
rake iex:symbols:load
rake iex:symbols:process
rake iex:ohlc:missing dates=2019-01-03,2020-01-03,2020-02-19,2020-03-23,2020-11-06,2021-01-04

rake iex:stats
