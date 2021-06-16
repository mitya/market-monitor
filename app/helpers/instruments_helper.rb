module InstrumentsHelper
  def percentage_precision = 0
  def ratio_color(ratio) = ratio ? (ratio > 0 ? 'green' : 'red') : 'none'
  def price_ratio(price, base_price) = (price && base_price ? price / base_price - 1.0 : nil)


  def colorize_value(value, base, unit: '$', title: nil)
    percentage = value / base - 1.0 if value && base
    green = value && base && value > base
    value_str = number_to_currency value, unit: currency_sign(unit)
    title ||= number_to_percentage percentage * 100, precision: 1, format: '%n ﹪' if percentage
    tag.span(value_str, class: "changebox changebox-#{green ? 'green' : 'red'}", title: title)
  end

  def colorize_change(value, green: nil, format: :number, title: nil, unit: nil, price: nil, precision: 2)
    green = value > 0 if green == nil && value.is_a?(Numeric)
    value = number_to_currency value, unit: currency_sign(unit), precision: precision if format == :number
    value = number_to_percentage value * 100, precision: percentage_precision, format: '%n ﹪' if value && format == :percentage
    title ||= number_to_currency price, unit: currency_sign(unit) if price
    tag.span(value, class: "changebox changebox-#{green ? 'green' : 'red'}", title: title)
  end

  def format_price_in_millions(price, unit: nil)
    return unless price
    price_in_millions = price / 1_000_000.0
    number_to_currency price_in_millions, unit: currency_sign(unit), precision: 1, format: '%u%nm'
  end

  def format_price(price, unit: nil, precision: nil)
    return unless price.present?
    precision ||= price > 10_000 ? 0 : price < 0.1 ? 4 : 2
    number_to_currency price, unit: currency_sign(unit), precision: precision if price
  end

  def colorized_price(price, base_price, unit: nil, inverse: false)
    ratio = inverse ? price_ratio(base_price, price) : price_ratio(price, base_price)
    title = number_to_percentage ratio * 100, precision: 1, format: '%n ﹪' if ratio
    tag.span class: "changebox changebox-#{ratio_color(ratio)}", title: title do
      format_price price, unit: unit
    end
  end

  def colorized_percentage(price, base_price, unit: '$', inverse: false)
    ratio = inverse ? price_ratio(base_price, price) : price_ratio(price, base_price)
    tag.span class: "changebox changebox-#{ratio_color(ratio)}", title: format_price(price, unit: currency_sign(unit)) do
      ratio_percentage ratio, precision: percentage_precision
    end
  end

  def colorized_diff(current, base, unit: 'USD', precision: nil)
    return unless current && base
    colorize_change base - current, green: current <= base, unit: 'USD', precision: precision
  end

  def ratio_percentage(ratio, precision: 0)
    number_to_percentage ratio * 100, precision: precision, delimiter: ',', format: '%n ﹪' if ratio
  end

  def relative_price(price, base_price, unit:, format: "absolute", inverse: false)
    method = format == 'absolute' ? :colorized_price : :colorized_percentage
    send method, price, base_price, unit: unit, inverse: inverse
  end

  def with_2_digits(value)
    number_with_precision value, precision: 2
  end

  def candle_info(candle)
    "L-H: #{with_2_digits candle.low}-#{with_2_digits candle.high}  OC: #{with_2_digits candle.open}-#{with_2_digits candle.close}" if candle
  end

  def volatility_indicator(instrument, accessor_or_date, format: :bar)
    candle = accessor_or_date.is_a?(Date) ?
      instrument.day_candles!.find_date(accessor_or_date) :
      instrument.send(accessor_or_date)

    volatility = candle&.volatility
    if volatility == nil
      return nil if format == :percentage
      return tag.span class: 'candle' do
        tag.span class: "volatility-bar volatility-nil", style: "height: 0px"
      end
    end

    high       = candle.high
    low        = candle.low
    direction  = candle.direction
    percent    = number_to_percentage volatility * 100, precision: 0, format: '%n ﹪'
    title      = "L:#{number_with_precision low, precision: 2} H:#{number_with_precision high, precision: 2}"
    klass      = volatility < 0.02 ? 'low' : volatility < 0.05 ? 'mid' : 'high'
    case format
    when :bar
      title = "V:#{percent} #{title} #{accessor_or_date}"
      tag.span class: 'candle' do
        tag.span(class: "candle-above volatility-bar volatility-#{klass} direction-#{direction}", style: "height: #{candle.volatility_above * 100 * 5}px", title: title) +
        tag.span(class: "candle-body  volatility-bar volatility-#{klass} direction-#{direction}", style: "height: #{candle.volatility_body  * 100 * 5}px", title: title) +
        tag.span(class: "candle-below volatility-bar volatility-#{klass} direction-#{direction}", style: "height: #{candle.volatility_below * 100 * 5}px", title: title)
      end
      # tag.span class: "volatility-bar volatility-#{klass} direction-#{direction}", style: "height: #{volatility * 100 * 5}px", title: title
    when :percentage
      tag.span percent, title: title, class: "volatility-value volatility-#{klass}"
    end
  end


  def currency_sign(currency_code)
    CurrencySigns[currency_code.to_s.to_sym] || currency_code
  end

  def currency_span(currency_code, suffix: nil)
    tag.span [currency_sign(currency_code), suffix].join(''), class: 'currency' if currency_code.present?
  end

  def red_green_class(is_green)
    is_green ? 'is-green' : 'is-red'
  end

  CurrencySigns = { USD: '$', RUB: '₽', EUR: '€', CNY: '¥', GBP: '£' }

  IndustryShortNames = {
    "All Other Telecommunications": "Telecommunications",
    "Custom Computer Programming Services": "Computer Programming Services",
    "Direct Life Insurance Carriers": "Life Insurance",
    "Motor Vehicle Gasoline Engine and Engine Parts Manufacturing": "Vehicle Engine Manufacturing",
    "Investment Banking and Securities Dealing": "Investment Banking",
    "All Other Miscellaneous Chemical Product and Preparation Manufacturing": "Chemical Manufacturing",
    "Computer Systems Design Services": "Computer Services",
    "Direct Property and Casualty Insurance Carriers": "Property Insurance",
    "Food Service Contractors": "Food Service",
    "Research and Development in Biotechnology": "Biotech R&D",
    "Nuclear Electric Power Generation": "Nuclear",
    "Crude Petroleum and Natural Gas Extraction": "Crude & Gas",
    "Securities and Commodity Exchanges": "Securities and Commodity",
    "Biological Product (except Diagnostic) Manufacturing": "Biotech Manufacturing",
    "Semiconductor and Related Device Manufacturing": "Semiconductor",
    "Other Financial Vehicles": "Financial",
    "Surgical and Medical Instrument Manufacturing": "Medical Manufacturing",
    "Data Processing, Hosting, and Related Services": "Data Processing",
    "Commercial Banking": "Banking",
    "Pharmaceutical Preparation Manufacturing": "Pharmaceutical",
    "Software Publishers": "Software",
  }.transform_keys(&:to_s)

  def industry_short_name(industry, length: 30)
    truncate IndustryShortNames[industry] || industry, length: length
  end

  def industry_options
    Stats.where.not(industry: '').group(:industry).order(count: :desc).count.map { |industry, count| ["#{industry_short_name industry, length: 100} (#{count})", industry] }
  end

  def sector_options
    Stats.where.not(sector: '').group(:sector).order(count: :desc).count.map { |sector, count| ["#{sector} (#{count})", sector] }
  end

  def type_options
    [%w[Stock Stock], %w[Fund Fund]]
  end

  def sector_code_options
    SectorCodeOptions
  end

  def currency_options
    CurrencySigns.map { |code, sign| ["#{code} #{sign}", code] }
  end

  def insider_options_for(ticker)
    InsiderTransaction.for_ticker(ticker).pluck(:insider_name).uniq.compact.sort.map { |name| [name.titleize, name] }
  end

  def instrument_order_options
    Aggregate::Accessors.map { |p| "aggregates.#{p.remove('_ago')}" } +
    Aggregate::Accessors.select { |p| p.include?('_ago') }.map { |p| "aggregates.#{p.remove('_ago')}_vol desc" } +
    [
      ['P/E',      'stats.pe desc'],
      ['ß',        'stats.beta desc'],
      ['Yield',    'stats.dividend_yield desc'],
      ['Capitalization',    'stats.marketcap desc'],
      ['Days Up',  'aggregates.days_up desc'],
      ['Low Date', 'aggregates.lowest_day_date desc'],
      ['Low Gain', 'aggregates.lowest_day_gain desc'],
      ['Trend', 'aggregates.days_up desc'],
      ['Portfolio Cost',       'portfolio.cost_in_usd'],
      ['Portfolio Cost Ideal', 'portfolio.ideal_cost_in_usd'],
      ['Portfolio Cost Diff',  'portfolio.cost_diff'],
    ]
  end

  def signal_order_options
    [
      ['Ticker', 'ticker'],
      ['Delta', 'delta'],
    ]
  end

  Sec4TransactionCodesDescriptions = {
    'P' => "Open market or private purchase of securities",
    'S' => "Open market or private sale of securities",
    'V' => "Transaction voluntarily reported earlier than required",
    'A' => "Grant, award, or other acquisition",
    'D' => "Sale (or disposition) back to the issuer of the securities",
    'F' => "Payment of exercise price or tax liability by delivering or withholding securities",
    'I' => "Discretionary transaction, which is an order to the broker to execute the transaction at the best possible price",
    'M' => "Exercise or conversion of derivative security",
    'C' => "Conversion of derivative security (usually options)",
    'E' => "Expiration of short derivative position (usually options)",
    'H' => "Expiration (or cancellation) of long derivative position with value received (usually options)",
    'O' => "Exercise of out-of-the-money derivative securities (usually options)",
    'X' => "Exercise of in-the-money or at-the-money derivatives securities (usually options)",
    'G' => "Bona fide gift form of any clauses",
    'L' => "Small acquisition",
    'W' => "Acquisition or disposition by will or laws of descent and distribution",
    'Z' => "Deposit into or withdrawal from voting trust",
    'J' => "Other acquisition or disposition (transaction described in footnotes)",
    'K' => "Transaction in equity swap or similar instrument",
    'U' => "Disposition due to a tender of shares in a change of control transaction",
  }

  Sec4TransactionCodesNames = {
    'P' => "Buy",
    'S' => "Sell",
    'F' => "Exercise",
  }

  SectorCodeTitles = {
    "commercialservices"    => ["Commercial",         'primary'],
    "communications"        => ["Communications"],
    "consumerdurables"      => ["Consumer Durables"],
    "consumernon-durables"  => ["Consumer Non-durables"],
    "consumerservices"      => ["Consumer Services"],
    "distributionservices"  => ["Distribution"],
    "electronictechnology"  => ["Electronics",        'warning'],
    "energyminerals"        => ["Energy",             'success'],
    "finance"               => ["Finance",            'dark'],
    "healthservices"        => ["Health Services",    'danger'],
    "healthtechnology"      => ["Health Tech",        'danger'],
    "industrialservices"    => ["Industrial",         'success'],
    "miscellaneous"         => ["Misc"],
    "n/a"                   => ["N/A"],
    "non-energyminerals"    => ["Minerals",           'success'],
    "processindustries"     => ["Process Industries", 'success'],
    "producermanufacturing" => ["Manufactoring"],
    "retailtrade"           => ["Retail",             'primary'],
    "technologyservices"    => ["Technology",         'warning'],
    "transportation"        => ["Transportation"],
    "utilities"             => ["Utilities"],
  }

  SectorCodeOptions = SectorCodeTitles.transform_values { |val| val.first }.invert

  def sector_badge(instrument, link: true)
    info = instrument&.info
    code = info&.sector_code
    text, background = *SectorCodeTitles[code] || code || 'N/A'
    text, background = ['RUS', 'light'] if instrument.rub?
    background ||= 'secondary'
    foreground = 'text-dark' if background.in?(%w[warning info light])
    badge = tag.span text || code, class: "badge bg-#{background} #{foreground}", title: info&.industry if text
    instrument.info&.accessible_peers.present?? link_to(badge, url_for(tickers: instrument.info.accessible_peers_and_self.join(' '))) : badge
  end

  def sec_tx_code_desc(sec_code)
    Sec4TransactionCodesDescriptions[sec_code]
  end

  def sec_tx_code_name(sec_code)
    Sec4TransactionCodesNames[sec_code] || sec_code
  end

  def days_old_badge(date)
    return if date.blank?
    days_ago = (Current.date - date).to_i
    color = days_ago > 350 ? 'bg-danger' : days_ago > 95 ? 'bg-dark' : days_ago > 35 ? 'bg-dark' : 'bg-secondary'
    # text = Current.date == date ? 'today' : "#{days_ago} d"
    # text = Current.date == date ? 'today' : distance_of_time_in_words(date, Current.date, scope: 'datetime.distance_in_words.short')
    text = date.year == Current.date.year ? l(date, format: :month) : l(date, format: :month_year)
    tag.span text, class: "badge #{color}", title: date
  end

  def growth_badge(aggregate)
    # aggregate.days_up.abs.in?([0, 1]) ? nil :
    #   aggregate.days_up.to_i > 0 ? tag.span(aggregate.days_up, class: "badge bg-success") :
    #   tag.span(aggregate.days_down, class: "badge bg-danger")
    unless aggregate.days_up.abs.in?([0, 1])
      tag.div(class: red_green_class(aggregate.days_up.to_i > 0) ) do
        count_bar aggregate.days_up.abs
      end
    end
  end

  def trading_view_url(instrument)
    "https://www.tradingview.com/chart/?symbol=#{instrument.exchange_ticker}"
  end

  def seeking_alpha_url(instrument)
    "https://seekingalpha.com/symbol/#{instrument.ticker}"
  end

  def red_green(text, is_green)
    tag.span text, class: red_green_class(is_green)
  end

  def red_green_class(is_green)
    is_green ? 'is-green' : 'is-red'
  end

  def type_icon(instrument)
    return fa_icon 'layer-group', small: true, title: 'Fund' if instrument.fund?
    return fa_icon 'coins', small: true, title: 'Tinkoff Premium', style: 'color: #ccc'  if instrument.marginal?
    return fa_icon 'crown', xsmall: true, title: 'Tinkoff Premium' if instrument.premium?
  end

  def known_icon(instrument)
    icons = [
      (:briefcase if InstrumentSet.portfolio.symbols.include?(instrument.ticker)),
      (:bell      if InstrumentSet.alarms.symbols.include?(instrument.ticker)),
      (:user      if InstrumentSet.insiders.symbols.include?(instrument.ticker)),
    ].compact
    icons = [:glasses] if icons.empty? && InstrumentSet.known?(instrument.ticker)
    icons.map { |icon| fa_icon(icon, xsmall: true) }.join(' ').html_safe
  end

  def instrument_logo(instrument, **options)
    inst = instrument.has_logo? ? instrument : Instrument.get('LX')
    image_tag "#{inst.logo_path.sub('public', '')}", size: '19x19', class: 'rounded', **options
  end

  def instrument_logo_button(inst)
    # link_to instrument_logo(inst), trading_view_url(inst), target: '_blank', tabindex: '-1', class: 'open-chart', 'data-ticker': inst.ticker if inst.has_logo?
    instrument_logo inst, class: 'open-chart', 'data-ticker': inst.ticker
  end

  def tickers_copy_list(records)
    tickers = records.map(&:ticker)
    tag.p(tickers.join(' '), class: 'text-muted text-center x-tickers-list mb-1', style: 'font-size: 0.5rem', 'data-tickers': tickers.to_json) +
    tag.p(class: 'text-muted text-center', style: 'font-size: 0.5rem') do
      link_to "Export", export_instruments_path(tickers: tickers.join(' '), set: params[:set])
    end
  end

  def min_amount_options
    %w[100_000 200_000 500_000 1_000_000]
  end
end

__END__
InstrumentsHelper::IndustryShortNames.keys
InstrumentsHelper::IndustryShortNames.keys.include? Instrument.get('ANIP').info.industry
Instrument.get('ANIP').info.industry
Stats.group_by(&:industry)

Stats.group(:industry).count.sort_by(&:second).each { |industry, count| p industry }; nil
