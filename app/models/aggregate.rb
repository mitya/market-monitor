class Aggregate < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :current, -> { where current: true }

  # store_accessor :data, :change
  # store_accessor :data, :volatility

  Accessors = %w[d1 d2 d3 d4 w1 w2 m1].map { |p| "#{p}_ago" } + %w[y2021 nov06 mar23 feb19 y2020 y2019]

  def days_down = days_up.to_i > 0 ? 0 : -days_up

  def lowest_day = lowest_day_date && instrument.day_candles.find_date(lowest_day_date)
  def lowest_day_low = lowest_day&.low

  class << self
    def create_for(instrument, date: Current.date, gains: true, analyze: true)
      puts "Aggregate data on #{date} for #{instrument}"
      aggregate = find_or_initialize_by instrument: instrument, date: date
      aggregate.current = true

      if gains
        Accessors.each do |accessor|
          suffix = accessor =~ /_ago|y\d{4}/ ? 'open' : 'low'
          price = instrument.send("#{accessor}_#{suffix}")
          base_price = instrument.base_price
          if price && base_price
            ratio = price / base_price - 1.0
            aggregate.send "#{accessor.remove '_ago'}=", ratio.to_f.round(3)
          end

          if accessor.include?('ago')
            if candle = instrument.send(accessor)
              aggregate.send "#{accessor.remove '_ago'}_vol=", candle.volatility.to_f.round(3)
            end
          end
        end
      end

      if analyze
        analyzer = CandleAnalyzer.new(instrument, date)
        aggregate.days_up = analyzer.green_days_count&.nonzero? || -analyzer.red_days_count.to_i

        if lowest_day = analyzer.lowest_day_since(3.months.ago)
          aggregate.lowest_day_date = lowest_day.date
          aggregate.lowest_day_gain = instrument.gain_since(lowest_day.range_low).to_f.round(3)
        end
      end

      aggregate.save!
      current.where(ticker: instrument.ticker).where('date < ?', date).update_all current: false
    end

    def create_for_all
      instruments = Instrument.all.abc
      Current.preload_prices_for instruments
      # Current.preload_day_candles_for instruments
      instruments.each { |instrument| create_for instrument, date: Current.date }
    end
  end
end


__END__

Aggregate.create_for_all
Aggregate.create_for Instrument['AA'], date: Date.current
Aggregate.create_for Instrument['AA'], date: Date.new(2021, 03, 30)
