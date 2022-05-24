class CurrencyConverter
  include StaticService

  ExchangeRates = {
    CNY: 0.15,
    RUB: 73.90,
  }

  def convert(amount, from_currency, to_currency, date: Current.date)
    return amount if from_currency == to_currency
    if from_currency.to_sym == :RUB && to_currency.to_sym == :USD
      if candle = cache[:USD][date]
        amount.to_d / candle.close
      end
    end
  end

  CURRENCY_TICKERS = {
    EUR: 'EUR_RUB', USD: 'USD_RUB'
  }

  def instrument_for(currency)
    PermaCache.instrument CURRENCY_TICKERS[currency]
  end

  def self.instance
    @instance ||= new
  end

  def cache
    @cache ||= begin
      ApplicationRecord.benchmark "Preload currency rates".magenta, silence: true do
        {
          USD: Candle.where(ticker: CURRENCY_TICKERS[:USD]).index_by(&:date)
        }
      end
    end
  end
end
