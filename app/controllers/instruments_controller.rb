class InstrumentsController < ApplicationController
  def root
    redirect_to instruments_path
  end

  def index
    @sets = InstrumentSet.all
    @set = InstrumentSet.new(params[:set]) if params[:set].present?

    @instruments = @set ? @set.instruments : Instrument.tinkoff
    @instruments = @instruments.abc.includes(:info, :price_target)
    @instruments = @instruments.where(info: { industry: params[:industry] }) if params[:industry].present?
    @instruments = @instruments.where(info: { sector: params[:sector] }) if params[:sector].present?
    @instruments = @instruments.page(params[:page]).per(200)

    Current.preload_day_candles_for @instruments
    Current.preload_prices_for @instruments
  end
end
