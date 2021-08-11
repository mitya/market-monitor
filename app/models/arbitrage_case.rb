class ArbitrageCase < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def diff = long?? foreign_bid - spb_ask : spb_bid - foreign_ask
  def short? = !long?
  def buy_price = long?? spb_ask : foreign_ask

  class << self
    def current_tickers
      ArbitrageCase.where(date: Current.date, delisted: false).where('updated_at > ?', 15.seconds.ago).distinct.pluck(:ticker)
    end
  end
end