class SetIexTickers
  include StaticService

  def call
    Instrument.usd.find_each { |inst| inst.update! iex_ticker: inst.ticker }
    Instrument.usd.find_each do |inst|
      inst.update! iex_ticker: nil if inst.ticker =~ /@GS|\.US/
    end
    Instrument.get('TRMK.US').update! iex_ticker: 'TRMK'
    Instrument.get('SPB@US').update! iex_ticker: 'SPB'
  end
end

__END__

Instrument.pluck(:ticker).grep(/@US/)
