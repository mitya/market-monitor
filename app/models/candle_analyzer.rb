class CandleAnalyzer
  attr :instrument, :date

  def initialize(instrument, date)
    @instrument = Instrument[instrument]
    @date = date.to_date
    @candle = instrument.candles.day.find_date_before(date)
  end

  def green_days_count
    @candle.each_previous.take_while { |cndl| cndl.up? }.count if @candle
  end

  def red_days_count
    @candle.each_previous.take_while { |cndl| cndl.down? }.count if @candle
  end

  def days_up_count
     @candle&.days_up
  end

  def days_down_count
    @candle&.days_down
  end

  def lowest_day_since(period_start)
    falling_period = period_start.to_date .. Current.date
    instrument.lowest_body_in falling_period
  end
end

__END__

CandleAnalyzer.new('AMZN', '2021-03-23')
CandleAnalyzer.new('QDEL', Date.current).days_up_count
