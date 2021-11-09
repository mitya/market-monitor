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
    rake 'tinkoff:prices:uniq' unless R.false?(:price)
  end
  rake 'process'
end


envtask :pantini do
  PantiniArbitrageParser.connect 'XFRA'
  PantiniArbitrageParser.connect 'US'
  PantiniArbitrageParser.connect 'TG'
end


task 'prices' => %w[iex:prices]
task 'prices:all' => %w[iex:prices tinkoff:prices:uniq]
task 'a' => %w[aggregate analyze]
task 'import' => %w[levels:import signals:import]
task 'close' => 'tinkoff:candles:import:5min:last'
task 'pre' => 'tinkoff:prices:pre'
task 'trade' => 'intraday:sync'


envtask(:SetIexTickers) { SetIexTickers.call }
envtask(:LoadMissingIexCandles) { LoadMissingIexCandles.call }
envtask(:ReplaceTinkoffCandlesWithIex) { ReplaceTinkoffCandlesWithIex.call }
envtask(:empty) { puts Instrument.all.select { |inst| inst.candles.none? }.join(' ') }
envtask(:set_first_date) { Instrument.get(ENV['ticker']).update! first_date: ENV['date'] }
envtask(:set_first_date_auto) { (R.instruments_from_env || Instrument.all).to_a.each { |inst| inst.set_first_date! } }
envtask(:service){ Module.const_get(ENV['s']).call }
envtask(:book)   { Orderbook.sync ENV['ticker'] }
envtask(:arb)    { Synchronizer.call }
envtask(:spikes) { Spike.scan_all since: 1.week.ago }
envtask(:news)   { Synchronizer.sync_news }


__END__
