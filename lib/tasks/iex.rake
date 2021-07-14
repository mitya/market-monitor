require 'csv'
require 'open-uri'

namespace :iex do
  namespace :logos do
    envtask :default do
      instruments = R.instruments_from_env || Instrument.usd
      instruments.each do |inst|
        response = Iex.logo(inst.ticker)
        url = response['url'].presence
        puts "Icon for #{inst.ticker}: #{url}"
        open('tmp/icons.csv', 'a') { |f| f.print CSV.generate_line([inst.ticker, url]) }
        sleep 0.5
      end
    end

    envtask :download do
      instruments = R.instruments_from_env || Instrument.premium
      instruments.abc.each do |inst|
        next if File.exist? "public/logos/#{inst.ticker}.png"

        puts "Load logo for #{inst.ticker}"
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


  namespace :days do
    envtask :missing do
      dates = []
      dates += ENV['dates'].to_s.split(',').presence           if ENV['dates']
      dates += Current.last_n_weeks(ENV['weeks'].to_i)         if ENV['weeks']
      dates += Current.weekdays_since(Date.parse ENV['since']) if ENV['since']
      dates += Current::SpecialDates.dates_plus                if R.true?('special')
      dates -= [Current.date]
      dates = Current.last_2_weeks if dates.empty?
      dates = dates - MarketCalendar.nyse_holidays.to_a
      dates.uniq.sort.reverse.each do |date|
        date = Date.parse(date) if String === date
        instruments = (R.instruments_from_env || Instrument.iex_sourceable).abc
        instruments = instruments.reject { |inst| inst.first_date && inst.first_date > date }
        with_missing_date = instruments.select { |inst| inst.candles.day.final.where(date: date).none? }

        puts if date.monday?
        puts "#{date} #{date.strftime '%a'} #{with_missing_date.count} #{with_missing_date.join(',')}".yellow

        next unless R.confirmed?

        # with_missing_date.each { |inst| Iex.import_day_candles inst, date: date }
        Current.parallelize_instruments(with_missing_date, IEX_RPS) { | inst| Iex.import_day_candles inst, date: date }
      end
    end

    envtask :period do
      R.instruments_from_env.iex.usd.abc.each do |inst|
        Iex.import_day_candles inst, period: ENV['period'] || 'ytd'
      end
    end

    %w[previous 5d 1m].each do |period|
      envtask period do
        Current.parallelize_instruments(Instrument.iex.abc, IEX_RPS) { |inst| Iex.import_day_candles inst, period: period }
      end
    end

    envtask :today do
      Instrument.premium.abc.each { |inst| Iex.import_today_candle inst }
    end

    envtask :on_dates do
      dates = ENV['dates'].to_s.split(',').map { |str| Date.parse(str) }
      Instrument.premium.abc.each do |inst|
        dates.each do |date|
          Iex.import_day_candles inst, date: date
        end
      end
    end

    envtask :stats do
      (1.year.ago.to_date .. Date.current).each do |date|
        puts "Total candles for #{date} is #{Candle.day.where(date: date).count}"
      end
    end
  end

  envtask(:tops) { ApiCache.get("cache/iex/tops.json") { Iex.tops } }
  envtask('tops:set_sectors' => :tops) { Stats.load_sector_codes_from_tops }

  namespace :symbols do
    envtask(:load)      { File.write "cache/iex/symbols #{Current.date.to_s :number}.json", Iex.symbols.to_json }
    envtask('otc:load') { File.write "cache/iex/symbols-otc #{Current.date.to_s :number}.json", Iex.otc_symbols.to_json }
    envtask :refresh do
      items = Iex.all_symbols_cache
      index = items.index_by(&:symbol)
      Instrument.all.each do |instrument|
        item = index[instrument.ticker]
        if item && instrument.usd?
          instrument.update! exchange: Iex::ExchangeMapping[item.exchange], flags: instrument.flags.push('iex').uniq
        else
          instrument.update! flags: instrument.flags.without('iex')
        end
      end
    end
    envtask(:peers) { Stats.load_peers }
    envtask :missing do
      items = Iex.all_symbols_cache
      index = items.index_by(&:symbol)
      Instrument.all.each do |inst|
        if inst.usd? && !index[inst.iex_ticker]
          puts "Missing #{inst}".red
        end
      end
    end
  end


  namespace :prices do
    envtask(:uniq) { Price.refresh_premium_from_iex }
    envtask(:all)  { Price.refresh_from_iex }
  end
  task :prices => 'prices:all'


  envtask :stats do
    instruments = R.instruments_from_env || Instrument.all
    instruments.iex_sourceable.abc.each do |inst|
      inst.info!.refresh include_company: R.true?(:company)
    end
  end

  envtask 'stats:missing' do
    instruments = Instrument.iex_sourceable.select { | inst| inst.info == nil }
    puts "Missing stats: #{instruments.map(&:ticker).sort.join(' ')}"
  end

  envtask :insider_transactions do
    instruments = R.instruments_from_env || Instrument.all
    instruments = instruments.iex_sourceable.abc
    Current.parallelize_instruments(instruments, IEX_RPS) { |inst| InsiderTransaction.import_iex_data_from_remote inst }
    rake 'iex:insider_transactions:cache'
  end

  envtask :'insider_transactions:cache' do
    Instrument.find_each do |inst|
      inst.info&.update! last_insider_buy_price: inst.last_insider_buy&.price
    end
  end

  envtask :insider_summaries do
    instruments = R.instruments_from_env || Instrument.all
    instruments = instruments.iex_sourceable.abc
    Current.parallelize_instruments(instruments, IEX_RPS) { |inst| InsiderSummary.import inst }
  end

  envtask :institutions do
    instruments = R.instruments_from_env || Instrument.all
    instruments = instruments.iex_sourceable.abc
    Current.parallelize_instruments(instruments, 1 || IEX_RPS) { |inst| InstitutionHolding.import inst }
  end

  envtask :price_targets do
    instruments = R.instruments_from_env || Instrument.all
    instruments = instruments.iex_sourceable.abc
    # instruments = instruments.select { |inst| !inst.price_target || inst.price_target.date < Date.new(2021, 6, 1)  }
    Current.parallelize_instruments(instruments, IEX_RPS) { |inst| PriceTarget.import_iex_data_from_remote inst }
  end

  envtask :'price_targets:missing' do
    instruments = Instrument.iex_sourceable.select { | inst| inst.price_targets.none? }
    puts "Missing price targets: #{instruments.map(&:ticker).sort.join(' ')}"
  end

  envtask :recommendations do
    instruments = R.instruments_from_env || Instrument.all
    instruments = instruments.iex_sourceable.abc
    Current.parallelize_instruments(instruments, IEX_RPS) { |inst| Recommendation.import_iex_data_from_remote inst }
    Recommendation.mark_current
  end

  envtask :'recommendations:missing' do
    instruments = Instrument.iex_sourceable.select { | inst| inst.recommendations.none? }
    puts "Missing recommendations: #{instruments.map(&:ticker).join(' ')}"
  end
end


__END__
rake iex:logos
rake iex:logos:download
rake iex:symbols:load
rake iex:symbols:process
rake iex:candles:days:missing dates=2019-01-03,2020-01-03,2020-02-19,2020-03-23,2020-11-06,2021-01-04 ok=1
rake iex:candles:days:1m
rake iex:candles:days:on_dates dates=2021-04-01

rake iex:stats tickers='PRAX' company=1
rake iex:candles:days:previous
rake iex:candles:days:today
rake iex:prices:all

rake iex:update
rake iex:insider_transactions tickers=ATRA,AYX,DOCU,HRTX,FCX
rake iex:insider_transactions set=main
rake iex:price_targets set=all
rake iex:recommendations set=all
