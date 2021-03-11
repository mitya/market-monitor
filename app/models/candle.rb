class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'isin'

  scope :current, -> { where current: true }
  scope :final, -> { where current: false }
  scope :date_before, -> date { order(date: :desc).where 'date < ?', date.to_date }
  scope :date_is, -> date { order(date: :desc).where date: date.to_date }

  class << self
    def last_loaded_date = final.maximum(:date)
  end
end
