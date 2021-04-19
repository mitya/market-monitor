class SignalsController < ApplicationController
  def index
    @signals = PriceSignal.all.order(:ticker)
    @signals = @signals.includes(:instrument)
    @signals = @signals.page(params[:page]).per(200)
  end
end
