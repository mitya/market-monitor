module ApplicationHelper
  def page_entries_block(records)
    tag.div page_entries_info(records), class: 'text-center mb-3'
  end

  def price_span(amount, unit: nil)
    tag.span number_to_currency(amount, unit: currency_sign(unit)), class: 'money-amount'
  end

  def fa_icon(name, small: false, xsmall: false, **options)
    tag.i class: "fas fa-#{name} #{'fa-sm' if small} #{'fa-xs' if xsmall}".strip, **options
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

  def bs_toggle_button(name, value, label, classes: nil)
    tag.span class: class_names('me-2', classes) do
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

  def bs_select(name, label, options, mb: 1, blank: true, select_class: nil, style: nil)
    tag.div class: "row mb-#{mb}" do
      tag.div(class: 'col-sm-2') do
        label_tag name, label, class: 'col-form-label'
      end +
      tag.div(class: 'col-sm-10') do
        select_tag name, options_for_select(options, params[name]), class: "form-select #{select_class}", include_blank: blank, style: style
      end
    end
  end

  def bs_text_field(name, label, mb: 1, classes: nil, type: 'text')
    tag.div class: "row mb-#{mb}" do
      tag.div(class: 'col-sm-2') do
        label_tag name, label, class: 'col-form-label'
      end +
      tag.div(class: 'col-sm-10') do
        text_field_tag name, params[name], class: "form-control #{classes}", type: type
      end
    end
  end

  ExcahngesWithLogos = %w[NYSE NASDAQ MOEX]
  def exchange_logo(exchange_name)
    image_tag "exchange-logos/#{exchange_name}.png", size: '15x15', class: 'exchange-logo' if exchange_name.in?(ExcahngesWithLogos)
  end

  def country_flag(instrument)
    country_code, country_name = instrument.info&.country_code, instrument.info&.country
    country_code, country_name = 'rus', 'Russia' if instrument.exchange_name == 'MOEX'
    country_code, country_name = 'deu', 'Germanu' if instrument.ticker.include? '@DE'
    image_tag "/country-flags/#{country_code}.png", class: 'country-flag', title: country_name if country_code
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

  def date_as_mday(date)
    l date, format: :mday if date
  end

  IntervalTitles = { 'hour' => 'H1', '5min' => 'M5' }

  def interval_badge(interval)
    tag.span IntervalTitles[interval], class: 'badge bg-secondary'
  end

  def percentage_bar(value)
    value = (value.to_f.abs * 100).round(3)
    full_percents = value.to_i
    last_percent = (value % 1 * 100).to_i

    if full_percents > 20
      full_percents = 20
      last_percent = 0
      too_much = true
    end

    last_bar = last_percent.nonzero?? tag.span(class: "percentage-bar", style: "height: #{last_percent}%") : ''
    tag.div class: 'percentage-bars' do
      (full_percents).times.map do |n|
        tag.span class: "percentage-bar", style: "height: 100%"
      end.join.html_safe + last_bar + (too_much ? '!!!!' : '')
    end
  end

  def count_bar(value)
    percentage_bar value / 100.0
  end

  def label_width(locals = nil)
    locals&.dig(:lw) || @label_width || 1
  end

  def recent_period_options
    month_starts = (0..(Current.date.month - 1)).map { |n| Current.ytd + n.months }
    [['All']] + month_starts.map do |day|
      [day.strftime("%b %Y"), "#{day.beginning_of_month}..#{day.end_of_month}"]
    end
  end
end
