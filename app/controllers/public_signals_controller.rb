class PublicSignalsController < ApplicationController
  def index
    params[:per_page] ||= '100'

    @signals = PublicSignal.all
    @signals = @signals.joins(:instrument)
    @signals = @signals.includes(:instrument => [:info, :price_target])
    @signals = @signals.page(params[:page]).per(params[:per_page])
    @signals = @signals.order('date desc')

    Current.preload_prices_for @signals.map(&:instrument)
    Current.preload_day_candles_for @signals.map(&:instrument)
  end
end
