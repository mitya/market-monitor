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
  
  def intraday    
    @chart_settings = Setting.chart_settings
    @chart_settings['columns'] ||= 2
    @chart_settings['rows'] ||= 2
    @chart_settings['period'] ||= '3min'
    @chart_settings['tickers'] ||= []

    @synced_tickers = Setting.sync_tickers.join(' ')

    @chart_tickers = Setting.chart_tickers

    @list_shown = params[:list] == '1'

    @intraday_levels = InstrumentAnnotation.with_intraday_levels
    @intraday_levels_text = @intraday_levels.map(&:intraday_levels_line).join("\n")

    @ticker_sets = TickerSet.order(:key)
    @ticker_sets_text = @ticker_sets.map(&:as_line).join("\n")
        
    @list_ticker_set = InstrumentSet.new('Current', :static, items: @chart_tickers)
  end
  
  def candles
    is_update = params[:limit] == '1'
    is_single = params[:single] == '1'
    period = Setting.chart_period
    repo = Candle.interval_class_for(period)
    tickers = Setting.chart_tickers
    tickers = tickers.first(1) if is_single
    
    instruments = Instrument.for_tickers(tickers).includes(:indicators, :annotation)
    instruments = tickers.map { |ticker| instruments.find { _1.ticker == ticker.upcase } }.compact
    openings = Candle::M3.today.openings.for(instruments).index_by(&:ticker)
    
    candles = instruments.inject({}) do |map, instrument|      
      ticker = instrument.ticker
      candles = repo.for(instrument).includes(:instrument).order(:date, :time).last(params[:limit] || is_single ? 777 : 500)
      map[ticker] = { ticker: ticker }
      map[ticker][:candles] = candles.map { |c| [c.datetime_as_msk.to_i, c.open.to_f, c.high.to_f, c.low.to_f, c.close.to_f, c.volume] }
      unless is_update
        map[ticker][:opens] = candles.select(&:opening?).map { _1.datetime_as_msk.to_i } unless period == 'day'
        map[ticker][:levels] = { } 
        unless period == 'day'
          map[ticker][:levels].merge!(
            MA20:  instrument.indicators.ema_20.to_f,
            MA50:  instrument.indicators.ema_50.to_f,
            MA200: instrument.indicators.ema_200.to_f,            
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
    Setting.save 'sync_tickers', params[:synced_tickers].split.map(&:upcase).sort
    Setting.save 'sync_ticker_sets', params[:sync_ticker_sets]
    Setting.merge 'chart_settings', { 
      tickers: params[:chart_tickers].split.map(&:upcase), 
      columns: params[:columns].to_i.nonzero?,
      rows: params[:rows].to_i.nonzero?,
      period: Candle.normalize_interval(params[:period]),
      time_shown: params[:time_shown],
      price_shown: params[:price_shown],
      wheel_scaling: params[:wheel_scaling],
      bar_spacing: params[:bar_spacing],
      level_labels: params[:level_labels],
      levels_shown: params[:levels_shown],
    }

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
end
