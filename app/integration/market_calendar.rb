class MarketCalendar
  class Local
    def initialize(market = :rub)
      @key = @market = @currency = market.to_sym
      @exchange_code = @key == :rub ? :Moex1 : :US
    end

    def us? = @key == :usd
    def ru? = @key == :rub

    def date = Time.now.to_date
    def last_day = @last_day ||= Candle.maximum(:date)
    def prev_day(base_date = last_day, n: 1)
      return MarketCalendar.prev(base_date, @market) if n == 1

      result = base_date
      n.times { result = MarketCalendar.prev(result, @market) }
      result
    end

    def yesterday = closest_weekday(date.prev_weekday, @market)
    def d2_ago    = closest_weekday(yesterday.prev_weekday)
    def d3_ago    = closest_weekday(d2_ago.prev_weekday)
    def d4_ago    = closest_weekday(d3_ago.prev_weekday)
    def d5_ago    = closest_weekday(d4_ago.prev_weekday)
    def d6_ago    = closest_weekday(d5_ago.prev_weekday)
    def d7_ago    = closest_weekday(d6_ago.prev_weekday)
    def d10_ago   = closest_weekday(d7_ago.prev_weekday.prev_weekday.prev_weekday)
    def m1_ago    = closest_weekday(1.month.ago.to_date)
    def m3_ago    = closest_weekday(3.month.ago.to_date)
    def y1_ago    = closest_weekday(1.year.ago.to_date)

    alias today date
    alias d0_ago today
    alias d1_ago yesterday
    alias w1_ago d5_ago
    alias w2_ago d10_ago
    alias week_ago w1_ago
    alias year_ago y1_ago
    alias month_ago m1_ago

    def est = Time.find_zone!('Eastern Time (US & Canada)')
    def msk = Time.find_zone!('Moscow')
    def timezone = @timezone ||= ru? ? msk : est
    def time = timezone.now
    def time_str = time.to_s(:time)

    def opening_time_str = MarketInfo::OpeningTimes[@exchange_code]
    def closing_time_str = MarketInfo::ClosingTimes[@exchange_code]

    def holiday?(date) = MarketCalendar.holiday?(date, @currency)
    def open_on?(date = self.date) = date.on_weekday? && !holiday?(date)
    def open? = open_on?(date) && time.to_s(:time).between?(opening_time_str, closing_time_str)
    def closed? = !open?

    def open_days(since, till = Current.date)
      since, till = since.begin, since.end if since.is_a?(Range)
      (since.to_date .. till.to_date).select { open_on? _1 }
    end

    def method_missing(method, *args, &block)
      Current.send(method, *args, &block)
    end

    delegate :closest_weekday, to: MarketCalendar
  end


  class << self
    def ru = @ru ||= Local.new(:rub)
    def us = @us ||= Local.new(:usd)

    def for(market)
      symbol = determine_market(market)
      return us if symbol == :us
      return ru if symbol == :ru
      return ru if symbol == :eu
    end

    MARKET_SYMBOLS = {
      :rub =>  :ru,
      :ru  =>  :ru,
      'ru' =>  :ru,
      'rub' => :ru,
      'RUB' => :ru,
      :usd =>  :us,
      :us  =>  :us,
      'us' =>  :us,
      'usd' => :us,
      'USD' => :us,

      :eur =>  :eu,
      :eu  =>  :eu,
      'eu' =>  :eu,
      'eur' => :eu,
      'EUR' => :eu,
    }
    def determine_market(something)
      return MARKET_SYMBOLS[something] if MARKET_SYMBOLS[something]
      something.respond_to?(:currency) ? MARKET_SYMBOLS[something.currency] : nil
    end

    def normalize_market(something)
      MARKET_SYMBOLS[something]
    end

    def closest_weekday(date, currency = nil)
      date.wday == 0           ? closest_weekday(date - 2, currency) :
      date.wday == 6           ? closest_weekday(date - 1, currency) :
      holiday?(date, currency) ? closest_weekday(date - 1, currency) :
      date
    end
    alias prev_closest_weekday closest_weekday

    def next_closest_weekday(date, currency = nil)
      date.wday == 0           ? next_closest_weekday(date + 1) :
      date.wday == 6           ? next_closest_weekday(date + 2) :
      holiday?(date, currency) ? next_closest_weekday(date + 1) :
      date
    end

    def market_open?(date, currency = nil)
      date.on_weekday? && !holiday?(date, currency)
    end

    def holiday?(date, currency = nil)
      return nyse_holidays.include?(date) if currency && currency.to_sym == :usd
      return moex_holidays.include?(date) if currency && currency.to_sym == :rub
      false
    end

    def prev(date = Date.current, currency = nil) = prev_closest_weekday(date.to_date.yesterday, currency)
    def next(date = Date.current, currency = nil) = next_closest_weekday(date.to_date.tomorrow, currency)
    def prev2(date) = [prev(date), prev(prev date)]

    def open_days(since, till = Current.date, currency: nil)
      since, till = since.begin, since.end if since.is_a?(Range)
      (since.to_date .. till.to_date).map { |date| market_open?(date, currency) ? date : nil }.compact
    end

    def nyse_holidays
      @nyse_holidays ||= %w[
        2020-01-01
        2020-01-20
        2020-02-17
        2020-04-10
        2020-05-25
        2020-07-03
        2020-09-07
        2020-11-26
        2020-12-25

        2021-01-01
        2021-01-18
        2021-02-15
        2021-04-02
        2021-05-31
        2021-07-05
        2021-09-06
        2021-11-25
        2021-12-24

        2022-01-17
        2022-02-21
        2022-04-15
        2022-05-30
        2022-06-20
        2022-07-04
        2022-09-05
        2022-12-26
      ].map { |str| Date.parse str }.to_set
    end

    def moex_holidays
      @moex_holidays ||= %w[
        2022-05-10
        2022-05-09
        2022-05-03
        2022-05-02
        2022-01-07

        2021-12-31
        2021-11-04
        2021-05-03
        2021-03-08
        2021-02-23
        2021-01-07

        2020-12-31
      ].map { |str| Date.parse str }.to_set
    end

    def periods
      (0 .. Current.date.month.pred).map { |n| Current.ytd + n.months }.map { |day| day.beginning_of_month .. day.end_of_month }
    end

    def special_dates
      # 2017-01-03
      # 2018-01-03
      # 2019-01-03
      # 2020-01-03
      # 2021-01-04
      @special_dates ||= %w[
        2020-02-19
        2020-03-23
        2020-11-06
        2021-05-12
        2021-08-20
        2021-09-21
        2021-10-26
      ].map(&:to_date).sort.reverse
    end

    def current_special_dates
      @current_special_dates ||= %w[
        2020-03-23
        2020-11-06
        2021-05-12
        2021-08-20
        2021-09-21
        2021-10-26
      ].map(&:to_date).sort.reverse
    end

    def current_recent_years
      Aggregate::Years
    end

    def periods_between(start_time, end_time, step = 1.minute)
      return [] if !start_time || !end_time
      periods = []
      current_time = start_time
      while current_time <= end_time
        periods << current_time
        current_time += step
      end
      periods
    end

  end

  class SpecialDates
    include StaticService

    def dates
      [
        Current.y2017,
        Current.y2018,
        Current.y2019,
        Current.y2020,
        Current.y2021,
        Current.y2022,
        Current.date,
        Current.d1_ago,
        Current.d2_ago,
        Current.d3_ago,
        Current.d4_ago,
        Current.w1_ago,
        Current.w2_ago,
        Current.m1_ago,
        Current.m3_ago,
        Current.y1_ago,
      ]
    end

    def dates_plus
      dates + []
    end
  end
end

__END__



Time.new(2000, 1, 1, 12)
MarketCalendar.periods_between instr('gazp').candles_for('1min').today.find_by(time: '12:00'), instr('gazp').candles_for('1min').today.find_by(time: '13:00')
MarketCalendar.periods_between Time.utc(2000, 1, 1, 12), Time.utc(2000, 1, 1, 15)
