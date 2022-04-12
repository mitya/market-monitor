class FuturesController < ApplicationController
  def index
    @expiration = '2022-06-17'
    @future_specs = Future.all.where(expiration_date: @expiration)
    @futures = Instrument.where(ticker: @future_specs)
    @stocks  = Instrument.where(ticker: @future_specs.map(&:base_ticker))
    @futures_by_ticker = @futures.index_by { _1.future.base_ticker }
    p @futures_by_ticker
    Current.preload_prices_for Instrument.rub.to_a
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
