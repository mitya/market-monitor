module InstrumentsHelper
  def change_percentage(relation)
  end

  def colorize_change(value, green: nil, format: :number)
    green = value > 0 if green == nil && value.is_a?(Numeric)
    value = number_to_currency value if format == :number
    value = number_to_percentage value * 100, precision: 2 if value && format == :percentage
    tag.span(value, class: "changebox changebox-#{green ? 'green' : 'red'}")
  end

  def currency_sign(currency_code)
    CurrencySigns[currency_code.to_s.to_sym]
  end

  CurrencySigns = { USD: '$', RUB: '₽', EUR: '€' }
end
