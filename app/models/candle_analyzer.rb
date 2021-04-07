class CandleAnalyzer
  attr :instrument, :date

  def initialize(instrument, date)
    @instrument = Instrument[instrument]
    @date = date.to_date
  end

  def green_days_count
    candle = instrument.candles.day.find_date(date)&.previous
    candle.each_previous.take_while { |cndl| cndl.up? }.count if candle
  end

  def red_days_count
    candle = instrument.candles.day.find_date(date)&.previous
    candle.each_previous.take_while { |cndl| cndl.down? }.count if candle
  end

  def days_up_count
    candle = instrument.candles.day.find_date(date)&.previous
    candle.each_previous.each_slice(2).take_while { |curr, prev| curr && prev && curr >= prev }.count if candle
  end

  def days_down_count
    candle = instrument.candles.day.find_date(date)&.previous
    candle.each_previous.each_slice(2).take_while { |curr, prev| curr && prev && curr <= prev }.count if candle
  end

  def lowest_day_since(period_start)
    falling_period = period_start.to_date .. Current.date
    instrument.lowest_body_in falling_period
  end
end

__END__

CandleAnalyzer.new('AMZN', '2021-03-23')
CandleAnalyzer.new('QDEL', Date.current).days_up_count
