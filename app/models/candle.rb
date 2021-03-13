class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'isin'

  scope :current, -> { where current: true }
  scope :final, -> { where current: false }
  scope :day, -> { where interval: 'day' }
  scope :find_date, -> date { order(date: :desc).where(date: date.to_date).take }
  scope :find_date_before, -> date { order(date: :desc).where('date < ?', date.to_date).take }

  class << self
    def last_loaded_date = final.maximum(:date)
  end
end
