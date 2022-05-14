class LevelHitsController < ApplicationController
  def index
    params[:dates] ||= [Current.yesterday.to_s]
    params[:per_page] ||= '400'
    params[:interval] ||= 'day'

    tickers = params[:tickers].to_s.split.map(&:upcase) if params[:tickers].present?
    if tickers&.one?
      params[:dates] = nil
      params[:per_page] = 100
    end

    @hits = PriceLevelHit.all
    @hits = @hits.left_joins(:instrument, :level)
    @hits = @hits.includes(:instrument => [:info, :price_target, :aggregate])

    @hits = @hits.where date: params[:dates]                                  if params[:dates].present?
    @hits = @hits.where kind: params[:kind]                                   if params[:kind].present?
    @hits = @hits.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @hits = @hits.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @hits = @hits.where ticker: tickers                                       if tickers.present?
    @hits = @hits.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?
    @hits = @hits.where level: { manual: true }                               if params[:manual] == '1'
    @hits = @hits.where source: params[:source]                               if params[:source].present?
    @hits = @hits.exact                                                       if params[:exact] == '1'
    @hits = @hits.important                                                   if params[:important] == '1'
    @hits = @hits.where positive: true                                        if params[:direction] == 'up'
    @hits = @hits.where positive: false                                       if params[:direction] == 'down'

    @hits = @hits.where 'days_since_last > ?', params[:days_since_last]       if params[:days_since_last].present?
    @hits = @hits.where 'rel_vol > ?', params[:rvol].to_f / 100               if params[:rvol].present?

    @hits = @hits.page(params[:page]).per(params[:per_page])
    @hits = @hits.order('date desc, ticker')

    PriceCache.preload @hits
    CandleCache.preload @hits
  end
end
