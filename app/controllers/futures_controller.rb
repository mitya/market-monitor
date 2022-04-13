class FuturesController < ApplicationController
  def index
    @expiration = '2022-06-17'
    @future_specs = Future.all.where(expiration_date: @expiration).includes(:instrument)
    @futures = @future_specs.map(&:instrument)
    @stocks  = Instrument.where(ticker: @future_specs.map(&:base_ticker))
    @futures_by_ticker = @futures.index_by { _1.future.base_ticker }

    Current.preload_prices_for Instrument.rub.to_a

    @rows = @stocks.map do |stock|
      future = @futures_by_ticker[stock.ticker]
      future_spec = @future_specs.detect { _1.base_ticker == stock.ticker}
      future_price = (future.last!.to_d / future_spec.base_lot).to_d
      next if future_price == 0
      relation = stock.last! / future_price

      OpenStruct.new(
        stock: stock, future: future, future_spec: future_spec, future_price: future_price,
        relation: relation, stock_is_more_expensive: stock.last! > future_price
      )
    end.compact.sort_by(&:relation).reverse
  end

  def imported
    stock_tickers = Instrument.active.rub.pluck(:ticker).to_set

    @futures = JSON.parse File.read("db/data/tinkoff-futures.json"), object_class: OpenStruct
    @futures = @futures.instruments
    @futures = @futures.select { stock_tickers.include? _1.basicAsset }
    @futures = @futures.reject { _1.expirationDate.to_time.past? }
    @futures = @futures.sort_by &:ticker
  end
end
