class ArbitragesController < ApplicationController
  def index
    Setting.save 'sync_exchanges', %w[XFRA TG US]
    Setting.save 'sync_books', %w[CLF DK M MAC]

    @arbitrages = ArbitrageCase.includes(:instrument => [:info, :orderbook]).where(date: Current.date).where('updated_at > ?', 1.minute.ago).order('long desc, percent desc')
    @arbitrages = @arbitrages.reject { |arb| !arb.instrument.orderbook || arb.instrument.orderbook&.not_available? || arb.instrument.orderbook.updated_at < 1.minute.ago }
    Current.preload_day_candles_for @arbitrages.map(&:instrument).to_a
  end
end
