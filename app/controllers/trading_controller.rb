class TradingController < ApplicationController
  skip_before_action :verify_authenticity_token

  def dashboard
    @is_morning = !Current.us_market_open?
    @market_open_time_in_mins = @is_morning ? 0 * 60 : 9 * 60 + 30
    @market_open_time_in_mins_utc = @market_open_time_in_mins + 4 * 60
    @market_open_time_in_hhmm_utc = helpers.format_as_minutes_since @market_open_time_in_mins_utc, 0

    @instruments = InstrumentSet[:trading].scope.includes(:info, :aggregate).order(:ticker)
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

    Current.preload_day_candles_with @instruments.to_a, []
    Current.preload_prices_for @instruments.to_a
  end

  def activities
    if request.xhr?
      @orders = Order.includes(:instrument).order(:ticker)
      @buys   = @orders.select &:buy?
      @sells  = @orders.select &:sell?
      @operations = Operation.market.passed.today.order(datetime: :desc).includes(:instrument)
      @portfolio = PortfolioItem.where('tinkoff_iis_lots > 0').order(:ticker).includes(:instrument)

      render json: {
        buys:       render_to_string(partial: 'orders/orders_table', locals: { title: 'Buys', orders: @buys }),
        sells:      render_to_string(partial: 'orders/orders_table', locals: { title: 'Buys', orders: @sells }),
        operations: render_to_string(partial: 'operations/operations'),
        portfolio:  render_to_string(partial: 'portfolio/items'),
      }
    end
  end

  def charts
    @chart_settings = Setting.chart_settings
    @chart_settings['columns'] ||= 2
    @chart_settings['rows'] ||= 2
    @chart_settings['period'] ||= '3min'
    @chart_settings['tickers'] ||= []

    @synced_tickers = Setting.sync_tickers.join(' ')
    @sync_ticker_sets = Setting.sync_ticker_sets

    @chart_tickers = Setting.chart_tickers

    @intraday_levels = InstrumentAnnotation.with_intraday_levels
    @intraday_levels_text = @intraday_levels.map(&:intraday_levels_line).join("\n")

    @ticker_sets = TickerSet.list
    @ticker_sets_text = @ticker_sets.map(&:as_line).join("\n")

    @current_ticker_set = @ticker_sets.detect { _1.tickers == @chart_tickers }
    @list_ticker_set = InstrumentSet.new(@current_ticker_set&.key || 'Custom', :static, items: @chart_tickers)

    @list_shown = params[:list] == '1'
    @chart_columns = @list_shown ? 1 : @chart_settings['columns']
    @chart_rows = @list_shown ? 1 : @chart_settings['rows']

    @since_date_str = @chart_settings['since']
  end

  def candles
    is_update = params[:limit] == '1'
    is_single = params[:single] == '1'
    period = Setting.chart_period
    repo = Candle.interval_class_for(period)
    tickers = Setting.chart_tickers.first(12)
    tickers = tickers.first(1) if is_single
    since_date = Setting.chart_settings['since'].to_date

    instruments = Instrument.for_tickers(tickers).includes(:indicators, :annotation)
    instruments = tickers.map { |ticker| instruments.find { _1.ticker == ticker.upcase } }.compact
    openings = Candle::M1.today.openings.for(instruments).index_by(&:ticker)

    candles = instruments.inject({}) do |map, instrument|
      ticker = instrument.ticker
      candles = repo.for(instrument).includes(:instrument).order(:date, :time).since(since_date).last(params[:limit] || (is_single ? 777 : 500))
      map[ticker] = { ticker: ticker }
      map[ticker][:candles] = candles.map { |c| [c.charting_timestamp, c.open.to_f, c.high.to_f, c.low.to_f, c.close.to_f, c.volume] }

      unless is_update
        map[ticker][:opens] = candles.select(&:opening?).map { _1.charting_timestamp } unless period == 'day'
        map[ticker][:levels] = { }
        map[ticker][:period] = period

        # if instruments.one? && period == 'day'
        if period == 'day'
          indicators = instrument.indicators_history.where('date >= ?', candles.map(&:date).min).order(:date)
          indicators += [indicators.last.last] if indicators.last.date != Current.date
          map[ticker][:averages] = { }
          [20, 50, 200].each do |period|
            map[ticker][:averages][period] = indicators.map { [_1.charting_timestamp, _1.send("ema_#{period}")] }.reject { _1.second == nil }
          end
        end

        unless period == 'day'
          map[ticker][:levels].merge!(
            MA20:  instrument.indicators&.ema_20&.to_f,
            MA50:  instrument.indicators&.ema_50&.to_f,
            MA200: instrument.indicators&.ema_200&.to_f,
            open:  openings[instrument.ticker]&.open&.to_f,
            close:  instrument.yesterday&.close&.to_f,
            intraday: instrument.annotation&.intraday_levels,
            # swing: instrument.levels.pluck(:value),
          )
        else
          map[ticker][:levels].merge!(
            # swing: instrument.levels.pluck(:value),
          )
        end
      end
      map
    end
    render json: candles
  end

  def update_chart_settings
    Setting.save 'sync_tickers',     params[:synced_tickers].split.map(&:upcase).sort if params.include?(:synced_tickers)
    Setting.save 'sync_ticker_sets', params[:sync_ticker_sets]                        if params.include?(:sync_ticker_sets)

    updates = { }
    updates[:tickers]       = params[:chart_tickers].split.map(&:upcase) if params.include?(:chart_tickers)
    updates[:columns]       = params[:columns].to_i.nonzero?             if params.include?(:columns)
    updates[:rows]          = params[:rows].to_i.nonzero?                if params.include?(:rows)
    updates[:period]        = Candle.normalize_interval(params[:period]) if params.include?(:period)
    updates[:time_shown]    = params[:time_shown]                        if params.include?(:time_shown)
    updates[:price_shown]   = params[:price_shown]                       if params.include?(:price_shown)
    updates[:wheel_scaling] = params[:wheel_scaling]                     if params.include?(:wheel_scaling)
    updates[:bar_spacing]   = params[:bar_spacing]                       if params.include?(:bar_spacing)
    updates[:level_labels]  = params[:level_labels]                      if params.include?(:level_labels)
    updates[:levels_shown]  = params[:levels_shown]                      if params.include?(:levels_shown)
    updates[:since]         = params[:since].presence                    if params.include?(:since)
    Setting.merge 'chart_settings', updates

    render json: { }
  end

  def update_intraday_levels
    lines = params[:text].split("\n").map(&:squish).reject(&:blank?)
    InstrumentAnnotation.update_intraday_levels_from_lines lines
    render json: { }
  end

  def update_ticker_sets
    TickerSet.update_from_lines params[:text].split("\n")
    render json: { }
  end

  def refresh
    key = { ru: :tinkoff_update_pending, us: :iex_update_pending }[params[:scope].to_s.to_sym]
    Setting.set key, true
    render json: nil
  end

  def recent
    now = Current.ru_time

    @instruments = Instrument.active.traded_on(current_market).includes(:info)
    @all_candles = Candle::M1.for(@instruments).today

    InstrumentCache.set @instruments
    Price.sync_with_last_candles @instruments

    @candles = {}

    [1, 5, 15, 60].each do |duration|
      last_candle_ids = @all_candles.where('time < ?', (now - duration.minutes).strftime('%H:%M')).group(:ticker).pluck('max(id)')
      @candles[duration] = @all_candles.where(id: last_candle_ids).index_by(&:ticker)
    end

    Current.preload_prices_for @instruments.to_a
    Current.preload_day_candles_with @instruments.to_a, [current_calendar.today, current_calendar.yesterday]

    @rows = @instruments.map do |inst|
      OpenStruct.new(
        ticker:                  inst.ticker,
        instrument:              inst,
        last:                    inst.last,
        change:                  inst.gain_since(inst.yesterday_close, :last),
        last_to_yesterday_open:  inst.gain_since(inst.yesterday_open, :last),
        last_to_today_open:      inst.gain_since(inst.today_open, :last),
        last_to_60m_ago:         inst.gain_since(@candles[60][inst.ticker]&.close, :last),
        last_to_15m_ago:         inst.gain_since(@candles[15][inst.ticker]&.close, :last),
        last_to_05m_ago:         inst.gain_since(@candles[ 5][inst.ticker]&.close, :last),
        last_to_01m_ago:         inst.gain_since(@candles[ 1][inst.ticker]&.close, :last),
        yesterday_volume:        inst.d1_ago&.volume_in_money,
        volume:                  inst.last_day&.volume_in_money,
        volatility:              inst.last_day&.volatility.to_f * 100,
        rel_volume:              inst.info.relative_volume.to_f * 100,
        d5_volume:               inst.info.avg_d5_money_volume,
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

    @groups = {
      main: @rows,
      illiquid: @very_illiquid
    }

    sort_field = params[:sort] || :change
    @groups = @groups.transform_values { |rows| rows.sort_by { _1.send(sort_field) || 0 }.reverse }
  end

  # def momentum_ru
  #   @now = Current.ru_time
  #   @market = :ru
  #   @instruments = Instrument.active.rub.includes(:info)
  #   momentum
  # end
  #
  # def momentum_us
  #   @now = Current.us_time
  #   @market = :us
  #   @instruments = Instrument.active.usd.current.includes(:info)
  #   momentum
  # end

  def momentum
    @instruments = Instrument.active.intraday_traded_on(current_market).includes(:info)
    @now = current_market == 'rub' ? Current.ru_time : Current.us_time

    @signals = PriceSignal.intraday.today.where(ticker: @instruments).order(time: :desc).includes(:instrument, :m1_candle).where('time > ?', (Current.msk.now - 2.hours).strftime('%H:%M')).first(300)

    InstrumentCache.set @instruments
    Current.preload_prices_for @instruments.to_a
    Current.preload_day_candles_with @instruments.to_a, [current_calendar.today, current_calendar.yesterday]

    @recent_candles = Candle::M1.for(@instruments).today.where(time: (@now - 15.minutes).to_hhmm .. @now.to_hhmm).order(:time).group_by(&:cached_instrument)
    @recent_changes = @recent_candles.map do |instrument, candles|
      ratio = price_ratio(instrument.last, candles.first.close) if candles.count > 5
      [instrument.ticker, ratio.to_f]
    end.sort_by(&:second).to_h

    @instrument_rows = @instruments.map do |inst|
      OpenStruct.new(
        instrument: inst,
        last:       inst.last,
        volume:     inst.today&.volume_in_money,
        rel_volume: inst.info.relative_volume.to_f * 100,
        volatility: inst.today&.volatility.to_f * 100,
        d5_volume:  inst.info.avg_d5_money_volume,
        change:     inst.change_since_close,
        recent_change: @recent_changes[inst.ticker].to_f,
      )
    end
    @instrument_rows = @instrument_rows.select { _1.change.present? }

    @top_gainers = @instrument_rows.sort_by { _1.change }.last(20).reverse
    @top_losers  = @instrument_rows.sort_by { _1.change }.first(20)
    @volume_gainers = @instrument_rows.sort_by { _1.rel_volume }.last(30).reverse
    @recent_gainers = @instrument_rows.sort_by { _1.recent_change }.last(20).reverse
    @recent_losers  = @instrument_rows.sort_by { _1.recent_change }.first(20)

    @level_hits = PriceLevelHit.where(ticker: @instruments).intraday.today.order(time: :desc)

    render :momentum
  end

  def last_week
    @instruments = Instrument.active.traded_on(current_market).includes(:info)
    @dates = MarketCalendar.open_days(15.days.ago, currency: current_market).last(6)
    Current.preload_day_candles_with @instruments.to_a, @dates
    InstrumentCache.set @instruments

    @results = @dates.each_with_object({}) do |date, hash|
      candles = @instruments.map { _1.day_candles!.find_date(date) }.compact
      gainers = candles.compact.sort_by(&:rel_close_change).last(15).reverse
      losers  = candles.compact.sort_by(&:rel_close_change).first(15)
      volume_gainers = candles.sort_by(&:volume_to_average).last(15).reverse.select { _1.volume_to_average > 2 }
      user_tickers = (gainers + losers).map(&:ticker).to_set

      volume_gainers.reject! { _1.ticker.in? user_tickers }

      result = OpenStruct.new(
        gainers: gainers, losers: losers, volume_gainers: volume_gainers
      )

      hash[date] = result
    end
  end

  def last_week_spikes
    @instruments = Instrument.active.traded_on(current_market).includes(:info)
    @dates = MarketCalendar.open_days(15.days.ago, currency: current_market).last(6) - [Current.date]
    Current.preload_day_candles_with @instruments.to_a, @dates
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
    @instruments = Instrument.active.traded_on(current_market).includes(:info, :indicators, :aggregate)
    @dates = [Current.date]
    Current.preload_day_candles_with @instruments.to_a, @dates
    Current.preload_prices_for @instruments.to_a
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

  private

  def price_ratio(current, base)
    current / base - 1 rescue 0
  end

  def load_instruments
  end
end
