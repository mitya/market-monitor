class InstrumentsController < ApplicationController
  def root
    redirect_to instruments_path
  end

  def index
    @sets = InstrumentSet.all
    @set = InstrumentSet.new(params[:set]) if params[:set].present?
    @instruments = @set ? @set.instruments.abc : Instrument.tinkoff.abc.limit(50)
    Current.preload_day_candles_for @instruments
    Current.preload_prices_for @instruments
  end
end
