class IntradayAnalyzer
  include StaticService

  def analyze(instrument, date: Current.date, interval: '1min')
    instrument.transaction do
      instrument.candles_for(interval).on(date).non_analyzed.order(:time).each do |candle|
        analyze_one instrument, candle
      end
    end
    nil
  end

  def analyze_one(instrument, candle)
    volume_threshold = 5
    average_volume = instrument.info.average_volume_for(candle.interval)

    if candle.volume > volume_threshold * average_volume
      emit! :volume_spike, candle
    end

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

    candle.analyzed!
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
      rel_volume: candle.volume / average_volume,
      change:     candle.rel_change
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

    candle_attrs = { instrument: candle.instrument, date: candle.date, time: candle.time, interval: candle.interval, direction: candle.direction }


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
