class TradingController < ApplicationController
  skip_before_action :verify_authenticity_token

  def dashboard
    @is_morning = !Current.us_market_open?
    @market_open_time_in_mins = @is_morning ? 0 * 60 : 9 * 60 + 30
    @market_open_time_in_mins_utc = @market_open_time_in_mins + 4 * 60
    @market_open_time_in_hhmm_utc = helpers.format_as_minutes_since @market_open_time_in_mins_utc, 0
    puts @market_open_time_in_hhmm_utc

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

    @ticker_sets = TickerSet.order(:key)
    @ticker_sets_text = @ticker_sets.map(&:as_line).join("\n")

    @list_ticker_set = InstrumentSet.new('Current', :static, items: @chart_tickers)

    @list_shown = params[:list] == '1'
    @chart_columns = @list_shown ? 1 : @chart_settings['columns']
    @chart_rows = @list_shown ? 1 : @chart_settings['rows']
  end

  def candles
    is_update = params[:limit] == '1'
    is_single = params[:single] == '1'
    period = Setting.chart_period
    repo = Candle.interval_class_for(period)
    tickers = Setting.chart_tickers.first(12)
    tickers = tickers.first(1) if is_single

    instruments = Instrument.for_tickers(tickers).includes(:indicators, :annotation)
    instruments = tickers.map { |ticker| instruments.find { _1.ticker == ticker.upcase } }.compact
    openings = Candle::M3.today.openings.for(instruments).index_by(&:ticker)

    candles = instruments.inject({}) do |map, instrument|
      ticker = instrument.ticker
      candles = repo.for(instrument).includes(:instrument).order(:date, :time).last(params[:limit] || (is_single ? 777 : 500))
      map[ticker] = { ticker: ticker }
      map[ticker][:candles] = candles.map { |c| [c.datetime_as_msk.to_i, c.open.to_f, c.high.to_f, c.low.to_f, c.close.to_f, c.volume] }
      unless is_update
        map[ticker][:opens] = candles.select(&:opening?).map { _1.datetime_as_msk.to_i } unless period == 'day'
        map[ticker][:levels] = { }
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

    @instruments = Instrument.rub.active.includes(:info)
    @all_candles = Candle::M1.for(@instruments).today

    InstrumentCache.set @instruments
    Price.sync_with_last_candles @instruments

    @candles = {}

    [1, 5, 15, 60].each do |duration|
      last_candle_ids = @all_candles.where('time < ?', (now - duration.minutes).strftime('%H:%M')).group(:ticker).pluck('max(id)')
      @candles[duration] = @all_candles.where(id: last_candle_ids).index_by(&:ticker)
    end

    Current.preload_prices_for @instruments.to_a
    Current.preload_day_candles_with @instruments.to_a, [Current.today, Current.yesterday]

    @rows = @instruments.map do |inst|
      OpenStruct.new(
        instrument:              inst,
        last:                    inst.last,
        last_to_yesterday_open:  price_ratio(inst.last, inst.yesterday_open),
        last_to_yesterday_close: price_ratio(inst.last, inst.yesterday_close),
        last_to_today_open:      price_ratio(inst.last, inst.today_open),
        last_to_60m_ago:         price_ratio(inst.last, @candles[60][inst.ticker]&.close),
        last_to_15m_ago:         price_ratio(inst.last, @candles[15][inst.ticker]&.close),
        last_to_05m_ago:         price_ratio(inst.last, @candles[ 5][inst.ticker]&.close),
        last_to_01m_ago:         price_ratio(inst.last, @candles[ 1][inst.ticker]&.close),
        yesterday_volume:        inst.d1_ago&.volume_in_money,
        volume:                  inst.today&.volume_in_money,
        rel_volume:              inst.info.relative_volume * 100,
        volatility:              inst.today&.volatility.to_f * 100,
        d5_volume:               inst.info.avg_d5_money_volume,
      )
    end

    ignored_tickers = %w[DASB GRNT MRKC MRKS MRKU MRKV MRKZ MSRS UPRO VRSB RENI GTRK TORS TGKBP MGTSP PMSBP MRKY].to_set
    watched_tickers = %w[AFKS AGRO AMEZ ENPG ETLN FESH FIVE GAZP GLTR GMKN KMAZ LNTA MAGN MTLR MTLRP MVID NMTP OZON POGR POLY RASP RNFT ROSN RUAL SGZH SMLT TCSG VKCO].to_set
    @ignored, @rows           = @rows.partition { ignored_tickers.include? _1.instrument.ticker }
    # @watched, @rows           = @rows.partition { watched_tickers.include? _1.instrument.ticker }
    # @liquid, @rows            = @rows.partition { _1.instrument.liquid? }
    @very_illiquid, @rows = @rows.partition { _1.instrument.very_illiquid? }
    @groups = [@watched, @liquid, @illiquid, @very_illiquid]
    @groups = [@rows, @very_illiquid]

    sort_field = params[:sort] || :last_to_yesterday_close
    @groups = @groups.map { |rows| rows.sort_by { _1.send(sort_field) || 0 }.reverse }

    @fields = [
      :icon,
      :ticker,
      :last,
      :last_to_yesterday_close,
      # :last_to_today_open,
      :last_to_60m_ago,
      :last_to_15m_ago,
      :last_to_05m_ago,
      # :yesterday_volume,
      # :volume,
      :rel_volume,
      # :d5_volume,
      :volatility,
    ]
  end

  private

  def price_ratio(current, base)
    current / base - 1 rescue 0
  end
end
