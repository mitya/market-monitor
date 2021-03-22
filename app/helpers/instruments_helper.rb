module InstrumentsHelper
  def percentage_precision = 0
  def ratio_color(ratio) = ratio ? (ratio > 0 ? 'green' : 'red') : 'none'
  def price_ratio(price, base_price) = (price / base_price - 1.0 if price && base_price)


  def colorize_value(value, base, unit: '$', title: nil)
    percentage = value / base - 1.0 if value && base
    green = value && base && value > base
    value_str = number_to_currency value, unit: currency_sign(unit)
    title ||= number_to_percentage percentage * 100, precision: 1, format: '%n ﹪' if percentage
    tag.span(value_str, class: "changebox changebox-#{green ? 'green' : 'red'}", title: title)
  end

  def colorize_change(value, green: nil, format: :number, title: nil, unit: nil, price: nil)
    green = value > 0 if green == nil && value.is_a?(Numeric)
    value = number_to_currency value, unit: unit if format == :number
    value = number_to_percentage value * 100, precision: percentage_precision, format: '%n ﹪' if value && format == :percentage
    title ||= number_to_currency price, unit: currency_sign(unit) if price
    tag.span(value, class: "changebox changebox-#{green ? 'green' : 'red'}", title: title)
  end

  def format_price_in_millions(price, unit: nil)
    return unless price
    price_in_millions = price / 1_000_000.0
    number_to_currency price_in_millions, unit: currency_sign(unit), precision: 1, format: '%u%nm'
  end

  def format_price(price, unit: nil)
    number_to_currency price, unit: currency_sign(unit), precision: price && price > 10_000 ? 0 : 2 if price
  end

  def colorized_price(price, base_price, unit: nil, inverse: false)
    ratio = inverse ? price_ratio(base_price, price) : price_ratio(price, base_price)
    title = number_to_percentage ratio * 100, precision: 1, format: '%n ﹪' if ratio
    tag.span class: "changebox changebox-#{ratio_color(ratio)}", title: title do
      format_price price, unit: unit
    end
  end

  def colorized_percentage(price, base_price, unit: nil, inverse: false)
    ratio = inverse ? price_ratio(base_price, price) : price_ratio(price, base_price)
    tag.span class: "changebox changebox-#{ratio_color(ratio)}", title: format_price(price, unit: currency_sign(unit)) do
      number_to_percentage ratio * 100, precision: percentage_precision, format: '%n ﹪' if ratio
    end
  end

  def relative_price(price, base_price, unit:, format: "absolute", inverse: false)
    method = format == 'absolute' ? :colorized_price : :colorized_percentage
    send method, price, base_price, unit: unit, inverse: inverse
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
    InstrumentInfo.where.not(industry: '').group(:industry).order(count: :desc).count.map { |industry, count| ["#{industry_short_name industry, length: 100} (#{count})", industry] }
  end

  def sector_options
    InstrumentInfo.where.not(sector: '').group(:sector).order(count: :desc).count.map { |sector, count| ["#{sector} (#{count})", sector] }
  end

  def sector_code_options
    SectorCodeOptions
  end

  def currency_options
    CurrencySigns.map { |code, sign| ["#{code} #{sign}", code] }
  end

  def insider_options_for(ticker)
    InsiderTransaction.for_ticker(ticker).pluck(:insider_name).uniq.sort.map { |name| [name.titleize, name] }
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
    'P' => "Purchase",
    'S' => "Sale",
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

  def sector_badge(code, **options)
    text, background = *SectorCodeTitles[code]
    background ||= 'secondary'
    foreground = 'text-dark' if background.in?(%w[warning info])
    tag.span text || code, class: "badge bg-#{background} #{foreground}", **options if text
  end

  def sec_tx_code_desc(sec_code)
    Sec4TransactionCodesDescriptions[sec_code]
  end

  def sec_tx_code_name(sec_code)
    Sec4TransactionCodesNames[sec_code] || sec_code
  end

  def instrument_logo(instrument)
    image_tag "#{instrument.logo_path.sub('public', '')}", size: '19x19', class: 'rounded' if instrument.has_logo?
  end

  def days_old_badge(date)
    return if date.blank?
    days_ago = (Date.current - date).to_i
    color = days_ago > 60 ? 'bg-danger' : days_ago > 15 ? 'bg-warning text-dark' : 'bg-success'
    tag.span "#{days_ago} d", class: "badge #{color}"
  end
end

__END__
InstrumentsHelper::IndustryShortNames.keys
InstrumentsHelper::IndustryShortNames.keys.include? Instrument.get('ANIP').info.industry
Instrument.get('ANIP').info.industry
InstrumentInfo.group_by(&:industry)

InstrumentInfo.group(:industry).count.sort_by(&:second).each { |industry, count| p industry }; nil
