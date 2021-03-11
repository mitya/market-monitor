class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'isin'

  class << self
    def last_loaded_date = maximum(:date)
  end
end
