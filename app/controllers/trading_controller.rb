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
    @charted_tickers = Setting.charted_tickers.join(' ')
    @synced_tickers = Setting.synced_tickers.join(' ')
    @period = Setting.charted_period || '3min'
    @intraday_levels = InstrumentAnnotation.with_intraday_levels
    @intraday_levels_text = @intraday_levels.map(&:intraday_levels_line).join("\n")
    @ticker_sets = TickerSet.order(:key)
    @ticker_sets_text = @ticker_sets.map(&:as_line).join("\n")
  end
  
  def candles
    is_update = params[:limit] == '1'
    repo = Candle.interval_class_for(Setting.charted_period)
    instruments = Instrument.for_tickers(Setting.charted_tickers).includes(:indicators, :annotation)
    
    candles = instruments.inject({}) do |map, instrument|      
      ticker = instrument.ticker
      candles = repo.where(ticker: instrument).includes(:instrument).order(:date, :time).last(params[:limit] || 500)
      map[ticker] = { ticker: ticker }
      map[ticker][:candles] = candles.map { |c| [c.datetime.to_i, c.open.to_f, c.high.to_f, c.low.to_f, c.close.to_f, c.volume] }
      unless is_update
        map[ticker][:opens] = candles.select(&:opening?).map { _1.datetime.to_i }
        map[ticker][:levels] = {
          MA20:  instrument.indicators.ema_20.to_f,
          MA50:  instrument.indicators.ema_50.to_f,
          MA200: instrument.indicators.ema_200.to_f,
          open:  instrument.today&.open,
          close:  instrument.yesterday&.close,
          intraday: instrument.annotation&.intraday_levels,
        }
      end
      map 
    end
    render json: candles
  end
  
  def update_chart_settings
    Setting.save 'charted_tickers', params[:charted_tickers].split.map(&:upcase)
    Setting.save 'synced_tickers', params[:synced_tickers].split.map(&:upcase).sort
    Setting.save 'charted_period', Candle.normalize_interval(params[:period])
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
