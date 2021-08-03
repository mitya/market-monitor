class TradingController < ApplicationController
  def dashboard
    @instruments = InstrumentSet[:trading].scope.includes(:info, :aggregate)
    @candles = Candle::M5.where(ticker: @instruments, date: Current.date).order(:time)
    @candles = @candles.select { |candle| candle.time_before_type_cast >= '13:30' }
    @candles = @candles.group_by(&:ticker)

    @opens = @candles.map { |ticker, candles| [ticker, candles.first.open] }.to_h
    @candles_by_ticker_time = @candles.map { |ticker, candles| [ticker, candles.index_by(&:time_before_type_cast)] }.to_h

    @minutes = (0..385).step(5).to_a

    Current.preload_day_candles_with @instruments.to_a, []
    Current.preload_prices_for @instruments.to_a
  end
end
