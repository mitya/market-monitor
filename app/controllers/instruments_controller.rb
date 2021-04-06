class InstrumentsController < ApplicationController
  def root
    redirect_to instruments_path
  end

  def index
    @instruments = Instrument.all
    @instruments = @instruments.joins(:aggregate)
    @instruments = @instruments.includes(:info, :price_target, :portfolio_item, :aggregate)
    @instruments = @instruments.where(info: { industry: params[:industry] })       if params[:industry].present?
    @instruments = @instruments.where(info: { sector: params[:sector] })           if params[:sector].present?
    @instruments = @instruments.where(info: { sector_code: params[:sector_code] }) if params[:sector_code].present?
    @instruments = @instruments.where(currency: params[:currency])                 if params[:currency].present?
    @instruments = @instruments.with_flag(params[:availability])                   if params[:availability].present?
    @instruments = @instruments.in_set(params[:set].presence)                      if params[:set].present? && params[:tickers].blank?
    @instruments = @instruments.for_tickers(params[:tickers].to_s.split)           if params[:tickers].present?
    @instruments = @instruments.order("#{params[:order].presence || 'ticker'} nulls last")
    @instruments = @instruments.page(params[:page]).per(200)

    @portfolio = PortfolioItem.all

    Current.preload_day_candles_with @instruments, params[:chart_volatility] ? Current.last_2_weeks : []
    Current.preload_prices_for @instruments
  end
end
