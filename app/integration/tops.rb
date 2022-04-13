class Tops
  class << self
    def gainers_us(**options) = gainers(currency: 'USD', position: :last,  **options)
    def losers_us(**options)  = gainers(currency: 'USD', position: :first, **options)
    def gainers_ru(**options) = gainers(currency: 'RUB', position: :last,  **options)
    def losers_ru(**options)  = gainers(currency: 'RUB', position: :first, **options)

    def gainers(limit: 33, currency: 'USD', position: :first, period: :today)
      if period.blank? || period.to_s == 'today' || period.to_s == 'last'
        Price.where(ticker: Instrument.active.where(currency: currency)).order(:change).pluck(:ticker).send(position, limit).reverse
      else
        order_expr = Arel.sql("data->'gains'->'#{period}'")
        Aggregate.where(ticker: Instrument.where(currency: currency)).where("#{order_expr} IS NOT NULL").order(order_expr).pluck(:ticker).send(position, limit).reverse
      end
    end
  end
end
