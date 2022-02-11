module BootstrapHelper
  def fa_icon(name, small: false, xsmall: false, **options)
    tag.i class: "fas fa-#{name} #{'fa-sm' if small} #{'fa-xs' if xsmall}".strip, **options
  end

  def bs_radio_button(name, value, label, **attrs)
    tag.div class: 'form-check form-check-inline' do
      radio_button_tag(name, value, params[name].to_s == value.to_s, class: 'form-check-input', **attrs) +
      label_tag("#{name}_#{value}", label, class: 'form-check-label', for: attrs[:id] || name)
    end
  end

  def bs_toggle_button(name, value, label, classes: nil, btn_class: nil)
    tag.span class: class_names('me-2', classes) do
      radio_button_tag(name, value, params[name].to_s == value.to_s, class: 'btn-check') +
      label_tag("#{name}_#{value}", label, class: class_names('btn btn-sm', btn_class || 'btn-outline-secondary'))
    end
  end

  def bs_button_group_radio_item(name, value, label, classes: nil, btn_class: nil)
    radio_button_tag(name, value, params[name].to_s == value.to_s, class: 'btn-check') +
    label_tag("#{name}_#{value}", label, class: class_names('btn', btn_class || 'btn-outline-secondary'))
  end

  def bs_check_box(name, label, value: '1', false_value: '0', inline: false, switch: false, default: false, id: name, checked: params[name] == value, **options)
    tag.div class: class_names('form-check', options[:class], 'form-check-inline': inline, 'form-switch': switch) do
      (default ? hidden_field_tag(name, '0', id: nil) : ''.html_safe) +
      check_box_tag(name, value, checked, class: 'form-check-input', id: id) +
      label_tag(name, label, class: 'form-check-label', for: id)
    end
  end

  def bs_select(name, label, options, mb: 1, blank: true, select_class: nil, style: nil)
    tag.div class: "row mb-#{mb} w-auto" do
      tag.div(class: 'col-sm-2') do
        label_tag name, label, class: 'col-form-label'
      end +
      tag.div(class: 'col-sm-10') do
        select_tag name, options_for_select(options, params[name]), class: "form-select form-select-sm #{select_class}", include_blank: blank, style: style
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
end