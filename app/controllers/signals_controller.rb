class SignalsController < ApplicationController
  def index
    params[:dates] ||= [Current.yesterday.to_s]
    params[:per_page] ||= '400'
    params[:interval] ||= 'day'
    params[:direction] ||= 'up'
    params[:signal] ||= 'breakout'

    @signals = PriceSignal.all
    @signals = @signals.joins(:instrument)
    @signals = @signals.includes(:instrument => [:info, :price_target])

    @signals = @signals.for_interval params[:interval]                              if params[:interval].present?
    @signals = @signals.where date: params[:dates]                                  if params[:dates].any?
    @signals = @signals.where kind: params[:signal]                                 if params[:signal].present?
    @signals = @signals.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @signals = @signals.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @signals = @signals.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @signals = @signals.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?
    @signals = @signals.where direction: params[:direction]                         if params[:direction].present?

    @signals = @signals.page(params[:page]).per(params[:per_page])

    @signals = @signals.order(:ticker, :date => :desc) if params[:interval] == 'day'
    @signals = @signals.order('date, time desc') if params[:interval] != 'day'

    Current.preload_prices_for @signals.map(&:instrument)
    Current.preload_day_candles_for @signals.map(&:instrument)
  end
end
