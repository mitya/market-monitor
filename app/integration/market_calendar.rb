class MarketCalendar
  class << self
    def closest_weekday(date)
      date.wday == 0          ? closest_weekday(date - 2) :
      date.wday == 6          ? closest_weekday(date - 1) :
      date.in?(nyse_holidays) ? closest_weekday(date - 1) :
      date
    end
    alias prev_closest_weekday closest_weekday

    def next_closest_weekday(date)
      date.wday == 0          ? next_closest_weekday(date + 1) :
      date.wday == 6          ? next_closest_weekday(date + 2) :
      date.in?(nyse_holidays) ? next_closest_weekday(date + 1) :
      date
    end

    def market_open?(date)
      date.on_weekday? && !nyse_holidays.include?(date)
    end

    def prev(date) = prev_closest_weekday(date.to_date.yesterday)
    def next(date) = next_closest_weekday(date.to_date.tomorrow)
    def prev2(date) = [prev(date), prev(prev date)]

    def open_days(since, till = Date.current)
      since, till = since.begin, since.end if since.is_a?(Range)
      (since.to_date .. till.to_date).map { |date| market_open?(date) ? date : nil }.compact
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
        2021-12-24
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
      ].map(&:to_date).sort.reverse
    end

    def current_special_dates
      @current_special_dates ||= %w[
        2020-03-23
        2020-11-06
        2021-05-12
        2021-08-20
      ].map(&:to_date).sort.reverse
    end

    def current_recent_years
      [2021, 2020, 2019, 2018, 2017]
    end
  end
end
