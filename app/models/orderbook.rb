class Orderbook < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def ask_price_on(index) = asks&.dig(index, 0)
  def ask_size_on(index)  = asks&.dig(index, 1)

  def available? = status == 'NormalTrading'
  def not_available? = status == 'NotAvailableForTrading'

  class << self
    def sync(instrument)
      puts "Load orderbook for #{instrument}"
      instrument = Instrument[instrument]
      instrument.create_orderbook unless instrument.orderbook
      instrument.orderbook.sync
    end
  end

  def sync
    response = Tinkoff.book instrument
    if response['error']
      self.status = 'TinkoffError'
    else
      self.last = response['lastPrice']
      self.bids = response['bids'].map { |offer| [offer['price'], offer['quantity']]  }
      self.asks = response['asks'].map { |offer| [offer['price'], offer['quantity']]  }
      self.status = response['tradeStatus']
    end
    self.save!
  end
end
