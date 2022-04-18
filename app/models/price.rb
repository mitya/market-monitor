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
    def set_missing_prices_to_close
      missing.each do |price|
        if yesterday = price.instrument.d1_ago
          price.update! source: 'close',
            value:   yesterday.close,
            last_at: yesterday.date.to_time.change(hour: 23)
        end
      end
    end

    def sync_with_last_candles(instruments, interval: '1min')
      puts "Sync prices with #{interval} candles [#{instruments.size} tickers]".yellow
      last_candle_ids = Candle.interval_class_for(interval).select("max(id)").group(:ticker)
      last_candles = Candle.interval_class_for(interval).where(ticker: instruments).where(id: last_candle_ids).includes(:instrument)
      prices = Price.where(ticker: instruments).index_by(&:ticker)
      last_candles.each do |candle|
        if price = prices[candle.ticker]
          price.update! value: candle.close, last_at: candle.datetime, source: 'tinkoff' if candle.datetime > price.updated_at
        end
      end
      nil
    end
  end
end
