class RecommendationsController < ApplicationController
  def index
    params[:per_page] ||= '200'

    @recommendations = Recommendation.all
    @recommendations = @recommendations.where ticker: InstrumentSet.get(params[:set])&.tickers if params[:set].present?
    @recommendations = @recommendations.where instruments: { currency: params[:currency] }     if params[:currency].present?
    @recommendations = @recommendations.for_tickers params[:tickers].split                     if params[:tickers].present?
    @recommendations = @recommendations.current                                                if params[:outdated] != '1'
    @recommendations = @recommendations.order(ticker: :asc, starts_on: :desc)
    @recommendations = @recommendations.includes(:instrument => :price_target)
    @recommendations = @recommendations.page(params[:page]).per(params[:per_page])

    @instruments = @recommendations.map(&:instrument).uniq
    Current.preload_day_candles_for @instruments
    Current.preload_prices_for @instruments
  end
end
