class CurrencyConverter
  include StaticService

  ExchangeRates = {
    CNY: 0.15,
    RUB: 73.90,
  }

  def convert(amount, from_currency, to_currency)
    return amount if from_currency == to_currency
    rate = ExchangeRates[from_currency.to_s.to_sym] || 1.0
    amount * rate
  end
end
