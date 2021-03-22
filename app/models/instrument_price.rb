class InstrumentPrice < ApplicationRecord
  self.table_name = 'prices'
  belongs_to :instrument, foreign_key: 'ticker'

  before_create { self.ticker ||= instrument.ticker }

  def outdated?
    !last_at || last_at < Current.date
  end

  class << self
    def refresh(set: nil)
      Instrument.tinkoff.in_set(set).abc.each do |inst|
        TinkoffConnector.update_current_price inst
        sleep 0.33
      end
    end

    def refresh_premium_from_iex
      refresh_from_iex Instrument.premium.map(&:ticker)
    end

    def refresh_from_iex(symbols = [])
      prices = ApiCache.get "cache/iex/tops.json", skip_if: symbols.any?, ttl: 15.minutes do
        IexConnector.tops(*symbols)
      end
      prices.each do |result|
        if instrument = Instrument[result['symbol']]
          next unless instrument.usd?
          price = result['lastSalePrice']
          puts "Update price for #{instrument.ticker} to #{price}"
          instrument.price!.update! value: price if price != nil && price != 0
        end
      end
    end
  end
end

__END__
InstrumentPrice.refresh
InstrumentPrice.refresh_premium_from_iex
InstrumentPrice.refresh_from_iex %w[aapl msft twtr]
