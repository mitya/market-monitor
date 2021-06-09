class SetIexTickers
  include StaticService

  def call
    # Instrument.usd.find_each { |inst| inst.update! iex_ticker: Instrument.iex_ticker_for(inst.ticker) }
    # Instrument.usd.find_each { |inst| inst.update! iex_ticker: nil if inst.ticker =~ /@GS/ }
    Instrument.find_each &:fix_iex_ticker
  end
end

__END__
