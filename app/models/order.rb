class Order < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def sell? = operation == 'Sell'
  def buy? = !sell?

  def total = price * lots

  class << self
    def sync
      data = Tinkoff.orders

      where.not(id: data.pluck('orderId')).delete_all

      data.each do |hash|
        instrument = Instrument.find_by(figi: hash['figi'])
        order = find_or_initialize_by(id: hash['orderId'].to_i)
        order.ticker        = instrument.ticker
        order.operation     = hash['operation']
        order.status        = hash['status']
        order.kind          = hash['type']
        order.price         = hash['price']
        order.lots          = hash['requestedLots']
        order.executed_lots = hash['executedLots']
        order.save!
      end
    end
  end

end
