class InsiderTransactionsController < ApplicationController
  def index
    params[:per_page] ||= '200'
    params[:insider] = nil if params[:tickers] && params[:tickers].split.many?

    @transactions = InsiderTransaction.with_price
    @transactions = @transactions.for_tickers params[:tickers].split if params[:tickers].present?
    @transactions = @transactions.for_insider params[:insider]       if params[:insider].present?
    @transactions = @transactions.for_direction params[:direction]   if params[:direction].present?
    @transactions = @transactions.market_only                        if params[:market_only] == '1'
    @transactions = @transactions.order(date: :desc, ticker: :asc)
    @transactions = @transactions.includes(:instrument)
    @transactions = @transactions.page(params[:page]).per(params[:per_page])

    Current.preload_prices_for @transactions.map &:instrument
  end
end
