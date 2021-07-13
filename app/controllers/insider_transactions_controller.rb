class InsiderTransactionsController < ApplicationController
  def index
    params[:per_page] ||= '200'
    params[:insider] = nil if params[:tickers] && params[:tickers].split.many?
    min_amount = params[:min_amount].to_i.nonzero?

    # params[:tickers] ||= Instrument.joins(:info).where('stats.marketcap < ?', 600_000_000).pluck(:ticker).join(' ')

    @transactions = InsiderTransaction.with_price
    @transactions = @transactions.joins(:instrument)
    @transactions = @transactions.for_tickers params[:tickers].split if params[:tickers].present?
    @transactions = @transactions.where ticker: InstrumentSet.get(params[:set]).symbols if params[:set].present? && params[:tickers].blank?

    @transactions = @transactions.for_insider params[:insider]       if params[:insider].present?
    @transactions = @transactions.for_direction params[:direction]   if params[:direction].present?
    @transactions = @transactions.market_only                        if params[:market_only] == '1'
    @transactions = @transactions.where('cost > ?', min_amount)      if min_amount
    @transactions = @transactions.where("? = any(instruments.flags)", params[:availability]) if params[:availability].present?
    @transactions = @transactions.order(date: :desc, ticker: :asc)
    @transactions = @transactions.includes(:instrument => [:info, :portfolio_item])
    @transactions = @transactions.page(params[:page]).per(params[:per_page])

    Current.preload_prices_for @transactions.map(&:instrument)
    Current.preload_day_candles_with @transactions.map(&:instrument).uniq, nil
  end
end
