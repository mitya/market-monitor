class InstrumentPrice < ApplicationRecord
  self.table_name = 'prices'
  belongs_to :instrument, foreign_key: 'figi'

  before_create { self.ticker ||= instrument.ticker }

  class << self
    def refresh
      Instrument.tinkoff.abc.each do |inst|
        TinkoffConnector.update_current_price inst
        sleep 0.4
      end
    end
  end
end


__END__
InstrumentPrice.refresh
