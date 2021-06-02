class PublicSignalsController < ApplicationController
  def index
    params[:per_page] ||= '100'
    params[:source] ||= 'Non-SA'

    @signals = PublicSignal.all
    @signals = @signals.joins(:instrument)
    @signals = @signals.includes(:instrument => [:info, :price_target])

    if params[:source] == 'Non-SA'
      @signals = @signals.where.not(source: "SA")
    elsif params[:source].present?
      @signals = @signals.where(source: params[:source])
    end

    @signals = @signals.page(params[:page]).per(params[:per_page])
    @signals = @signals.order('date desc')

    Current.preload_prices_for @signals.map(&:instrument)
    Current.preload_day_candles_for @signals.map(&:instrument)
  end
end
