class SetIexTickers
  include StaticService

  def call
    # Instrument.usd.find_each { |inst| inst.update! iex_ticker: Instrument.iex_ticker_for(inst.ticker) }
    # Instrument.usd.find_each { |inst| inst.update! iex_ticker: nil if inst.ticker =~ /@GS/ }
    # Instrument.find_each &method(:fix_iex_ticker)
    Instrument.find_each { |inst| process inst }
  end

  def process(inst)
    inst.update! iex_ticker: inst.usd?? iex_ticker_for(inst.ticker) : nil
  end

  def iex_ticker_for(ticker)
    ticker_fixes = { 'KAP@GS' => nil }
    ticker_fixes.include?(ticker) ?
      ticker_fixes[ticker] :
      ticker.include?('@GS') ?
        nil :
        ticker.sub(/\.US|@US/, '')
  end
end
