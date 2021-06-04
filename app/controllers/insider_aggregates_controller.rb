class InsiderAggregatesController < ApplicationController
  def index
    params[:per_page] ||= '200'

    @period = 6

    @aggregates = InsiderAggregate.all
    @aggregates = @aggregates.order("m#{@period}_buys_total" => :desc)
    @aggregates = @aggregates.includes(:instrument => :info)

    @aggregates = @aggregates.where ticker: params[:tickers].to_s.split.map(&:upcase)     if params[:tickers].present?
    @aggregates = @aggregates.page(params[:page]).per(params[:per_page])

    Current.preload_prices_for @aggregates.map &:instrument
  end
end
