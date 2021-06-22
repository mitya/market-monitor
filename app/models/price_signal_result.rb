class PriceSignalResult < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  belongs_to :signal, class_name: 'PriceSignal'

  class << self
    def create_for(signal)
      result = find_or_initialize_by signal: signal
      instrument = signal.instrument

      return puts "Missing #{signal.ticker}".red if instrument == nil

      max_selector = signal.up?? :high : :low
      next_day = MarketCalendar.next_closest_weekday(signal.date + 1)
      d1 = instrument.candles.day.find_date(next_day)
      return unless d1

      result.instrument = instrument
      result.entered    = d1.range.include?(signal.enter)
      result.stopped    = d1.range.include?(signal.stop)

      relatify = -> price { (price / signal.enter).round(3) }

      result.d1_close     = relatify.call d1.close
      result.d1_max       = relatify.call d1.send(max_selector)

      if d2 = d1.next
        result.d2_close     = relatify.call d2.close
        result.d2_max       = relatify.call d2.send(max_selector)
      end

      if w1 = d1.after_n_days(4)
        result.w1_close     = relatify.call w1.close
        result.w1_max       = relatify.call w1.send(max_selector)
        result.w1_max_close = relatify.call instrument.candles.day.where(date: next_day .. w1.date).pluck(:close).send(signal.up?? :max : :min)
      end

      result.save!
    end
  end
end

__END__

PriceSignal.outside_bars.up.limit(100).each { |signal| PriceSignalResult.create_for signal }
