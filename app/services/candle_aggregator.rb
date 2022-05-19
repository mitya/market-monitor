class CandleAggregator
  attr :instrument

  def initialize(instrument)
    @instrument = instrument
  end

  def update_today_candle_intraday(period = '1min')
    intraday_candles = @instrument.candles_for(period).today.by_time.to_a
    return if intraday_candles.empty?
    today = @instrument.today!
    today.update!(
      open:   intraday_candles.first.open,
      close:  intraday_candles.last.close,
      high:   intraday_candles.map(&:high).max,
      low:    intraday_candles.map(&:low).min,
      volume: intraday_candles.sum(&:volume),
    )

    CandleCache.update(today)
  end

  def update_larger_candles(date: Current.date)
    %w[5min].each do |interval|
      minutes_in_interval = Candle.interval_duration_in_mins(interval)
      day_open_time = @instrument.opening_time_without_date
      yesterday = @instrument.yesterday

      last_mx_candle = @instrument.candles_for(interval).on(date).order(:time).last
      last_mx_candle ||= @instrument.candles_for(interval).on(date).build(
        time: day_open_time, open: yesterday&.close, close: yesterday&.close, high: yesterday&.close, low: yesterday&.close
      )

      m1_candles = @instrument.candles_for('1min').on(date).since_time(last_mx_candle.time).order(:time).to_a
      m1_candles_index = m1_candles.index_by &:time
      time_intervals = MarketCalendar.periods_between(last_mx_candle.time, m1_candles.last&.time)

      grouped_intervals = time_intervals.in_groups_of(minutes_in_interval)
      grouped_intervals = grouped_intervals.map do |intervals|
        {
          start:   intervals.first&.to_hhmm,
          periods: intervals.map { _1&.to_hhmm },
          candles: intervals.map { m1_candles_index[_1] },
        }
      end

      Candle.transaction do
        grouped_m1_candles = grouped_intervals.each do |interval_data|
          interval_data => { start:, periods:, candles: }
          candles = candles.compact
          mx_candle = @instrument.candles_for(interval).on(date).find_or_initialize_by(time: start)

          mx_candle.instrument = @instrument
          mx_candle.source     = 'virtual'
          mx_candle.prev_close = last_mx_candle.prev_close
          if candles.any?
            mx_candle.open       = candles.first.open
            mx_candle.close      = candles.last.open
            mx_candle.high       = candles.map(&:high).max
            mx_candle.low        = candles.map(&:low).min
            mx_candle.volume     = candles.sum(&:volume)
            mx_candle.ongoing    = candles.last&.ongoing?
            mx_candle.save!
            last_mx_candle = mx_candle
          else
            next if last_mx_candle.open == nil
            mx_candle.open       = last_mx_candle.open
            mx_candle.close      = last_mx_candle.close
            mx_candle.high       = last_mx_candle.high
            mx_candle.low        = last_mx_candle.low
            mx_candle.ongoing    = last_mx_candle.ongoing?
            mx_candle.volume     = 0
            mx_candle.save!
          end
        end
      end
    end
  end
end
