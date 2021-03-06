class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :preload_cache


  private

  def on_xhr_render(partial_name)
    if request.xhr?
      render partial: partial_name.to_s
    else
      render
    end
  end

  def current_market = params[:market] || 'rub'
  def current_market_symbol = current_market.to_sym
  def current_calendar = MarketCalendar.for(current_market)
  def current_currency = current_market.upcase
  def ru_market? = current_market == 'rub'
  def us_market? = current_market == 'usd'

  helper_method :current_market, :current_currency, :ru_market?, :us_market?

  def preload_cache
    # PermaCache.load_instruments
    # PermaCache.load_infos
    # CandleCache.preload
  end
end
