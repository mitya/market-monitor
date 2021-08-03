class Operation < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :market, -> { where.not kind: 'BrokerCommission' }
  scope :passed, -> { where.not status: 'Decline' }

  def buy? = kind == 'Buy'
  alias_attribute :total, :payment

  class << self
    def sync
      last_sync_time = maximum(:created_at) || Current.ru_market_open_time
      puts "Load operations since #{last_sync_time}"
      data = Tinkoff.operations(since: last_sync_time)
      
      data['operations'].each do |hash|
        operation = find_or_initialize_by(id: hash['id'])
        operation.kind          = hash['operationType']
        operation.status        = hash['status']
        operation.datetime      = Time.parse hash['date']
        operation.instrument    = Instrument.find_by(figi: hash['figi'])
        operation.lots          = hash['quantity']
        operation.lots_executed = hash['quantityExecuted']
        operation.price         = hash['price']
        operation.payment       = hash['payment']
        operation.commission    = hash.dig 'commission', 'value'
        operation.currency      = hash['currency']
        operation.trades_count  = hash['trades']&.count
        operation.save!
      end
    end
  end
end
