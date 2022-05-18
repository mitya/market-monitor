class IntradayAnalyzer
  include StaticService

  def analyze(instrument, candles)
    return if candles.blank?
    instrument.transaction do
      candles_history = candles.first.same_day_siblings.where('time >= ? AND time < ?', candles.first.time - 2.hours, candles.first.time).order(:time) + candles
      watches = instrument.watched_targets.pending.order(:expected_price)
      candles.each do
        check_watches _1, instrument, watches
        analyze_one   _1, instrument, candles_history
      end
    end
    nil
  end

  def analyze_one(candle, instrument, candles_history)
    average_volume = instrument.info.average_volume_for(candle.interval)
    m1_big_change = candle.instrument.rub?? 0.015 : 0.01
    m1_big_volume = 7 * average_volume if average_volume
    m1_very_big_volume = 15 * average_volume if average_volume
    m5_big_change = candle.instrument.rub?? 0.03 : 0.02

    last_2_hours = candles_history.select { _1.time.between? candle.time - 2.hours, candle.time - 1.second }

    # candle_index_in_history = @candles_history.index_of(candle)
    # previous_n = @candles_history[[candle_index_in_history - 5, 0].max .. candle_index_in_history]
    # previous_n_change = candle.close - previous_n.first.open
    # previous_n_rel_change = previous_n_change / previous_n.first.open

    # elsif previous_n_rel_change > m5_big_change
    #   emit! :big_change, candle

    if candle.rel_change.abs > m1_big_change
      emit! :big_change, candle
    elsif m1_big_volume && (
          candle.volume > m1_very_big_volume ||
          candle.volume > m1_big_volume && last_2_hours.none? { _1.volume > candle.volume } )
      emit! :volume_spike, candle
    end

    candle.analyzed!

    # minutes_since_opening = 0
    # summary = instrument.day_summary
    #
    # if minutes_since_opening < 15
    #   candle.analyzed!
    #   return
    # end
    #
    # if candle.include?(summary.today_opening)
    #   emit! :hit, :today_open, candle, value: summary.today_opening
    # end
    #
    # if candle.include?(summary.yesterday_closing)
    #   emit! :hit, :yesterday_close, candle, value: summary.yesterday_closing
    # end
    #
    # intraday_levels.each do |level|
    #   if candle.include? level
    #     emit! :hit, :level, candle, value: level
    #   end
    # end
  end

  def emit!(signal, candle, **data)
    average_volume = candle.instrument.info.average_volume_for(candle.interval)
    up = candle.up? && candle.top_shadow_rel_size < 0.5 || candle.bottom_shadow_rel_size > 0.5
    puts "Detected at #{candle.time_str} #{signal} #{candle.ticker}".magenta
    PriceSignal.create! kind: signal.to_s.dasherize, data: data.compact,
      ticker:     candle.ticker,
      candle_id:  candle.id,
      date:       candle.date,
      time:       candle.time,
      interval:   candle.interval,
      direction:  up ? 'up' : 'down',
      rel_volume: (candle.volume / average_volume rescue 0),
      change:     candle.rel_change
  end

  def check_watches(candle, instrument, watches)
    watches.select { _1.hit_in? candle }.each do
      _1.hit!
    end
  end

  def analyze_candle(candle)
    return if candle == nil
    puts "Analyze #{candle}".cyan

    curr = candle
    siblings = candle&.same_day_siblings
    curr_index = siblings.index(curr)
    curr.analyzed! && return if curr_index < 5 || curr_index > siblings.size - 5

    recent = siblings[curr_index - 5 ... curr_index]
    recent_low = recent.map(&:low).min
    recent_max_change = recent.map(&:rel_change).max

    prev = recent[curr_index - 1]
    prev_rel_change = (curr.close - prev.open) / prev.open if prev

    candle_attrs = { ticker: candle.instrument, date: candle.date, time: candle.time, direction: candle.direction }


    # .5% change in a candle
    if curr.rel_close_change.abs >= 0.005
      PriceSignal.create! candle_attrs.merge kind: 'intraday.big-change', data: { change: curr.rel_close_change.to_f }

    # .5% change in 2 candles
    elsif prev_rel_change.to_f.abs >= 0.005
      PriceSignal.create! candle_attrs.merge kind: 'intraday.big-change-2', data: { change: prev_rel_change.to_f }
    end

    if curr.volatility_above >= 0.01
      PriceSignal.create! candle_attrs.merge kind: 'intraday.up-spike', direction: 'down', data: { change: candle.volatility_above.to_f }
    end

    if curr.volatility_below >= 0.01
      PriceSignal.create! candle_attrs.merge kind: 'intraday.down-spike', direction: 'up', data: { change: candle.volatility_below.to_f }
    end

    # remember signals in candle

    # find day high / low breakout
    # find yesterday high / low breakout
    # find day high / low retest (± .2%)
    # find predefined level hits, DMA hits, prev 7 day extremum hits (if there was signinficant)
    # * find volume spikes (3x above average, especially without large move)


    curr.analyzed!


    # if curr.down? && curr.rel_change.abs >= 0.005 && curr.low < recent_low && curr.rel_change.abs > recent_max_change.abs
    #   puts "Found #{curr.date} #{curr.time.to_s :time} #{curr.ticker}"
    # end
    #
    # signal_attrs = { instrument: curr.instrument, date: curr.date, base_date: curr.date, time: curr.time, interval: candle.interval }
    #
    # if match = (curr.absorb?(prev, 0.0) && curr.range_spread_percent > 0.015)
    #   puts "Detect for #{instrument.ticker.ljust 8} at #{curr.time.in_time_zone Current.msk} outside-bar"
    #   create! signal_attrs.merge kind: 'outside-bar',
    #     accuracy: (curr.spread / prev.spread).to_f.round(2),
    #     exact: match == true,
    #     direction: curr.direction, enter: curr.close, stop: curr.min,
    #     stop_size: curr.close_min_rel.abs.to_f.round(4)
    # end
    #
    # pin_vector, ratio = curr.tail_bar?(prev)
    # if pin_vector && ratio > 0.015
    #   puts "Detect for #{instrument.ticker.ljust 8} at #{curr.time.in_time_zone Current.msk} tail-bar #{pin_vector} #{ratio&.round(4)}"
    #   create! signal_attrs.merge kind: 'tail-bar',
    #     direction: pin_vector,
    #     enter: pin_vector == 'up' ? curr.high : curr.low,
    #     stop: pin_vector == 'up' ? curr.low : curr.high,
    #     stop_size: curr.max_min_rel.abs.to_f.round(4),
    #     accuracy: ratio.to_f.round(4)
    # end
  end
end


__END__

hit kind, value, time
hit_kind = level, t_open, y_close, dma, hod_retest, lod_retest


IntradayAnalyzer.analyze instr('gazp')
