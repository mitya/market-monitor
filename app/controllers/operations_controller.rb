class OperationsController < ApplicationController
  def index
    @operations = Operation.market.passed.today.order(datetime: :desc).includes(:instrument)
    on_xhr_render :operations
  end
end
