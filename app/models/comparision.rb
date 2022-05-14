class Comparision
  attr :base_date, :selector, :base_prices

  def initialize(base_date, selector: :close)
    @base_date = base_date.to_date
    @selector = selector
    @base_prices = {}
  end

  def price_on_date_for(instrument, date) = Instrument[instrument].price_on!(date.to_date)&.send(selector)

  def price_on_base_date_for(instrument)
    instrument = Instrument[instrument]
    @base_prices ||= {}
    @base_prices[instrument.ticker] = price_on_date_for(instrument, base_date)
  end

  def value_on(instrument, date)
    instrument = Instrument[instrument]
    base_price = price_on_base_date_for(instrument)
    date_price = price_on_date_for(instrument, date)
    return nil unless base_price && date_price
    ratio = date_price / base_price
    percent = (ratio * 100 - 100).to_i
  end

  def values_for(instrument, dates)
    dates.map { |date| value_on instrument, date }
  end

  def values_for_all(instruments, dates)
    instruments = instruments.map(&Instrument)
    CandleCache.preload instruments, dates

    instruments.each_with_object({}) { |inst, hash| hash[inst.ticker] = values_for(inst, dates) }
  end
end

__END__

Comparision.new('2021-05-21').price_on_base_date_for('DK').to_s
Comparision.new('2021-05-21').price_on_date_for('DK', '2021-06-02').to_s
Comparision.new('2021-05-21').value_on(  'DK', '2021-06-02').to_s
Comparision.new('2021-05-21').value_on('FANG', '2021-06-02').to_s
Comparision.new('2021-05-21').value_on(  'DK', '2021-01-07').to_s
Comparision.new('2021-05-21').value_on('FANG', '2021-01-07').to_s

Comparision.new('2021-05-21', %w[DK FANG CLR]).values_on('2021-05-01')
Comparision.new('2021-05-21').values_for('DK', '2021-05-01').map(&:to_s)
Comparision.new('2021-05-21').values_for_all(%w[DK FANG CLR], '2021-05-01')
