class Future < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker', inverse_of: :future

  class << self
    def import_intraday
      futures = Instrument.futures.rub
      Instrument.futures.rub.each { |inst| Tinkoff.import_intraday_candles_v2 inst, '1min' }
      Price.sync_with_last_candles Instrument.futures.rub
    end
  end
end
