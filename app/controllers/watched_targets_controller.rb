class WatchedTargetsController < ApplicationController
  def index
    targets = WatchedTarget.today.order(:ticker, :expected_price)
    targets = targets.select { _1.instrument.currency == current_currency }

    @bullish_targets, @bearish_targets = targets.partition &:bullish?
    @bearish_targets = @bearish_targets.sort_by { [_1.ticker, -_1.target_price] }

    PriceCache.preload
  end

  def create
    keep = params[:text].slice!('++').present?
    ticker, target = params[:text].upcase.split
    expected_price, expected_ma = target.include?('A') ? [nil, target.delete('A')] : [target, nil]

    return render json: { ok: false } unless ticker && (expected_price || expected_ma)
    return render json: { ok: false } if WatchedTarget.exists? ticker: ticker, expected_price: expected_price, expected_ma: expected_ma

    watch = WatchedTarget.create ticker: ticker, expected_price: expected_price, expected_ma: expected_ma, keep: keep
    render json: {
      ok: true,
      html: render_to_string(partial: 'row', locals: { target: watch }),
      list: "#{watch.bullish?? 'bullish' : 'bearish'}-#{watch.swing?? 'swing' : 'intraday'}"
    }
  end

  def destroy
    watch = WatchedTarget.find(params[:id])
    watch.destroy
    render json: { ok: true }
  end
end
