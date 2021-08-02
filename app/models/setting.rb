class Setting < ApplicationRecord
  class << self
    def get(key, default = nil)
      find_by_key(key)&.value || default
    end

    def save(key, value)
      find_or_create_by(key: key).update(value: value)
    end
  end
end
