class DashboardsController < ApplicationController
  def today
    now = current_market == 'rub' ? Current.ru_time : Current.us_time
    @instruments = Instrument.active.intraday_traded_on(current_market)
    InstrumentCache.set @instruments
    # Price.sync_with_last_candles @instruments

    @all_candles = Candle::M1.for(@instruments).today
    @candles = {}
    [1, 5, 15, 60].each do |duration|
      last_candle_ids = @all_candles.where('time < ?', (now - duration.minutes).strftime('%H:%M')).group(:ticker).pluck('max(id)')
      @candles[duration] = @all_candles.where(id: last_candle_ids).index_by(&:ticker)
    end

    PriceCache.preload @instruments
    CandleCache.preload @instruments, dates: [current_calendar.today, current_calendar.yesterday]

    recent_gains, recent_losses, recent_changes = RecentChanges.prepare @instruments, intervals: [15, 60], now: now

    @rows = @instruments.map do |inst|
      OpenStruct.new(
        ticker:                  inst.ticker,
        instrument:              inst,
        last:                    inst.last,
        change:                  inst.gain_since(inst.yesterday_close, :last),
        change_since_open:       inst.gain_since(inst.today_open, :last),
        change_since_today_low:  inst.gain_since(inst.today_low, :last),
        change_since_today_high: inst.gain_since(inst.today_high, :last),
        last_to_yesterday_open:  inst.gain_since(inst.yesterday_open, :last),
        last_to_today_open:      inst.gain_since(inst.today_open, :last),
        last_to_60m_ago:         inst.gain_since(@candles[60][inst.ticker]&.close, :last),
        last_to_15m_ago:         inst.gain_since(@candles[15][inst.ticker]&.close, :last),
        last_to_05m_ago:         inst.gain_since(@candles[ 5][inst.ticker]&.close, :last),
        last_to_01m_ago:         inst.gain_since(@candles[ 1][inst.ticker]&.close, :last),
        yesterday_volume:        inst.yesterday&.volume_in_money,
        volume:                  inst.last_day&.volume_in_money,
        volatility:              inst.last_day&.volatility.to_f * 100,
        rel_volume:              inst.info.relative_volume.to_f * 100,
        d5_volume:               inst.info.avg_d5_money_volume,
        change_in_15:            recent_changes[15][inst.ticker].to_f,
        change_in_60:            recent_changes[60][inst.ticker].to_f,
      )
    end

    ignored_tickers = %w[DASB GRNT MRKC MRKS MRKU MRKV MRKZ MSRS UPRO VRSB RENI GTRK TORS TGKBP MGTSP PMSBP MRKY].to_set
    watched_tickers = %w[AFKS AGRO AMEZ ENPG ETLN FESH FIVE GAZP GLTR GMKN KMAZ LNTA MAGN MTLR MTLRP MVID NMTP OZON POGR POLY RASP RNFT ROSN RUAL SGZH SMLT TCSG VKCO].to_set
    @ignored, @rows           = @rows.partition { ignored_tickers.include? _1.instrument.ticker }
    # @watched, @rows           = @rows.partition { watched_tickers.include? _1.instrument.ticker }
    # @liquid, @rows            = @rows.partition { _1.instrument.liquid? }
    @very_illiquid, @rows = @rows.partition { _1.instrument.very_illiquid? }
    # @groups = [@watched, @liquid, @illiquid, @very_illiquid]
    # @groups = [@rows]

    @groups = if current_market == 'rub'
      { main: @rows, illiquid: @very_illiquid }
    else
      # { main: @rows[0 .. (@rows.size / 2)], reverse: @rows[(@rows.size / 2 + 1) .. -1] }
      { main: @rows }
    end

    sort_field = params[:sort] || :change
    @groups = @groups.transform_values { |rows| rows.sort_by { _1.send(sort_field) || 0 }.reverse }
  end

  def momentum
    @instruments = Instrument.active.intraday_traded_on(current_market)
    @now = current_market == 'rub' ? Current.ru_time : Current.us_time

    InstrumentCache.set @instruments
    PriceCache.preload @instruments
    CandleCache.preload @instruments, dates: [current_calendar.today, current_calendar.yesterday]

    recent_gains, recent_losses = RecentChanges.prepare @instruments, intervals: [15, 60], now: @now

    @instrument_rows = @instruments.map do |inst|
      OpenStruct.new(
        instrument: inst,
        ticker:     inst.ticker,
        last:       inst.last,
        volume:     inst.last_day&.volume_in_money,
        volatility: inst.last_day&.volatility.to_f * 100,
        rel_volume: inst.info.relative_volume.to_f * 100,
        d5_volume:  inst.info.avg_d5_money_volume,
        change:     inst.change_since_close,
        gain_in_15: recent_gains [15][inst.ticker].to_f,
        loss_in_15: recent_losses[15][inst.ticker].to_f,
        gain_in_60: recent_gains [60][inst.ticker].to_f,
        loss_in_60: recent_losses[60][inst.ticker].to_f,
        change_since_today_low:  inst.gain_since(inst.today_low, :last),
        change_since_today_high: inst.gain_since(inst.today_high, :last),
      )
    end
    @instrument_rows = @instrument_rows.select { _1.change.present? }

    @top_gainers = @instrument_rows.sort_by { _1.change }.last(20).reverse
    @top_losers  = @instrument_rows.sort_by { _1.change }.first(20)
    @volume_gainers = @instrument_rows.sort_by { _1.rel_volume }.last(30).reverse

    gainers_sort_period = params[:gainers_sort_period] || 15
    @recent_gainers = @instrument_rows.sort_by { _1.send("gain_in_#{gainers_sort_period}") }.last(20).reverse
    @recent_losers  = @instrument_rows.sort_by { _1.send("loss_in_#{gainers_sort_period}") }.first(20)

    @signals = PriceSignal.intraday.today.where(ticker: @instruments).order(time: :desc).includes(:instrument, :m1_candle).where('time > ?', (Current.msk.now - 2.hours).strftime('%H:%M')).first(300)
    @level_hits = PriceLevelHit.where(ticker: @instruments).intraday.today.order(time: :desc)
  end

  def last_week
    @instruments = Instrument.active.traded_on(current_market)
    @dates = MarketCalendar.open_days(15.days.ago, currency: current_market).last(6)
    CandleCache.preload @instruments, dates: @dates
    InstrumentCache.set @instruments
    number_of_gainers = current_market == 'rub' ? 15 : 30

    @results = @dates.each_with_object({}) do |date, hash|
      candles = @instruments.map { _1.day_candles!.find_date(date) }.compact
      candles_by_change = candles.sort_by(&:rel_close_change)
      gainers = candles_by_change.last(number_of_gainers).reverse
      losers  = candles_by_change.first(number_of_gainers)

      used_tickers = (gainers + losers).map(&:ticker).to_set
      unused_candles = candles.reject { _1.ticker.in? used_tickers }

      volume_gainers = unused_candles.sort_by(&:volume_to_average).last(15).reverse # .select { _1.volume_to_average > 2 }
      volatile = unused_candles.sort_by(&:volatility_abs).last(15).reverse          #.select { _1.volatility_abs > 0.1 }

      result = OpenStruct.new(
        gainers: gainers, losers: losers, volume_gainers: volume_gainers, volatile: volatile
      )

      hash[date] = result
    end
  end

  def last_week_spikes
    @instruments = Instrument.active.traded_on(current_market)
    @dates = MarketCalendar.open_days(15.days.ago, currency: current_market).last(6) - [Current.date]
    CandleCache.preload @instruments, dates: @dates
    InstrumentCache.set @instruments

    @results = @dates.each_with_object({}) do |date, hash|
      spikes = Spike.where(date: date, ticker: @instruments).order(:spike)
      spikes = spikes.reject { _1.spike.abs < 0.05 }
      spikes_index = spikes.index_by &:ticker
      ups, downs = spikes.partition &:up?
      ups = ups.sort_by(&:spike).reverse

      result = OpenStruct.new(
        spikes_up: ups, spikes_down: downs
      )

      hash[date] = result
    end
  end

  def averages
    @instruments = Instrument.active.traded_on(current_market).includes(:indicators)
    @dates = [Current.date]
    CandleCache.preload @instruments, @dates
    PriceCache.preload @instruments
    InstrumentCache.set @instruments

    @rows = @instruments.map do |inst|
      OpenStruct.new(
        instrument:           inst,
        change:               inst.change_since_close,
        change_in_3d:         inst.change_in_3d,
        change_to_ema_20:     inst.change_to_ema_20,
        change_to_ema_50:     inst.change_to_ema_50,
        change_to_ema_200:    inst.change_to_ema_200,
        change_since_w2_low:  inst.change_since_w2_low,
        change_since_w2_high: inst.change_since_w2_high,
        change_since_month_low:  inst.change_since_month_low,
        change_since_month_high: inst.change_since_month_high,
      )
    end

    @rows.select! { _1.change_to_ema_20 && _1.change_since_month_low }

    ignored_tickers = %w[DASB GRNT MRKC MRKS MRKU MRKV MRKZ MSRS UPRO VRSB RENI GTRK TORS TGKBP MGTSP PMSBP MRKY  TGKA TGKB TGKBP TGKDP TGKN].to_set
    watched_tickers = %w[AFKS AGRO AMEZ ENPG ETLN FESH FIVE GAZP GLTR GMKN KMAZ LNTA MAGN MTLR MTLRP MVID NMTP OZON POGR POLY RASP RNFT ROSN RUAL SGZH SMLT TCSG VKCO].to_set
    @ignored, @rows  = @rows.partition { ignored_tickers.include? _1.instrument.ticker }
    @watched, @rows  = @rows.partition { watched_tickers.include? _1.instrument.ticker }
    @illiquid, @rows = @rows.partition { _1.instrument.illiquid? }
    @groups = {
      watched: @watched,
      other: @rows,
      illiquid: @illiquid,
    }

    sort_field = params[:sort] || :change_to_ema_50
    @groups = @groups.transform_values { |rows| rows.sort_by { _1.send(sort_field) || 0 }.reverse }
  end

  def timeline
    @is_morning = !Current.us_market_open?
    @market_open_time_in_mins = @is_morning ? 0 * 60 : 9 * 60 + 30
    @market_open_time_in_mins_utc = @market_open_time_in_mins + 4 * 60
    @market_open_time_in_hhmm_utc = helpers.format_as_minutes_since @market_open_time_in_mins_utc, 0

    @instruments = InstrumentSet[:trading].scope.order(:ticker)
    @candles = Candle::M5.where(ticker: @instruments, date: Current.date).order(:time)
    @candles = @candles.select { |candle| candle.time_before_type_cast >= @market_open_time_in_hhmm_utc }
    @candles_by_ticker = @candles.group_by(&:ticker)

    @opens                  = @candles_by_ticker.transform_values { |candles| candles.first }
    @lasts                  = @candles_by_ticker.transform_values { |candles| candles.last }
    @highs                  = @candles_by_ticker.transform_values { |candles| candles.max_by(&:high) }
    @lows                   = @candles_by_ticker.transform_values { |candles| candles.min_by(&:low) }
    @candles_by_ticker_time = @candles_by_ticker.transform_values { |candles| candles.index_by(&:time_before_type_cast) }
    @minutes_in_session = @is_morning ? 570 : 385
    @minutes = (0..@minutes_in_session).step(5).to_a

    @candles_by_ticker = @candles_by_ticker.map do |ticker, candles|
      candles = if by_time = @candles_by_ticker_time[ticker]
        @minutes.map { |minute| by_time["#{helpers.format_as_minutes_since @market_open_time_in_mins_utc, minute}:00"] || nil }
      end
      [ticker, candles.to_a]
    end.to_h

    CandleCache.preload @instruments
    PriceCache.preload @instruments
  end
end
