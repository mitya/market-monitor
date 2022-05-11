class ApplicationController < ActionController::Base
  private

  def on_xhr_render(partial_name)
    if request.xhr?
      render partial: partial_name.to_s
    else
      render
    end
  end

  def current_market
    params[:market] || 'rub'
  end

  def current_calendar
    MarketCalendar.for(current_market)
  end
end
