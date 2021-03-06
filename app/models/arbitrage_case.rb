class ArbitrageCase < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def diff = long?? foreign_bid - spb_ask : spb_bid - foreign_ask
  def short? = !long?
  def buy_price = long?? spb_ask : foreign_ask
  def sell_price = long?? foreign_bid : spb_bid
  def local_source = long?? :spb_ask : :spb_bid
  def foreign_source = long?? :foreign_bid : :foreign_ask

  class << self
    def current_tickers(direction: nil)
      cases = ArbitrageCase.where(date: Current.date, delisted: false).where('percent >= ?', 0.3).where('updated_at > ?', 15.seconds.ago)
      cases = cases.where(long: direction == 'up') if direction
      cases.distinct.pluck(:ticker)
    end
  end
end
