class TradingController < ApplicationController
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
  end
  
  def candles
    tickers = %w[CLF DK OSUR RIG VEON ZIM]
    candles = tickers.inject({}) do |map, ticker| 
      map[ticker] = Candle::M3.where(ticker: ticker).includes(:instrument).last(1000).map { |c| [c.datetime.to_i, c.open.to_f, c.high.to_f, c.low.to_f, c.close.to_f, c.volume] }
      map 
    end
    render json: candles
  end
end
