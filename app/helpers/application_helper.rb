module ApplicationHelper
  def page_entries_block(records)
    tag.div page_entries_info(records), class: 'text-center mb-3'
  end

  def price_span(amount, unit: nil)
    tag.span number_to_currency(amount, unit: currency_sign(unit)), class: 'money-amount'
  end

  def fa_icon(name, small: false, **options)
    tag.i class: "fas fa-#{name} #{'fa-sm' if small}".strip, **options
  end

  def all_option
    [['All', '']]
  end

  def availability_options
    [['Tinkoff', 'tinkoff'], ['TInkoff Premium', 'premium']]
  end

  def bs_radio_button(name, value, label)
    tag.div class: 'form-check form-check-inline' do
      radio_button_tag(name, value, params[name].to_s == value.to_s, class: 'form-check-input') +
      label_tag("#{name}_#{value}", label, class: 'form-check-label')
    end
  end
end
