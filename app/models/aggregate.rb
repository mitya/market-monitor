class Aggregate < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :current, -> { where current: true }
  scope :old, -> { where current: false }

  RecentDaySelectors = %w[d1 d2 d3 d4 w1 w2 m1 m3 y1]
  Years = [2022, 2021, 2020, 2019, 2018, 2017]
  Selectors = RecentDaySelectors + Years

  RecentDayAccessors = RecentDaySelectors.map { |p| "#{p}_ago" }
  YearBeginningAccessors = Years.map { |year| "y#{year}" }
  Accessors = RecentDayAccessors + YearBeginningAccessors

  def days_down = days_up.to_i > 0 ? 0 : -days_up

  def lowest_day = lowest_day_date && instrument.day_candles.find_date(lowest_day_date)
  def lowest_day_low = lowest_day&.low

  def gains        = data['gains'] ||= {}
  def volumes      = data['volumes'] ||= {}
  def volatilities = data['volatilities'] ||= {}

  def candle = @candle ||= instrument.candles.day.find_date(date)

  class << self
    def create_for(instrument, date: Current.yesterday, gains: true, analyze: true, volume: true, force: true, year_highs: true)
      puts "Aggregate data on #{date} for #{instrument}"
      aggregate = find_or_initialize_by instrument: instrument, date: date
      return if aggregate.persisted? && !force

      day_candle = instrument.day_candles!.find_date(date)
      close = day_candle&.close
      aggregate.close = close
      aggregate.close_change = instrument.on_close_change(date: MarketCalendar.prev(date))

      return puts "Requested date #{date} != #{Current.yesterday}".red if date != Current.yesterday

      if gains && close
        current = close
        compare_to_current = -> (historic) { (current / historic - 1.0).to_f.round(3) }

        RecentDayAccessors.each do |accessor|
          if historic = instrument.send("#{accessor}_close")
            aggregate.gains[accessor.remove '_ago'] = compare_to_current.(historic)
          end
        end

        MarketCalendar.current_recent_years.each do |year|
          if historic = instrument.send("y#{year}_open")
            aggregate.gains[year] = compare_to_current.(historic)
          end
        end

        MarketCalendar.special_dates.each do |date|
          if historic = instrument.candles.day.find_date(date)&.close
            aggregate.gains[date.to_s] = compare_to_current.(historic)
          end
        end
      end

      if volume
        RecentDayAccessors.each do |accessor|
          if recent = instrument.send(accessor)
            aggregate.volatilities[accessor.remove '_ago'] = recent.volatility.to_f.round(3)
            aggregate.volumes[accessor.remove '_ago']      = recent.volume_to_average.to_f.round(3)
            aggregate.d1_money_volume = recent.volume * instrument.lot * recent.close if accessor == 'd1_ago'
          end
        end
      end

      if analyze
        analyzer = CandleAnalyzer.new(instrument, date)
        aggregate.days_up = analyzer.days_up_count&.nonzero? || -analyzer.days_down_count.to_i
        aggregate.change_map = analyzer.change_map

        if lowest_day = analyzer.lowest_day_since(3.months.ago)
          aggregate.lowest_day_date = lowest_day.date
          aggregate.lowest_day_gain = instrument.gain_since(lowest_day.range_low).to_f.round(3)
        end
      end

      if year_highs && close
        y1_high = instrument.day_candles.where('date >= ?', 1.year.ago.to_date).order(:high).last
        y3_high = instrument.day_candles.where('date >= ?', 3.year.ago.to_date).order(:high).last
        y1_low = instrument.day_candles.where('date >= ?', 1.year.ago.to_date).order(:low).first
        y3_low = instrument.day_candles.where('date >= ?', 3.year.ago.to_date).order(:low).first
        aggregate.y1_high_change = (close / y1_high.high - 1.0).to_f.round(3)
        aggregate.y3_high_change = (close / y3_high.high - 1.0).to_f.round(3)
        aggregate.y1_low_change  = (close / y1_low.low   - 1.0).to_f.round(3)
        aggregate.y3_low_change  = (close / y3_low.low   - 1.0).to_f.round(3)
        aggregate.y1_high_date = y1_high.date
        aggregate.y3_high_date = y3_high.date
        aggregate.y1_low_date  = y1_low.date
        aggregate.y3_low_date  = y3_low.date
      end

      aggregate.save!
    end

    def create_for_all(date: Current.date, instruments: Instrument.active, **options)
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
Aggregate.create_for Instrument['MSFT']
