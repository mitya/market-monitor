class SignalStrategiesController < ApplicationController
  def index
    params[:per_page] ||= '500'

    @results = PriceSignalStrategy.all
    @results = @results.where signal: params[:signal]            if params[:signal].present?
    @results = @results.where direction: params[:direction]      if params[:direction].present?
    @results = @results.page(params[:page]).per(params[:per_page])
    # @results = @results.order(:change)

    @strategies = @results
  end
end
