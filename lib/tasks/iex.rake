require 'csv'
require 'open-uri'

namespace :iex do
  namespace :logos do
    envtask :default do
      Instrument.usd.each do |inst|
        response = IexConnector.logo(inst.ticker)
        url = response['url'].presence
        puts "Icon for #{inst.ticker}: #{url}"
        open('tmp/icons.csv', 'a') { |f| f.print CSV.generate_line([inst.ticker, url]) }
        sleep 0.5
      end
    end

    envtask :download do
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
  end


  namespace :candles do
    envtask 'days:on_dates' do
      dates = ENV['dates'].to_s.split(',').presence || Current::SpecialDates.dates
      dates.sort.each do |date|
        date = Date.parse(date) if String === date
        instruments = R.instruments_from_env || Instrument.premium
        with_missing_date = instruments.abc.select { |inst| inst.candles.day.where(date: date).none? }

        puts "Date checked: #{date}"
        puts "With missing date: #{with_missing_date.join(',')}"
        puts "Total missing date #{with_missing_date.count}"
        puts "Total candles for #{date} is #{Candle.day.where(date: date).count}"
        puts

        next unless R.confirmed?

        with_missing_date.each do |inst|
          IexConnector.import_day_candles inst, date: date
          sleep 0.3
        end
      end
    end

    %w[previous 5d 1m].each do |period|
      envtask "days:#{period}" do
        Instrument.premium.abc.each { |inst| IexConnector.import_day_candles inst, period: period }
      end
    end

    envtask 'days:today' do
      Instrument.premium.abc.each { |inst| IexConnector.import_today_candle inst }
    end

    envtask :stats do
      (1.year.ago.to_date .. Date.current).each do |date|
        puts "Total candles for #{date} is #{Candle.day.where(date: date).count}"
      end
    end
  end


  namespace :symbols do
    envtask(:load)      { File.write "cache/iex/symbols #{Current.date.to_s :number}.json", IexConnector.symbols.to_json }
    envtask('otc:load') { File.write "cache/iex/symbols-otc #{Current.date.to_s :number}.json", IexConnector.otc_symbols.to_json }
    envtask :process do
      items = JSON.parse File.read "db/data/iex-symbols-#{Current.date.to_s :number}.json"
      items.each do |item|
        if instrument = Instrument.get(item['symbol'])
          instrument.update! exchange: IexConnector::ExchangeMapping[item['exchange']], flags: (instrument.flags + ['iex']).uniq
        end
      end
    end
  end


  namespace :prices do
    envtask(:premium) { InstrumentPrice.refresh_premium_from_iex }
    envtask(:all)     { InstrumentPrice.refresh_from_iex }
  end


  envtask :stats do
    instruments = R.instruments_from_env || Instrument.all
    instruments.usd.iex.abc.each do |inst|
      inst.info.refresh include_company: R.true?(:company)
      sleep 0.33
    end
  end

  envtask :insider_transactions do
    Instrument.usd.iex.in_set(ENV['set'] || 'main').abc.each do |inst|
      InsiderTransaction.import_iex_data_from_remote inst, delay: 0.33
    end
  end

  envtask :price_targets do
    Instrument.usd.iex.in_set(ENV['set'] || 'main').abc.each do |inst|
      PriceTarget.import_iex_data_from_remote inst, delay: 0.33
    end
  end

  envtask :recommendations do
    Instrument.usd.iex.in_set(ENV['set'] || 'main').abc.each do |inst|
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
rake iex:insider_transactions set=main
rake iex:price_targets set=all
rake iex:recommendations set=all
