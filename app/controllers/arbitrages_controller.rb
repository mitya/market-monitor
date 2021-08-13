class ArbitragesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    Setting.save 'sync_exchanges', %w[XFRA TG US]
    Setting.save 'sync_books', %w[CLF DK M MAC]

    @arbitrages = ArbitrageCase.includes(:instrument => [:info, :orderbook]).where(date: Current.date).where('updated_at > ?', 1.minute.ago).order('long desc, percent desc')
    @arbitrages = @arbitrages.reject { |arb| !arb.instrument.orderbook || arb.instrument.orderbook&.not_available? || arb.instrument.orderbook.updated_at < 1.minute.ago }
    @arbitrage_groups = @arbitrages.group_by &:ticker
    Current.preload_day_candles_for @arbitrages.map(&:instrument).to_a

    @long_arbitrage_groups, @short_arbitrage_groups = @arbitrage_groups.partition { |ticker, group| group.any? &:long? }

    on_xhr_render :arbitrages
  end

  def limit_order
    response = Tinkoff.limit_order(params[:ticker], params[:operation], params[:lots], params[:price])
    render json: response
  end

  def cancel_order
    response = Tinkoff.cancel_order(params[:id])
    render json: response
  end
end
