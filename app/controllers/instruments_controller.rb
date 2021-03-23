class InstrumentsController < ApplicationController
  def root
    redirect_to instruments_path
  end

  def index
    @instruments = Instrument.all
    @instruments = @instruments.abc.includes(:info, :price_target)
    @instruments = @instruments.where(info: { industry: params[:industry] })       if params[:industry].present?
    @instruments = @instruments.where(info: { sector: params[:sector] })           if params[:sector].present?
    @instruments = @instruments.where(info: { sector_code: params[:sector_code] }) if params[:sector_code].present?
    @instruments = @instruments.where(currency: params[:currency])                 if params[:currency].present?
    @instruments = @instruments.with_flag(params[:availability])                   if params[:availability].present?
    @instruments = @instruments.in_set(params[:set].presence)                      if params[:set].present? && params[:tickers].blank?
    @instruments = @instruments.for_tickers(params[:tickers].to_s.split)           if params[:tickers].present?
    @instruments = @instruments.page(params[:page]).per(200)

    extra_dates = []
    extra_dates += Current.last_2_weeks if params[:chart_volatility]

    Current.preload_day_candles_for @instruments, extra_dates: extra_dates
    Current.preload_prices_for @instruments
  end
end
