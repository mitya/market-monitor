module ApplicationHelper
  def page_entries_block(records)
    tag.div page_entries_info(records), class: 'text-center mb-3'
  end
end
