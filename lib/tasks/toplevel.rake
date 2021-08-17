envtask :main do
  rake 'iex:days:previous'
  rake 'tinkoff:days:previous'
  if Current.weekend?
    rake 'iex:prices'          unless R.false?(:price)
    # rake 'iex:days:today'      unless R.false?(:today)
  elsif Current.us_market_open?
    rake 'iex:prices'          unless R.false?(:price)
    rake 'tinkoff:prices:uniq' unless R.false?(:price)
  elsif Current.uk_market_open?
    rake 'iex:prices:uniq'     unless R.false?(:price)
    rake 'tinkoff:prices:uniq' unless R.false?(:price)
    # rake 'iex:days:today'          if R.true?(:today)
  else
    rake 'iex:prices:uniq'     unless R.false?(:price)
    rake 'tinkoff:prices:uniq'      unless R.false?(:price)
  end
  rake 'aggregate'
  rake 'indicators'
  rake 'analyze'
  rake 'levels:alerts'
  rake 'tinkoff:portfolio:sync'
end

task :prices => %w[iex:prices tinkoff:prices:uniq]

envtask :aggregate do
  Aggregate.create_for_all date: ENV['date'] ? Date.parse(ENV['date']) : Current.yesterday
  Aggregate.set_current
end

envtask :indicators do
  DateIndicators.create_for_all
  DateIndicators.set_current
end

envtask :aggregate_old do
  MarketCalendar.open_days(Date.current.beginning_of_year, Current.yesterday).each do |date|
    Aggregate.create_for_all date: date, force: false
  end
end

envtask 'aggregate:stats' do
  pp Aggregate.group(:date).where('date > ?', 2.weeks.ago).count.reverse_merge(Current.last_2_weeks.map{ |d| [d, 0] }.to_h).sort
  pp PriceSignal.group(:date).where('date > ?', 2.weeks.ago).count.reverse_merge(Current.last_2_weeks.map{ |d| [d, 0] }.to_h).sort
end

envtask :analyze do
  PriceSignal.analyze_all date: ENV['date'] ? Date.parse(ENV['date']) : Current.last_closed_day
end

envtask :analyze_old do
  MarketCalendar.open_days(Date.current.beginning_of_year, '2021-04-16'.to_date).each do |date|
    PriceSignal.analyze_all date: date, force: false
  end
end

task :a => %w[aggregate analyze]

envtask(:levels) { PriceLevel.search_all }
envtask('levels:import') { PriceLevel.load_manual }
envtask('levels:hits') { PriceLevelHit.analyze_all }
envtask('levels:alerts') { PriceLevelHit.analyze_manual }
envtask(:gf) { InsiderTransaction.parse_guru_focus }
envtask(:sa) {
  PublicSignal.parse_seeking_alpha
  InsiderAggregate.aggregate
}


envtask('signals') { PublicSignal.load }

envtask('list:clear') do
  puts ENV['tickers'].split(',').map{ |tk| tk.split(':').last }.sort.join("\n")
end

envtask('list:import') do
  list = ENV['list']
  file = Pathname("db/instrument-sets/#{list}.txt")
  text = file.read
  text = text.gsub(',', "\n")
  tickers = text.each_line.map { |line| line.to_s.split(':').last.upcase.chomp.presence }.uniq.compact
  file.write(tickers.join("\n"))
end


task :import => %w[levels:import signals:import]

envtask :check_dead do
  Tinkoff::BadTickers.each do |ticker|
    inst = Instrument.get(ticker)
    if inst
      puts "#{inst} #{inst.candles.day.order(:date).last&.date}"
    end
  end
end

envtask :destroy do
  ENV['ticker'].to_s.split.each do |ticker|
    puts "Destroy #{ticker}"
    Instrument[ticker].destroy! if ENV['ok']
  end
end

envtask :destroy_all_dead do
  Tinkoff::BadTickers.each do |ticker|
    Instrument.get(ticker)&.destroy
  end
end

envtask(:SetIexTickers) { SetIexTickers.call }
envtask(:LoadMissingIexCandles) { LoadMissingIexCandles.call }
envtask(:ReplaceTinkoffCandlesWithIex) { ReplaceTinkoffCandlesWithIex.call }

envtask :empty do
  instruments = Instrument.all.select { |inst| inst.candles.none? }
  puts instruments.join(' ')
end

envtask :set_first_date do
  Instrument.get(ENV['ticker']).update! first_date: ENV['date']
end

envtask :set_first_date_auto do
  (R.instruments_from_env || Instrument.all).to_a.each { |inst| inst.set_first_date! }
end

envtask :service do
  Module.const_get(ENV['s']).call
end


namespace :signal do
  envtask :breakouts do
    instruments = InstrumentSet.known_symbols.sort
    instruments = Instrument.all
    PriceSignal.find_breakouts instruments, direction: :up
    # PriceSignal.find_breakouts instruments, direction: :down
    # PriceSignal.find_breakouts(%w[AMEZ])
  end

  envtask :results do
    # PriceSignal.outside_bars.up.limit(500).each { |signal| PriceSignalResult.create_for signal }
    # PriceSignal.outside_bars.each { |signal| PriceSignalResult.create_for signal }
    PriceSignal.breakouts.each { |signal| PriceSignalResult.create_for signal }
    # PriceSignal.breakouts.where(ticker: %w[AMEZ]).each { |signal| PriceSignalResult.create_for signal }
  end

  envtask :aggregate do
    PriceSignalStrategy.create_some
  end
end


namespace :options do
  envtask :specs do
    OptionItemSpec.create_all InstrumentSet.known_instruments.map(&:iex_ticker).compact.sort
    # OptionItemSpec.create_all Instrument.iex_sourceable.abc.pluck(:iex_ticker)
    # OptionItemSpec.create_all Instrument.for_tickers(%w[ALTO ZIM]).abc.pluck(:iex_ticker)
  end

  envtask :week do
    OptionItem.import_all InstrumentSet.known_instruments.map(&:iex_ticker).compact.sort.select { |t| t > 'ATEX' }, range: '1w'
    # OptionItem.import_all R.instruments_from_env || Instrument.iex_sourceable, range: '1w'
    # OptionItem.import_all Instrument.for_tickers(%w[ALTO ZIM]).abc.pluck(:iex_ticker), range: '1w'
  end

  envtask :day do
    # OptionItem.load_all Instrument.iex_sourceable.abc.pluck(:ticker), range: '1d'
    # instruments = Instrument.iex_sourceable.abc.where('ticker >= ?', 'C').pluck(:iex_ticker)
    instruments = R.instruments_from_env || InstrumentSet.known_instruments # .select { |t| t > 'T' }
    Current.parallelize_instruments(instruments.map(&:iex_ticker).sort, IEX_RPS) do |inst|
      OptionItem.import inst, range: '1d'
    end
  end
end

task :close => 'tinkoff:candles:import:5min:last'
task :pre => 'tinkoff:prices:pre'


envtask :set_average_volume do
  Instrument.find_each &:set_average_volume
end

envtask :pantini do
  PantiniArbitrageParser.connect 'XFRA'
  PantiniArbitrageParser.connect 'US'
  PantiniArbitrageParser.connect 'TG'
end

envtask :book do
  Orderbook.sync ENV['ticker']
end

envtask :arb do
  Synchronizer.call
end

envtask :m5 do
  loop do
    puts "Syncing M5..."
    Tinkoff.load_trading_5m_candles
    loop do
      sleep 5
      time = Time.current
      break if time.min % 5 == 0 && time.sec < 9
    end
  end
end

__END__

rake aggregate date=2021-08-09
