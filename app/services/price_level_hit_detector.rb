class PriceLevelHitDetector
  include StaticService

  DELTA = 0.01

  def analyze(instrument, date: nil, levels: nil)
    instrument = Instrument[instrument]
    levels ||= instrument.levels
    date ||= Current.yesterday
    curr = instrument.day_candles!.find_date(date)
    prev = curr&.previous
    return unless curr && prev

    instrument.level_hits.where(date: date).delete_all

    # recent = curr.previous_n(10)
    # recent_ref = recent[-4]
    #
    # levels.order(:value).each do |level|
    #   if is_nearby = curr.range_with_delta(DELTA).include?(level.value)
    #     exact = is_nearby && curr.range.include?(level.value)
    #     delta = exact ? 0 : DELTA
    #     was_on_level_recently = recent.any? { |candle| candle.range_with_delta(delta).include?(level.value) }
    #     kind = 'level'
    #
    #     if prev
    #       if prev > curr && prev.close > level.value_plus(delta)
    #         kind = was_on_level_recently ? 'retest-down' : 'fall'
    #       elsif prev < curr && prev.close < level.value_plus(exact ? 0 : -DELTA)
    #         kind = was_on_level_recently ? 'retest-up' : 'rise'
    #       end
    #     end
    #
    #     record! level: level, date: curr.date, kind: kind, exact: exact
    #   end
    # end
    #
    # where(date: MarketCalendar.prev(curr.date)).each do |yday|
    #   if curr.up? && curr.close > yday.level.value_plus(DELTA)
    #     kind = 'rebound-up' # or just pass through
    #   elsif curr.down? && curr.close < yday.level.value_plus(-DELTA)
    #     kind = 'rebound-down'
    #   end
    #
    #   record! level: yday.level, date: curr.date, kind: kind
    # end

    levels.order(:value).each do |level|
      value = level.value
      attrs = { source: 'level', date: curr.date, level: level }
      check_level curr, prev, value, attrs
    end

    indicators = instrument.indicators_history.find_by(date: curr.date)
    { 20 => indicators&.ema_20, 50 => indicators&.ema_50, 200 => indicators&.ema_200 }.each do |length, value|
      next unless value
      attrs = { source: 'ma', ma_length: length, date: curr.date, ticker: instrument.ticker, level_value: value }
      check_level curr, prev, value, attrs
    end
  end


  def analyze_all(   instruments: Instrument.active.abc, date: Current.yesterday) = instruments.each { analyze _1,                           date: date }
  def analyze_manual(instruments: Instrument.active.abc, date: Current.yesterday) = instruments.each { analyze _1, levels: _1.levels.manual, date: date }


  private

  def check_level(curr, prev, value, attrs)
    open    = curr.open
    close   = curr.close
    high    = curr.high
    low     = curr.low
    y_close = prev.close
    attrs[:close_distance] = ((close - value).abs / value.to_d).round(3)

    last_day_crossed = if attrs[:source] == 'level'
      curr.instrument.level_hits.levels.where(level: attrs[:level]).order(:date).last&.date
    else
      curr.instrument.level_hits.ma.where(ma_length: attrs[:ma_length]).order(:date).last&.date
    end
    days_since_last = last_day_crossed ? curr.date - last_day_crossed : 99

    return if days_since_last < 7 && attrs[:level]

    attrs[:days_since_last] = days_since_last
    attrs[:rel_vol] = curr.volume_to_average.to_f.round(3)

    case
    when open < value && close >= value
      record! 'up-break', **attrs
    when open > value && close > value && low <= value
      record! 'down-test', **attrs.merge(max_distance: ((low - value).abs / value.to_d).round(3))
    when open > value && close >= value && y_close < value
      record! 'up-gap', **attrs

    when open > value && close <= value
      record! 'down-break', **attrs
    when open < value && close < value && high >= value
      record! 'up-test', **attrs.merge(max_distance: ((high - value).abs / value.to_d).round(2))
    when open < value && close < value && y_close > value
      record! 'down-gap', **attrs
    end
  end

  def record!(kind, **attrs)
    hit = PriceLevelHit.find_or_create_by! kind: kind, **attrs
    puts "#{hit.date} hit #{hit.ticker.ljust 8} #{hit.source_name.ljust(5)} #{hit.days_since_last.to_s.ljust(3)} #{hit.kind.ljust(10)} #{hit.level_value}".
      colorize(hit.positive?? :green : :red)
  end
end

__END__
PriceLevelHit.delete_all
PriceLevelHitDetector.analyze_manual date: Current.yesterday
PriceLevelHitDetector.analyze 'AAPL'
MarketCalendar.open_days('2021-07-01').each { PriceLevelHitDetector.analyze_all date: _1 }
