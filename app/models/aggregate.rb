class Aggregate < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :current, -> { where current: true }

  Accessors = %w[d1 d2 d3 d4 w1 w2 m1].map { |p| "#{p}_ago" } + %w[y2021 nov06 mar23 feb19 y2020 y2019 y2018 y2017]

  def days_down = days_up.to_i > 0 ? 0 : -days_up

  def lowest_day = lowest_day_date && instrument.day_candles.find_date(lowest_day_date)
  def lowest_day_low = lowest_day&.low

  class << self
    def create_for(instrument, date: Current.yesterday, gains: true, analyze: true, volume: true, force: true)
      puts "Aggregate data on #{date} for #{instrument}"
      aggregate = find_or_initialize_by instrument: instrument, date: date
      return if aggregate.persisted? && !force

      day_candle = instrument.day_candles!.find_date(date)
      aggregate.close = day_candle&.close
      aggregate.close_change = instrument.on_close_change(date: MarketCalendar.prev(date))

      if gains && date == Current.yesterday
        Accessors.each do |accessor|
          suffix = 'low'
          suffix = 'open' if accessor =~ /y\d{4}/
          suffix = 'close' if accessor =~ /\w\d_ago/
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

      if volume && date == Current.yesterday
        %w[d1 d2 d3 d4 w1 w2 m1].map { |p| "#{p}_ago" }.each do |accessor|
          if candle = instrument.send(accessor)
            aggregate.send "#{accessor.remove '_ago'}_volume=", candle.volume_to_average.to_f.round(3)
          end
        end
      end

      if analyze
        analyzer = CandleAnalyzer.new(instrument, date)
        aggregate.days_up = analyzer.days_up_count&.nonzero? || -analyzer.days_down_count.to_i

        if lowest_day = analyzer.lowest_day_since(3.months.ago)
          aggregate.lowest_day_date = lowest_day.date
          aggregate.lowest_day_gain = instrument.gain_since(lowest_day.range_low).to_f.round(3)
        end
      end

      aggregate.save!
    end

    def create_for_all(date: Current.date, instruments: Instrument.all, **options)
      instruments = instruments.sort_by &:ticker
      Current.preload_prices_for instruments
      Current.parallelize_instruments(instruments, 6) { |inst| create_for inst, date: date, **options }
    end

    def set_current(date = Current.yesterday)
      current.where('date < ?', date).update_all current: false
      where('date = ?', date).update_all current: true
    end
  end
end


__END__

Aggregate.create_for_all
Aggregate.create_for Instrument['AA'], date: Date.current
Aggregate.create_for Instrument['AA'], date: Date.new(2021, 03, 30)



MarketCalendar.open_days(4.months.ago, Date.yesterday).each do |date|
  Aggregate.create_for Instrument['AAPL'], date: date, gains: false, analyze: false, volume: false
end

MarketCalendar.open_days(2.months.ago, Date.yesterday).each do |date|
  Aggregate.create_for_all date: date
end

MarketCalendar.open_days(1.week.ago, Date.yesterday).each   { |date| Aggregate.create_for_all date: date, instruments: Instrument.all }

MarketCalendar.open_days(4.months.ago, Date.yesterday).each { |date| Aggregate.create_for_all date: date, instruments: Instrument.all }
Aggregate.set_current
