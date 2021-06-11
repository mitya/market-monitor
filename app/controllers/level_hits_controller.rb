class LevelHitsController < ApplicationController
  def index
    params[:dates] ||= [Current.yesterday.to_s]
    params[:per_page] ||= '400'
    params[:interval] ||= 'day'
    params[:important] ||= '1'

    @hits = PriceLevelHit.all
    @hits = @hits.joins(:instrument, :level)
    @hits = @hits.includes(:instrument => [:info, :price_target, :aggregate])

    @hits = @hits.where date: params[:dates]                                  if params[:dates].any?
    @hits = @hits.where kind: params[:kind]                                   if params[:kind].present?
    @hits = @hits.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @hits = @hits.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @hits = @hits.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @hits = @hits.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?
    @hits = @hits.exact                                                       if params[:exact] == '1'
    @hits = @hits.important                                                   if params[:important] == '1'
    @hits = @hits.where level: { manual: true }                               if params[:manual] == '1'

    @hits = @hits.page(params[:page]).per(params[:per_page])
    @hits = @hits.order('date desc, ticker')

    Current.preload_prices_for @hits.map(&:instrument)
    Current.preload_day_candles_for @hits.map(&:instrument)
  end
end
