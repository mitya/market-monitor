module TablesHelper
  def th(key, label = nil, **attrs)
    return unless current_table_fields_include?(key)
    attrs['data-sort'] = attrs.delete(:sort) || key
    tag.th label, **attrs
  end

  def td(key, content = nil, **attrs, &block)
    return unless current_table_fields_include?(key)
    attrs['name'] = key
    tag.td content, **attrs, &block
    # content ||= capture(nil, &block)
    # tag.td content, **attrs
  end

  def data_table(**attrs, &block)
    fields = attrs.delete :fields
    @current_table_fields = fields&.to_set
    html = tag.table **attrs, &block
    @current_table_fields = nil
    html
  end

  def current_table_fields
    @current_table_fields || []
  end

  def current_table_fields_include?(key)
    current_table_fields.empty? || current_table_fields.include?(key)
  end
end
