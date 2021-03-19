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
end
