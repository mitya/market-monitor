namespace :signals do
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

  envtask :earnings_breakouts do
    PriceSignal.find_earnings_breakouts Instrument.all
  end
end

envtask('signals') { PublicSignal.load }
