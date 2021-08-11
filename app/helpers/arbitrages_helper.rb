module ArbitragesHelper

  ARB_EXCHANGE_CODES = { N: 'NASDAQ', F: 'XFRA', T: 'Tradegate', U: 'US'}
  ARB_EXCHANGE_FLAGS = { N: 'usa', F: 'deu', T: 'deu', U: 'usa'}

  def arb_exchange_code(code)
    ARB_EXCHANGE_CODES[code.to_s.to_sym]
  end

  def arb_exchange_flag(code)
    country_flag_icon ARB_EXCHANGE_FLAGS[code.to_s.to_sym]
  end

  def order_button(ticker, operation, price, lots, lots_to_buy: lots, muted: false)
    return unless price && lots
    desired_total = 700
    lots_to_buy = [(desired_total / price).ceil, lots].min
    klass = muted ? 'btn-outline-secondary' : operation == 'Buy' ? 'btn-outline-success' : 'btn-outline-danger'
    tag.button "#{number_with_precision price, precision: 2} @ #{lots}", class: "btn btn-sm limit-order-button #{klass}",
      data: { operation: 'Buy', price: price, lots: lots_to_buy, ticker: ticker },
      title: "Buy #{number_with_delimiter lots_to_buy} @ #{price} = #{number_with_precision lots_to_buy * price, prceision: 2}"
  end

  def buy_button(ticker, price, lots, lots_to_buy = lots, muted: false)
    order_button ticker, 'Buy', price, lots, lots_to_buy: lots_to_buy, muted: muted
  end

  def sell_button(ticker, price, lots, lots_to_buy = lots, muted: false)
    order_button ticker, 'Sell', price, lots, lots_to_buy: lots_to_buy, muted: muted
  end
end
