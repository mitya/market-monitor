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

  def options_from_keys(keys)
    keys.map { |key| [key.underscore.humanize.downcase, key] }
  end

  def availability_options
    [['Tinkoff', 'tinkoff'], ['TInkoff Premium', 'premium']]
  end

  def recent_dates_options
    1.upto(6).map { |n| ["#{n} #{'week'.pluralize n} ago", n.weeks.ago.to_date.to_s] }
  end

  def pagination_options
    %w[100 200 300 400 500 1000 5000]
  end

  def bs_radio_button(name, value, label)
    tag.div class: 'form-check form-check-inline' do
      radio_button_tag(name, value, params[name].to_s == value.to_s, class: 'form-check-input') +
      label_tag("#{name}_#{value}", label, class: 'form-check-label')
    end
  end

  def bs_toggle_button(name, value, label)
    tag.span class: 'me-2' do
      radio_button_tag(name, value, params[name].to_s == value.to_s, class: 'btn-check') +
      label_tag("#{name}_#{value}", label, class: 'btn btn-sm btn-outline-secondary')
    end
  end

  def bs_check_box(name, label, value: '1', false_value: '0', inline: false, switch: false, default: false, id: name, checked: params[name] == value, **options)
    tag.div class: class_names('form-check', options[:class], 'form-check-inline': inline, 'form-switch': switch) do
      (default ? hidden_field_tag(name, '0', id: nil) : ''.html_safe) +
      check_box_tag(name, value, checked, class: 'form-check-input', id: id) +
      label_tag(name, label, class: 'form-check-label', for: id)
    end
  end

  def bs_select(name, label, options, mb: 1, blank: true, select_class: nil)
    tag.div class: "row mb-#{mb}" do
      tag.div(class: 'col-sm-2') do
        label_tag name, label, class: 'col-form-label'
      end +
      tag.div(class: 'col-sm-10') do
        select_tag name, options_for_select(options, params[name]), class: "form-select #{select_class}", include_blank: blank
      end
    end
  end

  ExcahngesWithLogos = %w[NYSE NASDAQ MOEX]
  def exchange_logo(exchange_name)
    image_tag "exchange-logos/#{exchange_name}.png", size: '15x15', class: 'exchange-logo' if exchange_name.in?(ExcahngesWithLogos)
  end

  def decapitalize(string)
    string = string.to_s
    string.length > 10 && string.upcase == string ? string.titleize : string
  end

  def days_ago(date)
    if date
      days = (Current.date - date).to_i
      "#{days} days ago"
    end
  end

  def sessions_ago(date)
    %w[2 3 4 5 6 7].each do |n|
      return "#{n} ss" if date == Current.send("d#{n}_ago")
    end
    nil
  end

  def date_in_words(date)
    return unless date
    date = date.to_date
    case
      when date.to_date == Current.today then 'today'
      when date.to_date == Current.yesterday then 'yesterday'
      when date >= Current.d7_ago then sessions_ago(date)
      else days_ago(date)
    end
  end

  def date_as_wday(date)
    return if !date
    # return 'Yesterday' if date == Current.yesterday
    # return 'Today' if date == Current.today
    "#{l date, format: :wday_name}, #{date.day.ordinalize}"
  end
end
