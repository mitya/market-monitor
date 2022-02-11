class InstrumentsSorter
  OrderMap = {
    ticker:                "instruments.ticker",
    pe:                    "stats.pe desc",
    beta:                  "stats.beta desc",
    yield:                 "stats.dividend_yield desc",
    marketcap:             "stats.marketcap desc",
    d5_money_volume:       "stats.d5_money_volume desc",
    d5_marketcap_volume:   "stats.d5_marketcap_volume desc",
    days_up:               "aggregates.days_up desc",
    lowest_day_date:       "aggregates.lowest_day_date desc",
    lowest_day_gain:       "aggregates.lowest_day_gain desc",
    d1_money_volume:       "aggregates.d1_money_volume desc",
    y1_high_change:        "aggregates.y1_high_change desc",
    y3_high_change:        "aggregates.y3_high_change desc",
    y1_low_change:         "aggregates.y1_low_change desc",
    y1_low_change:         "aggregates.y1_low_change desc",
    ema_20_trend:          "indicators.ema_20_trend desc",
    ema_50_trend:          "indicators.ema_50_trend desc",
    ema_200_trend:         "indicators.ema_200_trend desc",
    portfolio_cost:        "portfolio.cost_in_usd",
    portfolio_ideal_cost:  "portfolio.ideal_cost_in_usd",
    portfolio_cost_diff:   "portfolio.cost_diff",
    change:                "prices.change desc",
    change_atr:            "prices.change_atr desc",
  }.stringify_keys

  class << self
    def determine_sort_order(order_field)
      order_field = order_field.presence.to_s
      period_selector = order_field.split('.').last
      order_expression = OrderMap[ order_field ]

      order_expression ||= case order_field
        when /gain.recent/, /gain.date/, /gain.year/
          "data->'gains'->'#{period_selector}'"
        when /volume/
          "data->'volumes'->'#{period_selector}' desc"
        when /volatility/
          "data->'volatilities'->'#{period_selector}' desc"
        when /portfolio/
          nil
      end

      order_expression ||= "instruments.ticker"

      Arel.sql("#{order_expression} nulls last")
    end
  end
end