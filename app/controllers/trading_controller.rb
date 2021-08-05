class TradingController < ApplicationController
  def dashboard
    @instruments = InstrumentSet[:trading].scope.includes(:info, :aggregate)
    @candles = Candle::M5.where(ticker: @instruments, date: Current.date).order(:time)
    @candles = @candles.select { |candle| candle.time_before_type_cast >= '13:30' }
    @candles_by_ticker = @candles.group_by(&:ticker)

    @opens                  = @candles_by_ticker.transform_values { |candles| candles.first }
    @lasts                  = @candles_by_ticker.transform_values { |candles| candles.last }
    @highs                  = @candles_by_ticker.transform_values { |candles| candles.max_by(&:high) }
    @lows                   = @candles_by_ticker.transform_values { |candles| candles.min_by(&:low) }
    @candles_by_ticker_time = @candles_by_ticker.transform_values { |candles| candles.index_by(&:time_before_type_cast) }
    @minutes = (0..385).step(5).to_a

    @candles_by_ticker = @candles_by_ticker.transform_values do |ticker, candles|
      by_time = @candles_by_ticker_time[ticker]
      @minutes.map { |minute| by_time["#{helpers.format_as_minutes_since 13 * 60 + 30, minute}:00"] || nil } if by_time
    end

    Current.preload_day_candles_with @instruments.to_a, []
    Current.preload_prices_for @instruments.to_a
  end

  def activities
  end
end
