envtask :main do
  # rake 'iex:days:previous'
  rake 'tinkoff:days:previous'
  # if Current.weekend?
  #   # rake 'iex:prices'          unless R.false?(:price)
  # elsif Current.us_market_open?
  #   # rake 'iex:prices'          unless R.false?(:price)
  #   rake 'tinkoff:prices:uniq' unless R.false?(:price)
  # elsif Current.uk_market_open?
  #   # rake 'iex:prices:uniq'     unless R.false?(:price)
  #   rake 'tinkoff:prices:uniq' unless R.false?(:price)
  # else
  #   # rake 'iex:prices:uniq'     unless R.false?(:price)
  #   rake 'tinkoff:prices:uniq' unless R.false?(:price)
  # end
  rake 'process'
end


task 'missing'    => %w[iex:days:missing]
task 'prices'     => %w[iex:prices]
task 'prices+'    => %w[iex:prices tinkoff:prices:liquid]
task 'prices:rus' => %w[tinkoff:prices:uniq]
task 'prices:all' => %w[iex:prices tinkoff:prices:uniq]
task 'a'          => %w[aggregate analyze]
task 'import'     => %w[levels:import signals:import]
task 'close'      => %w[tinkoff:candles:import:5min:last]
task 'pre'        => %w[tinkoff:prices:pre]
task 'sync'       => %w[intraday:sync]
task 'sync:ru'    => %w[intraday:sync:ru]
task 'sync:us'    => %w[intraday:sync:us]
task 'today'      => %w[tinkoff:candles:today]
task 'averages'   => %w[candles:set_average_volume candles:set_d5_volume]
task 'futures'    => %w[tinkoff:futures]

task :weekly => %w[candles:set_average_change]

envtask(:SetIexTickers) { SetIexTickers.call }
envtask(:LoadMissingIexCandles) { LoadMissingIexCandles.call }
envtask(:ReplaceTinkoffCandlesWithIex) { ReplaceTinkoffCandlesWithIex.call }
envtask(:set_first_date) { Instrument.get(ENV['ticker']).update! first_date: ENV['date'] }
envtask(:set_first_date_auto) { (R.instruments_from_env || Instrument.active).to_a.each { |inst| inst.set_first_date! } }
envtask(:service){ Module.const_get(ENV['s']).call }
envtask(:book)   { Orderbook.sync ENV['ticker'] }
envtask(:arb)    { Synchronizer.call }
envtask(:spikes) { Spike.scan_all since: Spike.maximum(:date) }
envtask(:extremum_updates) { ExtremumUpdate.search_for Instrument.active, date: Current.yesterday }
envtask(:news)   { Synchronizer.sync_news }


envtask('empty:iex')     { puts Instrument.iex_sourceable.select { |inst| inst.candles.none? }.join(' ') }
envtask('empty:tinkoff') { puts Instrument.non_iex.select { |inst| inst.candles.none? }.join(' ') }

envtask :pantini do
  PantiniArbitrageParser.connect 'XFRA'
  PantiniArbitrageParser.connect 'US'
  PantiniArbitrageParser.connect 'TG'
end

__END__
