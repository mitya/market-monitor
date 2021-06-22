class PriceSignalResult < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  belongs_to :signal, class_name: 'PriceSignal' #, inverse_of: :result

  class << self
    def create_for(signal)
      result = find_or_initialize_by signal: signal
      instrument = signal.instrument

      return puts "Missing #{signal.ticker}".red if instrument == nil

      max_selector = signal.up?? :high : :low
      next_day = MarketCalendar.next_closest_weekday(signal.date + 1)
      d1 = instrument.day_candles.find_date(next_day)
      return unless d1

      result.instrument = instrument
      result.entered    = d1.range.include?(signal.enter)
      result.stopped    = d1.range.include?(signal.stop)

      relatify = -> price { signal.profit_ratio(price, use_stop: true).round(3) }

      result.d1_close     = relatify.call d1.close
      result.d1_max       = relatify.call d1.send(max_selector)

      if d2 = d1.next
        result.d2_close     = relatify.call d2.close
        result.d2_max       = relatify.call d2.send(max_selector)
      end

      if d3 = d2&.next
        result.d3_close     = relatify.call d3.close
        result.d3_max       = relatify.call d3.send(max_selector)
      end

      if w1 = instrument.day_candles.find_date_or_after(next_day + 5)
        result.w1_close = relatify.call w1.close
        result.w1_max   = relatify.call instrument.candles.day.where(date: next_day .. w1.date).pluck(:close).send(signal.up?? :max : :min)
      end

      if w2 = instrument.day_candles.find_date_or_after(next_day + 10)
        result.w2_close = relatify.call w2.close
        result.w2_max   = relatify.call instrument.candles.day.where(date: next_day .. w2.date).pluck(:close).send(signal.up?? :max : :min)
      end

      if m1 = instrument.day_candles.find_date_or_after(next_day + 20)
        result.m1_close = relatify.call m1.close
        result.m1_max   = relatify.call instrument.candles.day.where(date: next_day .. m1.date).pluck(:close).send(signal.up?? :max : :min)
      end

      if m2 = instrument.day_candles.find_date_or_after(next_day + 40)
        result.m2_close = relatify.call m2.close
        result.m2_max   = relatify.call instrument.candles.day.where(date: next_day .. m2.date).pluck(:close).send(signal.up?? :max : :min)
      end

      result.save!
    end
  end
end

__END__

PriceSignal.outside_bars.up.limit(100).each { |signal| PriceSignalResult.create_for signal }
PriceSignal.outside_bars.up.where(ticker: %w[BDTX]).limit(100).each { |signal| PriceSignalResult.create_for signal }
