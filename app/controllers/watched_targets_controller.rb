class WatchedTargetsController < ApplicationController
  def index
    targets = WatchedTarget.today.order(:ticker, :expected_price)
    targets = targets.select { _1.instrument.currency == current_currency }

    @bullish_targets, @bearish_targets = targets.partition &:bullish?
    @bearish_targets = @bearish_targets.sort_by { [_1.ticker, -_1.expected_price] }

    PriceCache.preload
  end

  def create
    ticker, expected_price = params[:text].split
    return render status: 400, json: { ok: false } unless ticker && expected_price

    target = WatchedTarget.create ticker: ticker.upcase, expected_price: expected_price
    render json: {
      ok: true,
      html: render_to_string(partial: 'row', locals: { target: target }),
      list: target.bullish?? 'bullish' : 'bearish'
    }
  end

  def destroy
    target = WatchedTarget.find(params[:id])
    target.destroy
    render json: { ok: true }
  end
end
