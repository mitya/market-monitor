class TickerSetItemsController < ApplicationController
  def toggle
    set = TickerSet.find_by_key(params[:ticker_set_id])
    included = set.toggle_ticker params[:id]
    render json: { ticker: params[:id], ok: true, included: included }
  end

  def create
    set = TickerSet.find_by_key(params[:ticker_set_id])
    tickers = params[:text].to_s.split.map(&:upcase)
    set.add tickers
    PermaCache.reset_current_instruments if set.key == 'current'
    render json: { ok: true }
  end
end
