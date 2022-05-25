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

    def above_ma_20  = select_by_ma(20,  :above, 0)
    def above_ma_50  = select_by_ma(50,  :above, 0)
    def above_ma_200 = select_by_ma(200, :above, 0)
    def below_ma_20  = select_by_ma(20,  :below, 0)
    def below_ma_50  = select_by_ma(50,  :below, 0)
    def below_ma_200 = select_by_ma(200, :below, 0)

    def select_by_ma(ma_length, position, days_since_last = 0)
      field = "ema_#{ma_length}_trend"
      operator = position == :above ? '>' : '<'
      # Instrument.stocks.usd.joins(:indicators_record).where("#{field} #{operator} #{days_since_last}").order(field).pluck(:ticker)

      Instrument.stocks.usd.joins(:indicators_record).where("#{field} #{operator} #{days_since_last}").order(field).
        select { _1.send("change_to_ema_#{ma_length}").abs > 0.07 }.pluck(:ticker)
    end
  end
end
