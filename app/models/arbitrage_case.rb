class ArbitrageCase < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def current_tickers
      ArbitrageCase.where(date: Current.date, delisted: false).where('updated_at > ?', 15.seconds.ago).distinct.pluck(:ticker)
    end
  end
end
