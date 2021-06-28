class SignalStrategiesController < ApplicationController
  def index
    params[:per_page] ||= '500'
    params[:period] = '' if params[:period] == 'All'
    period = params[:period].split('..').map(&:to_date).to_inclusive_range if params[:period].present?


    @results = PriceSignalStrategy.all
    @results = @results.where signal: params[:signal]            if params[:signal].present?
    @results = @results.where direction: params[:direction]      if params[:direction].present?
    @results = @results.where period: period
    @results = @results.where.not prev_1w_low: nil if params[:prev_1w_low_set]
    @results = @results.where.not prev_2w_low: nil if params[:prev_2w_low_set]
    @results = @results.page(params[:page]).per(params[:per_page])
    @results = @results.order('period nulls first, change nulls first, prev_1w_low nulls first, prev_2w_low nulls first')

    @strategies = @results
  end
end
