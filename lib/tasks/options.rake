namespace :options do
  envtask :specs do
    OptionItemSpec.create_all InstrumentSet.known_instruments.map(&:iex_ticker).compact.sort
    # OptionItemSpec.create_all Instrument.iex_sourceable.abc.pluck(:iex_ticker)
    # OptionItemSpec.create_all Instrument.for_tickers(%w[ALTO ZIM]).abc.pluck(:iex_ticker)
  end

  envtask :week do
    OptionItem.import_all R.instruments_from_env, range: '1w', spread: 0.2, depth: 2, date: ENV['date'].presence
    # OptionItem.import_all InstrumentSet.known_instruments.map(&:iex_ticker).compact.sort.select { |t| t > 'ATEX' }, range: '1w'
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
