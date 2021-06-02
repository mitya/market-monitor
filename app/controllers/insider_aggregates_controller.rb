class InsiderAggregatesController < ApplicationController
  def index
    params[:per_page] ||= '200'

    @aggregates = InsiderAggregate.all
    @aggregates = @aggregates.order(m3_buys_total: :desc)
    @aggregates = @aggregates.includes(:instrument => :info)
    @aggregates = @aggregates.page(params[:page]).per(params[:per_page])

    Current.preload_prices_for @aggregates.map &:instrument
  end
end
