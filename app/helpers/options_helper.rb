module OptionsHelper
  MainSortFields = {
    ticker:                "Ticker",
    pe:                    "P/E",
    beta:                  "ß",
    yield:                 "Yield",
    marketcap:             "Capitalization",
    d5_marketcap_volume:   "5-day Marketcap-relative Volume",
    d5_money_volume:       "5-day Money Volume",
    d1_money_volume:       "Yesterday Money Volume",
    days_up:               "Days Up",
    lowest_day_date:       "Low Date",
    lowest_day_gain:       "Low Gain",
    y1_high_change:        "Since 1Y High",
    y3_high_change:        "Since 3Y High",
    y1_low_change:         "Since 1Y Low",
    y3_low_change:         "Since 3Y Low",
    ema_20_trend:          "EMA 20",
    ema_50_trend:          "EMA 50",
    ema_200_trend:         "EMA 200",
    'portfolio.cost_in_usd': "Portfolio Cost",
    portfolio_ideal_cost:  "Portfolio Cost Ideal",
    portfolio_cost_diff:   "Portfolio Cost Ideal",
    change:                "Change",
    change_atr:            "ATR Change",
  }.stringify_keys.invert.to_a
  
  

  def all_option = [['❊', '']]

  def options_from_keys(keys)
    keys.map { |key| [key.underscore.humanize.downcase, key] }
  end

  def availability_options
    [[fa_icon('shopping-bag', xsmall: true), 'tinkoff'], [fa_icon('crown', xsmall: true), 'premium']]
  end

  def recent_dates_options
    1.upto(6).map { |n| ["#{n} #{'week'.pluralize n} ago", n.weeks.ago.to_date.to_s] }
  end

  def pagination_options
    %w[100 200 300 400 500 1000 5000]
  end
  
  def recent_period_options
    [['All']] + MarketCalendar.periods.map { |period| [period.begin.strftime("%b %Y"), period.to_s] }
  end
  
  def industry_options
    Stats.where.not(industry: '').group(:industry).order(count: :desc).count.map { |industry, count| ["#{industry_short_name industry, length: 100} (#{count})", industry] }
  end

  def sector_options
    Stats.where.not(sector: '').group(:sector).order(count: :desc).count.map { |sector, count| ["#{sector} (#{count})", sector] }
  end

  def type_options
    [[fa_icon('scroll', xsmall: true), 'Stock'], [fa_icon('layer-group', xsmall: true), 'Fund']]
  end

  def sector_code_options
    Const::SectorCodeOptions
  end

  def currency_options
    Const::CurrencySignsUsed.map { |code, sign| [sign, code] }
  end

  def insider_options_for(ticker)
    InsiderTransaction.for_ticker(ticker).pluck(:insider_name).uniq.compact.sort.map { |name| [name.titleize, name] }
  end    

  def instrument_order_options
    MainSortFields +
    Aggregate::RecentDaySelectors.map { |p| "gain.recent.#{p}" } +
    Aggregate::RecentDaySelectors.map { |p| "volume.#{p}" } +
    Aggregate::RecentDaySelectors.map { |p| "volatility.#{p}" } +
    MarketCalendar.current_special_dates.select.map { |d| "gain.date.#{d}" } +
    MarketCalendar.current_recent_years.select.map { |year| "gain.year.#{year}" }
  end

  def signal_order_options
    [
      ['Ticker', 'ticker'],
      ['Delta', 'delta'],
    ]
  end
  
  def min_amount_options
    %w[40_000 50_000 100_000 200_000 500_000 1_000_000]
  end    
end