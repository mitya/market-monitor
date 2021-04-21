class SignalsController < ApplicationController
  def index
    params[:dates] ||= [Current.yesterday.to_s]

    @signals = PriceSignal.all.order(:ticker, :date => :desc)
    @signals = @signals.joins(:instrument)
    @signals = @signals.includes(:instrument => :info)

    @signals = @signals.where date: params[:dates]                                  if params[:dates].any?
    @signals = @signals.where kind: params[:signal]                                 if params[:signal].present?
    @signals = @signals.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @signals = @signals.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @signals = @signals.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @signals = @signals.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?

    @signals = @signals.page(params[:page]).per(200)

    Current.preload_prices_for @signals.map(&:instrument)
    Current.preload_day_candles_for @signals.map(&:instrument)
  end
end
