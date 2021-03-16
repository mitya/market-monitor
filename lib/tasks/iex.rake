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
    Instrument.usd.abc.each do |inst|
      next if File.exist? "tmp/logos/#{inst.ticker}.png"

      puts "Load #{inst.ticker}"
      URI.open("https://storage.googleapis.com/iexcloud-hl37opg/api/logos/#{inst.ticker}.png", 'rb') do |remote_file|
        open("tmp/logos/#{inst.ticker}.png", 'wb') { |file| file << remote_file.read }
      end

      sleep 0.5
    rescue OpenURI::HTTPError
      puts "Mising #{inst.ticker}"
      sleep 0.5
    end
  end

  task :stats => :environment do
    InstrumentInfo.refresh
  end

  task 'ohlc:missing' => :environment do
    date = Date.parse ENV['date']
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

  task 'candles:stats' => :environment do
    (1.year.ago.to_date .. Date.current).each do |date|
      puts "Total candles for #{date} is #{Candle.day.where(date: date).count}"
    end
  end
end


__END__
rake iex:logos
rake iex:logos:download

rake iex:stats
rake iex:ohlc:missing date=2019-01-03
rake iex:ohlc:missing date=2020-01-03
rake iex:ohlc:missing date=2020-02-19
rake iex:ohlc:missing date=2020-03-23
rake iex:ohlc:missing date=2020-11-06
rake iex:ohlc:missing date=2021-01-04
rake iex:candles:stats

Instrument.get('AAON').candles.day.find_date('2020-03-23')
