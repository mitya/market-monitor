class Price < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  before_create { self.ticker ||= instrument.ticker }

  scope :missing, -> { where "source IS NULL OR source = ?", 'close' }

  def outdated? = !last_at || last_at < Current.date
  def today? = last_at && last_at > Current.date.midnight
  def low_lower?(percentage) = value && low && value - low >= value * percentage

  after_update def update_change
    close = instrument.d1_ago_close
    atr = instrument.info&.avg_change
    return unless value && close
    change = value / close - 1.0
    update_columns change: change.round(3), change_atr: atr && (change / atr).round(3)
  end

  class << self
    def refresh_from_tinkoff(instruments)
      instruments = Instrument.get_all(instruments).sort_by(&:ticker).reject(&:premium?)
      Current.parallelize_instruments(instruments, 1) { | inst| update_tinkoff_price inst; sleep 0.1 }
    end

    def update_tinkoff_price(instrument, **opts)
      instrument = Instrument[instrument]
      response_json = Tinkoff.last_hour_candles instrument, 2.hours.ago

      return puts "Refresh Tinkoff price for #{instrument} failed: #{response_json}".red if response_json['candles'] == nil
      candles = response_json.dig 'candles'
      candle = candles[-1]

      last = candle&.dig 'c'
      low = candles.map { |c| c['l'] }.min
      volume = candles.map { |c| c['v'] }.sum

      printf "Refresh Tinkoff price for %-7s %3i candles last=#{last}\n", instrument.ticker, candles.count
      instrument.price!.update! value: last, last_at: candle['time'], source: 'tinkoff', low: low, volume: volume if last
    end


    def refresh_from_iex(symbols = [])
      prices = ApiCache.get "cache/iex/tops.json", skip_if: symbols.any?, ttl: 15.minutes do
        puts "Load new prices from IEX..."
        Iex.tops(*symbols)
      end
      prices.sort_by { |p| p['symbol'] }.each do |result|
        if instrument = Instrument.get_by_iex_ticker(result['symbol'])
          next unless instrument.usd?

          price = result['lastSalePrice']
          last_at = Time.ms(result['lastUpdated'])
          next if instrument.price!.last_at && instrument.price!.last_at > last_at
          next if price.to_f == 0

          instrument.price!.update! value: price, last_at: last_at, source: 'iex', low: nil, volume: nil
        end
      end
      set_missing_prices_to_close
    end

    def refresh_premium_from_iex
      refresh_from_iex Instrument.premium.map(&:iex_ticker)
      set_missing_prices_to_close
    end


    def set_missing_prices_to_close
      Price.missing.each do |price|
        if yesterday = price.instrument.d1_ago
          price.update! source: 'close',
            value:   yesterday.close,
            last_at: yesterday.date.to_time.change(hour: 23)
        end
      end
    end
  end
end

__END__
Price.refresh
Price.refresh_premium_from_iex
Price.refresh_from_iex %w[aapl msft twtr]

Iex.tops Instrument.premium.map(&:ticker)
