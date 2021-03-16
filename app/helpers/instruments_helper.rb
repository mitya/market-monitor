module InstrumentsHelper
  def change_percentage(relation)
  end

  def colorize_value(value, base, unit: '$', title: nil)
    green = value && base && value > base
    value_str = number_to_currency value, unit: currency_span(unit)
    tag.span(value_str, class: "changebox changebox-#{green ? 'green' : 'red'}", title: title)
  end

  def colorize_change(value, green: nil, format: :number, title: nil, unit: nil, price: nil)
    green = value > 0 if green == nil && value.is_a?(Numeric)
    value = number_to_currency value, unit: unit if format == :number
    value = number_to_percentage value * 100, precision: 1, format: '%n ﹪' if value && format == :percentage
    title ||= number_to_currency price, unit: currency_sign(unit) if price

    # return tag.span(number_to_currency(title, unit: ''), class: "changebox changebox-#{green ? 'green' : 'red'}")
    tag.span(value, class: "changebox changebox-#{green ? 'green' : 'red'}", title: title)
  end

  def currency_sign(currency_code)
    CurrencySigns[currency_code.to_s.to_sym]
  end

  def currency_span(currency_code, suffix: nil)
    tag.span [currency_sign(currency_code), suffix].join(''), class: 'currency'
  end

  CurrencySigns = { USD: '$', RUB: '₽', EUR: '€' }

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

  def industry_short_name(industry)
    truncate IndustryShortNames[industry] || industry
  end
end

__END__
InstrumentsHelper::IndustryShortNames.keys
InstrumentsHelper::IndustryShortNames.keys.include? Instrument.get('ANIP').info.industry
Instrument.get('ANIP').info.industry
InstrumentInfo.group_by(&:industry)

InstrumentInfo.group(:industry).count.sort_by(&:second).each { |industry, count| p industry }; nil
