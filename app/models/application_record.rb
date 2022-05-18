class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def thread_object_id = id
end
