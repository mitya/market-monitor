class Price < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  before_create { self.ticker ||= instrument.ticker }

  def outdated?
    !last_at || last_at < Current.date
  end

  class << self
    def refresh_from_tinkoff(instruments)
      instruments.each do |inst|
        Tinkoff.update_current_price inst
        sleep 0.1
      end
    end

    def refresh_from_iex(symbols = [])
      prices = ApiCache.get "cache/iex/tops.json", skip_if: symbols.any?, ttl: 15.minutes do
        puts "Load new prices from IEX..."
        Iex.tops(*symbols)
      end
      prices.sort_by { |p| p['symbol'] }.each do |result|
        if instrument = Instrument[result['symbol']]
          next unless instrument.usd?
          price = result['lastSalePrice']
          last_at = Time.ms(result['lastUpdated'])
          next if instrument.price!.last_at && instrument.price!.last_at > last_at

          puts "Update price for #{instrument.ticker.ljust 5} [#{last_at}] to #{price.nonzero?}"
          instrument.price!.update! value: price, last_at: last_at, source: 'iex' if price.to_f != 0
        end
      end
    end

    def refresh_premium_from_iex
      refresh_from_iex Instrument.premium.map(&:ticker)
    end
  end
end

__END__
Price.refresh
Price.refresh_premium_from_iex
Price.refresh_from_iex %w[aapl msft twtr]

Iex.tops Instrument.premium.map(&:ticker)
