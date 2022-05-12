module InstrumentsHelper
  def percentage_precision = 0
  def ratio_color(ratio) = ratio && ratio != 0 ? (ratio > 0 ? 'green' : 'red') : 'none'
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

  def format_price_in_millions(price, unit: nil, precision: 1)
    return unless price
    price_in_millions = price / 1_000_000.0
    number_to_currency price_in_millions, unit: currency_sign(unit), precision: precision, format: '%u%n'
  end

  def format_price(price, _unit = nil, unit: nil, precision: nil)
    return unless price.present?
    precision ||= price > 1_000 ? 0 : price < 0.1 ? 4 : 2
    number_to_currency price, unit: currency_sign(_unit || unit) || '', precision: precision if price
  end

  def colorized_price(price, base_price, unit: nil, inverse: false, precision: 1)
    ratio = inverse ? price_ratio(base_price, price) : price_ratio(price, base_price)
    title = number_to_percentage ratio * 100, precision: precision, format: '%n ﹪' if ratio
    tag.span class: "changebox changebox-#{ratio_color(ratio)}", title: title do
      format_price price, unit: unit
    end
  end

  def colorized_percentage(price, base_price, unit: '$', inverse: false, precision: percentage_precision, blank_threshold: nil, format: nil, title: nil)
    ratio = inverse ? price_ratio(base_price, price) : price_ratio(price, base_price)
    colorized_ratio ratio, title: format_price(title == :base ? base_price : price, unit: currency_sign(unit)), precision: precision, blank_threshold: blank_threshold, format: format
  end

  def colorized_ratio(ratio, title: nil, precision: percentage_precision, blank_threshold: nil, inverse: false, format: nil)
    return if blank_threshold && ratio.to_f.abs < blank_threshold
    ratio = ratio * -1 if ratio && inverse
    tag.span class: "changebox changebox-#{ratio_color(ratio)}", title: title do
      ratio_percentage ratio, precision: precision, format: format
    end
  end

  def colorized_diff(current, base, unit: 'USD', precision: nil)
    return unless current && base
    colorize_change base - current, green: current <= base, unit: unit, precision: precision
  end

  def ratio_percentage(ratio, precision: 0, format: nil)
    format ||= '%n ﹪'
    number_to_percentage ratio * 100, precision: precision, delimiter: ',', format: format if ratio
  end

  def relative_price(price, base_price, unit:, format: "absolute", inverse: false, precision: 1, percentage_precision: self.percentage_precision, blank_threshold: nil, title: nil)
    # method = format == 'absolute' ? :colorized_price : :colorized_percentage
    # send method, price, base_price, unit: unit, inverse: inverse, precision: method == :colorized_price ? precision : percentage_precision, hide_zero: hide_zero
    if format == 'absolute'
      colorized_price price, base_price, unit: unit, inverse: inverse, precision: precision
    elsif format == 'diff'
      colorized_diff base_price, price, unit: unit, precision: precision
    else
      colorized_percentage price, base_price, unit: unit, inverse: inverse, precision: percentage_precision, blank_threshold: blank_threshold, title: title
    end
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

  def m5_chart(candles, direction:)
    open = candles.compact.first&.open if candles
    return unless open

    candles.map do |candle|
      next tag.span(class: 'candle candle-placeholder') unless candle
      time = ''
      diff = (candle.close - open) / open
      high_diff = (candle.high - open) / open - diff
      low_diff = (candle.low - open) / open - diff
      positive = diff > 0
      diff *= -1 if direction == 'down'
      title = direction == 'up' ?
        "#{time[0, 5]} C #{candle.close} #{diff.round(4) * 100}% — H #{candle.high} +#{high_diff.round(4) * 100}%" :
        "#{time[0, 5]} C #{candle.close} #{diff.round(4) * 100}% — L #{candle.low} -#{low_diff.round(4) * 100}%"
      scale = 1000
      candle_color = direction == 'up' ? 'direction-up' : 'direction-down'
      candle_color = candle.up?? 'direction-up' : 'direction-down'
      tag.span class: 'candle' do
        (
          (direction == 'up' && positive ? tag.span(class: "candle-above volatility-bar volatility-high spike #{candle_color}", style: "height: #{(high_diff * scale).round}px") : '') +
          tag.span(class: "candle-body volatility-bar volatility-high #{candle_color}", style: "height: #{(diff * scale).round}px", title: title) +
          (direction == 'down' && !positive ? tag.span(class: "candle-above volatility-bar volatility-high spike #{candle_color}", style: "height: #{(-low_diff * scale).round}px") : '')
        ).html_safe
        # tag.span(class: "candle-below volatility-bar volatility-#{klass} direction-#{direction}", style: "height: #{candle.volatility_below * 100 * 5}px", title: title)
      end
    end.join.html_safe
  end


  def currency_sign(currency_code)
    currency_code = currency_code.currency if currency_code.is_a?(Instrument)
    Const::CurrencySigns[currency_code.to_s.to_sym] || currency_code
  end

  def currency_span(currency_code, suffix: nil)
    tag.span [currency_sign(currency_code), suffix].join(''), class: 'currency' if currency_code.present?
  end

  def red_green_class(is_green)
    is_green ? 'is-green' : 'is-red'
  end

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

  def sector_badge(instrument, link: true)
    return nil if instrument.rub?
    # return country_flag_icon('RUS') if instrument.rub?

    info = instrument&.info
    code = info&.sector_code
    text, background = *Const::SectorCodeTitles[code] || code || 'N/A'
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

  def growth_badge(aggregate)
    # aggregate.days_up.abs.in?([0, 1]) ? nil :
    #   aggregate.days_up.to_i > 0 ? tag.span(aggregate.days_up, class: "badge bg-success") :
    #   tag.span(aggregate.days_down, class: "badge bg-danger")
    tag.div(class: red_green_class(aggregate.days_up.to_i > 0) ) do
      count_bar aggregate.days_up.abs
    end
  end

  def change_map(aggregate)
    tag.div class: class_names('percentage-bars wide-bars') do
      aggregate.change_map.to_s.each_char.map do |code|
        classes = case code
          when 'U' then 'is-green'
          when 'D' then 'is-red'
          when 't' then 'is-green turn'
          when 's' then 'is-green spike'
          when 'T' then 'is-red turn turn-down'
          when 'S' then 'is-red spike'
        end
        tag.span class: class_names("percentage-bar", classes), data: { code: code }
      end.join.html_safe
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
    return fa_icon 'utensils', xsmall: true, title: 'Shortable', style: 'color: #ccc' if instrument.shortable?
    return fa_icon 'coins', small: true, title: 'Marginal', style: 'color: #ccc' if instrument.marginal?
    return fa_icon 'crown', xsmall: true, title: 'Tinkoff Premium' if instrument.premium?
  end

  def watched_icon(instrument)
    return fa_icon 'star', xsmall: true if instrument.watched?
  end

  def known_icon(instrument)
    # icons = [
    #   (:briefcase if InstrumentSet.portfolio.symbols.include?(instrument.ticker) && instrument.portfolio_item&.active?),
    #   (:briefcase if InstrumentSet.portfolio.symbols.include?(instrument.ticker)),
    #   (:bell      if InstrumentSet.alarms.symbols.include?(instrument.ticker)),
    #   (:user      if InstrumentSet.insiders.symbols.include?(instrument.ticker)),
    #   (:times     if InstrumentSet.rejected.symbols.include?(instrument.ticker)),
    # ].compact
    # icons = []
    # icons = [:glasses] if icons.empty? && InstrumentSet.known?(instrument.ticker)
    # icons.map { |icon| fa_icon(icon, xsmall: true) }.join(' ').html_safe

    return fa_icon :dice, xsmall: true if InstrumentSet.n1?(instrument.ticker)
    return fa_icon :glasses, xsmall: true if InstrumentSet.known?(instrument.ticker)
  end

  def instrument_logo(instrument, **options)
    @default_logo_instrument ||= Instrument.get('LX')
    inst = instrument.has_logo? ? instrument : @default_logo_instrument
    image_tag "#{inst.logo_path.sub('public', '')}", size: '19x19', class: 'rounded', **options
  end

  def instrument_logo_button(inst)
    # link_to instrument_logo(inst), trading_view_url(inst), target: '_blank', tabindex: '-1', class: 'open-chart', 'data-ticker': inst.ticker if inst.has_logo?
    instrument_logo inst, class: 'open-chart', 'data-ticker': inst.ticker
  end

  def tickers_copy_list(records)
    tickers = records.to_a.map(&:ticker)
    tag.p class: 'text-muted text-center x-tickers-list my-1 mx-5 py-1 px-5', style: 'font-size: 0.5rem', 'data-tickers': tickers.to_json do
      tag.span(tickers.join(' ')) + ' ' +
      link_to("Export", export_instruments_path(tickers: tickers.join(' '), set: params[:set]))
    end
  end


  def set_button_class(set_key)
    SET_BUTTON_CLASSES[set_key]
  end

  SET_BUTTON_CLASSES = {
    oil:             'inner-dark',
    coal:            'inner-dark',
    gas:             'inner-dark',
    mining:          'inner-dark',
    shipping:        'inner-dark',
    portfolio:       'inner-warning',
    main:            'inner-warning',
    categorized:     'inner-warning',
    arkf:            'inner-success',
    arkg:            'inner-success',
    arkk:            'inner-success',
    arkw:            'inner-success',
    russel_2000:     'inner-success',
    sp_500:          'inner-success',
    nasdaq_100:      'inner-success',
    current:         'inner-warning',
    '1'.to_sym =>    'inner-warning',
  }

  def format_risk_ratio(ratio)
    return if ratio.blank?
    reversed = 100 / ratio.to_f
    tag.span "#{reversed.to_f.round(1)}x", title: number_to_percentage(ratio, precision: 0)
    number_to_percentage(ratio, precision: 0)
  end

  def category_title(key)
    clean_key = key.to_s.gsub('*', '')
    InstrumentSet.category_titles[clean_key] || clean_key.humanize
  end

  def format_ticker(instrument)
    tag.span instrument.ticker, title: instrument.name, class: class_names('ticker-item', 'fw-bold text-decoration-underline': instrument.watched?)
  end
end
