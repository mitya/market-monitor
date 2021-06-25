class PriceSignalResult < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  belongs_to :signal, class_name: 'PriceSignal' #, inverse_of: :result

  scope :param_gte, -> (param, value) { where "(price_signals.data->'#{param}')::float >= ?", value if value.present? }
  scope :param_lte, -> (param, value) { where "(price_signals.data->'#{param}')::float <= ?", value if value.present? }
  scope :param_in_range, -> (param, range) { param_gte(param, range.begin).param_lte(param, range.end) if range.present? }

  class << self
    def create_for(signal)
      result = find_or_initialize_by signal: signal
      instrument = signal.instrument

      return puts "Missing #{signal.ticker}".red if instrument == nil
      puts "Check #{signal.ticker.ljust 6} #{signal.kind} on #{signal.date}"

      max_selector = signal.up?? :high : :low
      next_day = MarketCalendar.next_closest_weekday(signal.date + 1)
      d1 = instrument.day_candles.find_date(next_day)
      return unless d1

      result.instrument = instrument
      result.entered    = d1.range.include?(signal.enter)
      result.stopped    = d1.range.include?(signal.stop)

      relatify = -> price { signal.profit_ratio(price, use_stop: true).round(3) }

      {
        d1: d1,
        d2: d1&.next,
        d3: d1&.next&.next,
        d4: d1&.next&.next&.next,
      }.each do |period, candle|
        if candle
          result.send "#{period}_close=", relatify.call(candle.close)
          result.send "#{period}_max=", relatify.call(candle.send(max_selector))
        end
      end

      {
        w1: instrument.day_candles.find_date_or_after(next_day +  5),
        w2: instrument.day_candles.find_date_or_after(next_day + 10),
        w3: instrument.day_candles.find_date_or_after(next_day + 15),
        m1: instrument.day_candles.find_date_or_after(next_day + 20),
        m2: instrument.day_candles.find_date_or_after(next_day + 40)
      }.each do |period, candle|
        if candle
          result.send "#{period}_close=", relatify.call(candle.close)
          result.send "#{period}_max=", relatify.call(instrument.candles.day.where(date: next_day .. candle.date).pluck(:close).send(signal.up?? :max : :min))
        end
      end

      result.save!
    end
  end
end

__END__

PriceSignal.outside_bars.up.limit(100).each { |signal| PriceSignalResult.create_for signal }
PriceSignal.outside_bars.up.where(ticker: %w[BDTX]).limit(100).each { |signal| PriceSignalResult.create_for signal }
