class SetIexTickers
  include StaticService

  def call
    # Instrument.usd.find_each { |inst| inst.update! iex_ticker: inst.ticker }
    Instrument.usd.find_each do |inst|
      if inst.ticker =~ /@GS|\.US/
        inst.update! iex_ticker: nil
      end
    end
  end
end

__END__
