class ChartsController < ApplicationController
  def show
    @chart_settings = Setting.chart_settings
    @chart_settings['columns'] ||= 2
    @chart_settings['rows'] ||= 2
    @chart_settings['period'] ||= '3min'
    @chart_settings['tickers'] ||= []

    @synced_tickers = Setting.sync_tickers.join(' ')
    @sync_ticker_sets = Setting.sync_ticker_sets


    @intraday_levels = InstrumentAnnotation.with_intraday_levels
    @intraday_levels_text = @intraday_levels.map(&:intraday_levels_line).join("\n")

    @custom_ticker_sets = TickerSet.stored
    @custom_ticker_sets_text = @custom_ticker_sets.map(&:as_line).join("\n")
    @predefined_ticker_sets = TickerSet.from_instrument_sets

    @chart_tickers = Setting.chart_tickers.sort
    @chart_tickers_line = @chart_tickers.join(' ').upcase
    @current_ticker_set = (@custom_ticker_sets + @predefined_ticker_sets).detect { _1.tickers == @chart_tickers }

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

    instruments = Instrument.for_tickers(tickers).includes(:annotation)
    instruments = tickers.map { |ticker| instruments.find { _1.ticker == ticker.upcase } }.compact
    openings = Candle::M1.today.openings.for(instruments).index_by(&:ticker)

    candles = instruments.inject({}) do |map, instrument|
      ticker = instrument.ticker
      candles = repo.for(instrument).order(:date, :time).since(since_date).last(params[:limit] || (is_single ? 777 : 500))
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
            map[ticker][:averages][period] = {}
            map[ticker][:averages][period][:data] = indicators.map { [_1.charting_timestamp, _1.send("ema_#{period}")] }.reject { _1.second == nil }

            if last_value = map.dig(ticker, :averages, period, :data, -1, -1)
              gain = instrument.gain_since(:last, last_value)
              map[ticker][:averages][period][:distance] = "#{gain > 0 ? '+' : '–'}#{(gain.abs * 100).to_i}%"
            end
          end

          extremums = ExtremumFinder.find_for(candles)
          extremums.each do |extremum|
            gain = instrument.gain_since(:last, extremum)
            next if gain.abs < 0.03
            gain_pct = (gain * 100).to_i
            map[ticker][:levels]["#{gain_pct > 0 ? '+' : '–'}#{gain_pct.abs}%"] = extremum
          end

          # rs_ref = Instrument['IVZ'].day_candles.asc.index_by &:date
          # map[ticker][:rs] = candles.map { [_1.charting_timestamp, ((_1.close / rs_ref[_1.date]&.close).round(5) rescue nil) ] }.reject { _1.second == nil }
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

  def update
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
end
