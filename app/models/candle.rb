class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :ongoing, -> { where ongoing: true }
  scope :final, -> { where ongoing: false }
  scope :day, -> { where interval: 'day' }
  scope :todays, -> { where date: Current.date }
  scope :for_date, -> date { order(date: :desc).where(date: date.to_date) }
  scope :find_date, -> date { order(date: :desc).where(date: date.to_date).take }
  scope :find_date_before, -> date { order(date: :desc).where('date < ?', date.to_date).take }

  def final? = !ongoing?

  class << self
    def last_loaded_date = final.maximum(:date)
  end
end
