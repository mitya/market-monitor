class DashboardsController < ApplicationController
  def today
    now = current_market == 'rub' ? Current.ru_time : Current.us_time
    instruments = @instruments || PermaCache.current_instruments_for_market(current_market)

    PriceCache.preload instruments
    CandleCache.preload! instruments, dates: [current_calendar.today, current_calendar.yesterday]
    oldest_candles = RecentChanges.oldest_candles_for_periods instruments, periods: [1, 5, 15, 60], now: now
    recent_gains, recent_losses, recent_changes = RecentChanges.prepare instruments, periods: [15, 60], now: now

    rows = instruments.map do |inst|
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
        last_to_60m_ago:         inst.gain_since(oldest_candles[60][inst.ticker]&.close, :last),
        last_to_15m_ago:         inst.gain_since(oldest_candles[15][inst.ticker]&.close, :last),
        last_to_05m_ago:         inst.gain_since(oldest_candles[ 5][inst.ticker]&.close, :last),
        last_to_01m_ago:         inst.gain_since(oldest_candles[ 1][inst.ticker]&.close, :last),
        yesterday_volume:        inst.yesterday&.volume_in_money,
        volume:                  inst.last_day&.volume_in_money,
        volatility:              inst.last_day&.volatility.to_f * 100,
        rel_volume:              inst.info.relative_volume.to_f * 100,
        d5_volume:               inst.info.avg_d5_money_volume,
        avg_change:              inst.info.avg_change.to_f * 100,
        change_in_15:            recent_changes[15][inst.ticker].to_f,
        change_in_60:            recent_changes[60][inst.ticker].to_f,
        gain_in_60:              recent_gains[60][inst.ticker].to_f,
        loss_in_60:              recent_losses[60][inst.ticker].to_f,
      )
    end

    market_favorites = TickerSet.favorites.instruments.select { _1.currency == current_currency }.pluck(:ticker).to_set
    # favorites, rows = rows.partition { market_favorites.include? _1.ticker }

    @groups = if current_market == 'rub'
      ignored, rows = rows.partition { MarketInfo::MoexIgnored.include? _1.instrument.ticker }
      illiquid, rows = rows.partition { _1.instrument.illiquid? }
      { main: rows, favorites: [], illiquid: illiquid }
    else
      { current: rows, favorites: [] }
    end

    sort_field = params[:sort].to_s.to_sym || :change
    asc_sorts = %i[ticker change_since_today_high]
    @groups = @groups.transform_values { |group_rows| group_rows.sort_by { _1.send(sort_field) || 0 } }
    @groups = @groups.transform_values { |group_rows| group_rows.reverse } unless asc_sorts.include?(sort_field)
  end

  def favorites
    @instruments = TickerSet.favorites.instruments.select { _1.currency == current_currency }
    today
    render :today
  end

  def momentum
    @instruments = PermaCache.current_instruments_for_market(current_market)
    @instruments.reject! &:ignored?
    @now = current_market == 'rub' ? Current.ru_time : Current.us_time

    PriceCache.preload @instruments
    CandleCache.preload! @instruments, dates: [current_calendar.today, current_calendar.yesterday]
    recent_gains, recent_losses = RecentChanges.prepare @instruments, periods: [15, 60], now: @now

    @instrument_rows = @instruments.map do |inst|
      OpenStruct.new(
        instrument:              inst,
        ticker:                  inst.ticker,
        last:                    inst.last,
        volume:                  inst.last_day&.volume_in_money,
        volatility:              inst.last_day&.volatility.to_f * 100,
        rel_volume:              inst.info.relative_volume.to_f * 100,
        d5_volume:               inst.info.avg_d5_money_volume,
        change:                  inst.change_since_close,
        change_since_today_low:  inst.gain_since(inst.today_low, :last),
        change_since_today_high: inst.gain_since(inst.today_high, :last),
        gain_in_15:              recent_gains [15][inst.ticker].to_f,
        loss_in_15:              recent_losses[15][inst.ticker].to_f,
        gain_in_60:              recent_gains [60][inst.ticker].to_f,
        loss_in_60:              recent_losses[60][inst.ticker].to_f,
      )
    end
    @instrument_rows = @instrument_rows.select { _1.change.present? }

    @top_gainers = @instrument_rows.sort_by { _1.change }.last(20).reverse
    @top_losers  = @instrument_rows.sort_by { _1.change }.first(20)
    @volume_gainers = @instrument_rows.sort_by { _1.rel_volume }.last(20).reverse

    gainers_sort_period = params[:gainers_sort_period] || 15
    @recent_gainers = @instrument_rows.sort_by { _1.send("gain_in_#{gainers_sort_period}") }.last(20).reverse
    @recent_losers  = @instrument_rows.sort_by { _1.send("loss_in_#{gainers_sort_period}") }.first(20)

    @signals = PriceSignal.intraday.today.where(ticker: @instruments).order(time: :desc).includes(:instrument, :m1_candle).where('time > ?', (Current.msk.now - 2.hours).strftime('%H:%M')).first(300)
    @level_hits = PriceLevelHit.where(ticker: @instruments).intraday.today.order(time: :desc)
  end

  def week
    instruments = PermaCache.instruments_for_market(current_market)
    monday = params[:week].to_s.to_date || Current.today.beginning_of_week
    dates = current_calendar.open_days(monday, monday + 6)
    CandleCache.preload! instruments, dates: dates
    number_of_gainers = current_market == 'rub' ? 15 : 30

    @results = dates.each_with_object({}) do |date, hash|
      candles = instruments.map { _1.day_candles!.find_date(date) }.compact
      candles_by_change = candles.sort_by(&:rel_close_change)
      gainers = candles_by_change.last(number_of_gainers).reverse
      losers  = candles_by_change.first(number_of_gainers)

      used_tickers = (gainers + losers).map(&:ticker).to_set
      unused_candles = candles.reject { _1.ticker.in? used_tickers }

      volume_gainers = unused_candles.sort_by(&:volume_to_average).last(15).reverse
      volatile = unused_candles.sort_by(&:volatility_abs).last(15).reverse

      result = OpenStruct.new(
        gainers: gainers, losers: losers, volume_gainers: volume_gainers, volatile: volatile
      )

      hash[date] = result
    end
  end

  def week_spikes
    instruments = PermaCache.instruments_for_market(current_market)
    monday = params[:week].to_s.to_date || Current.today.beginning_of_week
    dates = current_calendar.open_days(monday, monday + 6)
    CandleCache.preload! instruments, dates: dates

    all_spikes = Spike.where(date: dates, ticker: instruments).order(:spike).group_by(&:date)
    @results = dates.each_with_object({}) do |date, hash|
      spikes = all_spikes[date].to_a.reject { _1.spike.abs < 0.05 }
      spikes_index = spikes.index_by &:ticker
      ups, downs = spikes.partition &:up?
      ups = ups.sort_by(&:spike).reverse

      result = OpenStruct.new(
        spikes_up: ups, spikes_down: downs
      )

      hash[date] = result
    end
  end

  def week_extremums
    instruments = PermaCache.instruments_for_market(current_market)
    params[:week] ||= Current.today.beginning_of_week.to_s
    dates = if params[:week]
      monday = params[:week].to_date
      current_calendar.open_days(monday, monday + 6)
    else
      last_date = Current.yesterday
      current_calendar.open_days(last_date - 15.days, last_date).last(7)
    end
    extremum_updates = ExtremumUpdate.where(date: dates, ticker: instruments).order(:ticker).group_by(&:date)
    CandleCache.preload instruments, dates: dates

    @results = dates.each_with_object({}) do |date, hash|
      ups, downs = extremum_updates[date].to_a.partition &:new_high?
      hash[date] = OpenStruct.new(ups:, downs:)
    end
  end

  def averages
    show_all = params[:all].present? || current_market == 'rub'
    selector = show_all ? :instruments_for_market : :current_instruments_for_market
    instruments = PermaCache.send(selector, current_market)
    dates = [Current.date]
    CandleCache.preload! instruments, dates
    PriceCache.preload instruments

    rows = instruments.map do |inst|
      OpenStruct.new(
        instrument:              inst,
        ticker:                  inst.ticker,
        indicators:              inst.indicators,
        change:                  inst.change_since_close,
        change_in_3d:            inst.change_in_3d,
        change_to_ema_20:        inst.change_to_ema_20,
        change_to_ema_50:        inst.change_to_ema_50,
        change_to_ema_200:       inst.change_to_ema_200,
        change_since_w2_low:     inst.change_since_w2_low,
        change_since_w2_high:    inst.change_since_w2_high,
        change_since_month_low:  inst.change_since_month_low,
        change_since_month_high: inst.change_since_month_high,
      )
    end
    rows.select! { _1.change_to_ema_20 && _1.change_since_month_low }

    @groups = if current_market == 'rub'
      illiquid, rows = rows.partition { _1.instrument.illiquid? }
      { all: rows, illiquid: illiquid }
    else
      favorite_tickers = TickerSet.favorites.instruments.select { _1.currency == current_currency }.pluck(:ticker).to_set
      current_tickers = TickerSet.current.tickers.to_set
      favorites, rows = rows.partition { favorite_tickers.include? _1.ticker }
      current, rows = rows.partition { current_tickers.include? _1.ticker }
      { favorites: favorites, current: current, other: show_all ? rows : nil }.compact
    end

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

    CandleCache.preload! @instruments
    PriceCache.preload @instruments
  end
end
