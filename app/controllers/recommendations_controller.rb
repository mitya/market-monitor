class RecommendationsController < ApplicationController
  def index
    @ticker = params[:ticker].upcase if params[:ticker].present?
    @recommendations = Recommendation.all
    @recommendations = @recommendations.for_ticker @ticker if @ticker
    @recommendations = @recommendations.current if params[:current] == '1'
    @recommendations = @recommendations.order(ticker: :asc, starts_on: :desc)
    @recommendations = @recommendations.includes(:instrument => :price_target)
    @recommendations = @recommendations.page(params[:page]).per(200)

    @instruments = @recommendations.map(&:instrument).uniq
    Current.preload_day_candles_for @instruments
    Current.preload_prices_for @instruments
  end
end
