class TickerSetItemsController < ApplicationController
  def toggle
    set = TickerSet.find_by_key(params[:ticker_set_id])
    included = set.toggle_ticker params[:id]
    render json: { ticker: params[:id], ok: true, included: included }
  end
end
