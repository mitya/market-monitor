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

  task 'candles:days:on_dates' => :environment do
    ENV['dates'].to_s.split(',').each do |date|
      date = Date.parse(date)
      with_missing_date = Instrument.premium.abc.select { |inst| inst.candles.day.where(date: date).none? }

      puts "Date checked: #{date}"
      puts "With missing date: #{with_missing_date.join(',')}"
      puts "Total missing date #{with_missing_date.count}"
      puts "Total instruments #{Instrument.count}"
      puts "Total candles for #{date} is #{Candle.day.where(date: date).count}"
      puts

      next unless ENV['ok'] == '1'

      with_missing_date.each do |inst|
        IexConnector.import_day_candles inst, date: date
        sleep 0.3
      end
    end
  end

  %w[previous 5d 1m].each do |period|
    task "candles:days:#{period}" => :environment do
      Instrument.premium.abc.each { |inst| IexConnector.import_day_candles inst, period: period }
    end
  end

  task 'candles:days:today' => :environment do
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

  task 'prices:premium' => :env do
    InstrumentPrice.refresh_premium_from_iex
  end

  task 'prices:all' => :env do
    InstrumentPrice.refresh_from_iex
  end

  task 'update' => %w[prices candles:days:previous]

  task 'insider_transactions' => :env do
    set = ENV['set'] || 'main'
    Instrument.usd.iex.in_set(set).abc.each do |inst|
      InsiderTransaction.import_iex_data_from_remote(inst)
      sleep 0.5
    end
  end

  task 'price_targets' => :env do
    set = ENV['set'] || 'main'
    Instrument.usd.iex.in_set(set).abc.each do |inst|
      PriceTarget.import_iex_data_from_remote inst, delay: 0.33
    end
  end

  task 'recommendations' => :env do
    set = ENV['set'] || 'main'
    Instrument.usd.iex.in_set(set).abc.each do |inst|
      Recommendation.import_iex_data_from_remote inst, delay: 0.33
    end
  end
end


__END__
rake iex:logos
rake iex:logos:download
rake iex:symbols:load
rake iex:symbols:process
rake iex:candles:days:on_dates dates=2019-01-03,2020-01-03,2020-02-19,2020-03-23,2020-11-06,2021-01-04 ok=1
rake iex:candles:days:1m

rake iex:stats
rake iex:candles:days:previous
rake iex:prices:all

rake iex:update
rake iex:insider_transactions set=small
rake iex:price_targets set=all
rake iex:recommendations set=all
