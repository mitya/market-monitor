class NewsController < ApplicationController
  def index
    params[:per_page] ||= '400'

    @news = News.order(datetime: :desc, ticker: :asc)
    @news = @news.joins(:instrument)
    @news = @news.includes(:instrument => [:info])

    @news = @news.where instruments: { currency: params[:currency] }          if params[:currency].present?
    @news = @news.for_tickers params[:tickers].to_s.split.map(&:upcase)       if params[:tickers].present?
    @news = @news.where ticker: InstrumentSet.get(params[:set]).symbols       if params[:set].present? && params[:tickers].blank?
    @news = @news.where ["? = any(instruments.flags)", params[:availability]] if params[:availability].present?
    @news = @news.page(params[:page]).per(params[:per_page])

    PriceCache.preload @news
    CandleCache.preload @news
  end
end
