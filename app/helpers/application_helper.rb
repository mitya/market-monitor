module ApplicationHelper
  def page_title!(title)
    @page_title = title
  end

  def menu_hidden?
    @menu_hidden || params.include?('mh')
  end

  def page_entries_block(records)
    tag.div page_entries_info(records), class: 'text-center mb-3'
  end

  def price_span(amount, unit: nil)
    tag.span number_to_currency(amount, unit: currency_sign(unit)), class: 'money-amount'
  end

  ExcahngesWithLogos = %w[NYSE NASDAQ MOEX]
  def exchange_logo(exchange_name)
    image_tag "exchange-logos/#{exchange_name}.png", size: '15x15', class: 'exchange-logo' if exchange_name.in?(ExcahngesWithLogos)
  end

  def country_flag(instrument)
    country_code, country_name = instrument.info&.country_code, instrument.info&.country
    country_code, country_name = 'rus', 'Russia' if instrument.exchange_name == 'MOEX'
    country_code, country_name = 'deu', 'Germanu' if instrument.ticker.include? '@DE'
    country_flag_icon country_code, country_name
  end

  def country_flag_icon(country_code, country_name = nil)
    image_tag "/country-flags/#{country_code}.png", class: 'country-flag', title: country_name if country_code
  end

  def decapitalize(string)
    string = string.to_s
    string.length > 10 && string.upcase == string ? string.titleize : string
  end

  def sessions_ago(date)
    %w[2 3 4 5 6 7].each do |n|
      return "#{n} ss" if date == Current.send("d#{n}_ago")
    end
    nil
  end

  IntervalTitles = { 'hour' => 'H1', '5min' => 'M5' }

  def interval_badge(interval)
    tag.span IntervalTitles[interval], class: 'badge bg-secondary'
  end

  def percentage_bar(value, classes: nil, rtl: false, title: nil, threshold: 15, threshold_text: nil, precision: 0)
    value = (value.to_f.abs * 100).round(3)
    full_percents = value.to_i
    last_percent = (value % 1 * 100).to_i

    if full_percents > threshold
      full_percents = 15
      last_percent = 0
      too_much = true
    end

    if too_much
      if threshold_text.is_a?(Numeric)
        full_percents = [threshold_text, full_percents].max
      else
        return threshold_text if threshold_text
        return tag.span title, class: class_names(classes, 'percentage-bar-text-replacement')
      end
    end

    title ||= number_to_percentage(value, precision: 1)
    last_bar = last_percent.nonzero?? tag.span(class: "percentage-bar", style: "height: #{last_percent}%") : ''
    tag.div class: class_names('percentage-bars', classes), title: title, 'data-value': value do
      full_bars = (full_percents).times.map do |n|
        tag.span class: "percentage-bar", style: "height: 100%"
      end.join.html_safe
      # too_much_sign = too_much ? '!!!' : ''
      too_much_sign = ''
      ((rtl ? (last_bar + full_bars) : (full_bars + last_bar)) + too_much_sign).html_safe
    end
  end

  def percentage_bar_or_number(value, classes: nil, precision: 1, rtl: false, threshold: 0.08, title: nil)
    if value.to_f.abs >= threshold
      colorized_ratio value, precision: precision, format: '%n'
    else
      percentage_bar value, classes: classes, rtl: rtl, title: title
    end
  end

  def count_bar(value, **attrs)
    percentage_bar value / 100.0, **attrs
  end

  def relative_bar(base, current, **attrs)
    ratio = current / base - 1 rescue 0
  end

  def ratio_bar(ratio, threshold: 0.08, **attrs)
    return if !ratio
    if ratio.to_f.abs >= threshold
      colorized_ratio ratio, precision: 1, format: '%n'
    else
      attrs[:classes] = "#{attrs[:classes]} #{red_green_class(ratio > 0)}".strip
      percentage_bar ratio, **attrs
    end
  end

  def label_width(locals = nil)
    locals&.dig(:lw) || @label_width || 1
  end


  def range_fields(name, type: 'text', classes: 'form-control form-control-sm d-inline w-auto', size: 5, **attrs)
    tag.input(type: type, class: classes, name: "#{name}_from", value: params["#{name}_from"], size: size, **attrs) +
    " ??? " +
    tag.input(type: type, class: classes, name: "#{name}_to", value: params["#{name}_to"], size: size, **attrs)
  end

  def form_field(label = nil, sizes = [2, 10])
    tag.div(class: 'row mb-1') do
      tag.div(class: "col-sm-#{sizes.first}") do
        tag.label label, class: 'col-form-label'
      end +
      tag.div(class: "col-sm-#{sizes.last}") do
        yield
      end
    end
  end

  def round_percentage(value)
    return nil if not value
    return value if value == Float::INFINITY
    return value if value < 100
    return value.round(-1)
  end

  def round_to(value, precision: 3)
    case value
      when 10000.. then value.round(-2)
      when 500.. then value.round(-1)
      when 100.. then value.round
      when 30..100 then value.round
      else value
    end
  end

  def float_to_percentage(value, precision: 1)
    return nil unless value
    number_to_percentage value * 100, precision: precision
  end

  def format_percentage(value, precision: percentage_precision, round: false)
    return unless value
    value = value * 100
    value = round_percentage(value) if round
    number_to_percentage value, precision: precision, format: '%n??????'
  end
end
