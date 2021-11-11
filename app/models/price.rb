class Price < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  before_create { self.ticker ||= instrument.ticker }

  scope :missing, -> { where "source IS NULL OR source = ?", 'close' }

  def outdated? = !last_at || last_at < Current.date
  def today? = last_at && last_at > Current.date.midnight
  def low_lower?(percentage) = value && low && value - low >= value * percentage

  before_update def update_change
    close = instrument.d1_ago_close
    atr = instrument.info&.avg_change
    return unless value && close
    change = value / close - 1.0
    assign_attributes change: change.round(3), change_atr: atr && (change / atr).round(3)
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

    def set_missing_prices_to_close
      missing.each do |price|
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
