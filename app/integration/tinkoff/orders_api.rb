class Tinkoff
  concerning :OrdersApi do
    def book(instrument)
      instrument = Instrument[instrument]
      call_js_api "orderbook #{instrument.figi}"
    end

    def orders
      call_js_api "orders", account: 'iis'
    end

    def operations(since: Current.ru_market_open_time, till: Time.current + 5.seconds)
      call_js_api "operations _ _ #{since.xmlschema} #{till.xmlschema}", account: 'iis'
    end

    def limit_order(ticker, operation, lots, price, account: 'iis')
      call_js_api "limit-order #{Instrument[ticker].figi} #{operation} #{lots} #{price}", account: account
    end

    def market_order(ticker, operation, lots, account: 'iis')
      call_js_api "market-order #{Instrument[ticker].figi} #{operation} #{lots}", account: account
    end

    def cancel_order(order_id, account: 'iis')
      call_js_api "cancel-order #{order_id}", account: account
    end

    def limit_buy  (ticker, lots, price) = limit_order(ticker, 'Buy',  lots, price, account: 'iis')
    def limit_sell (ticker, lots, price) = limit_order(ticker, 'Sell', lots, price, account: 'iis')
    def market_buy (ticker, lots)       = market_order(ticker, 'Buy',  lots, account: 'iis')
    def market_sell(ticker, lots)       = market_order(ticker, 'Sell', lots, account: 'iis')
  end
end