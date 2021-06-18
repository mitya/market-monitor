class MarketCalendar
  class << self
    def closest_weekday(date)
      date.wday == 0          ? closest_weekday(date - 2) :
      date.wday == 6          ? closest_weekday(date - 1) :
      date.in?(nyse_holidays) ? closest_weekday(date - 1) :
      date
    end

    def market_open?(date)
      date.on_weekday? && !nyse_holidays.include?(date)
    end

    def prev(date)
      closest_weekday date.yesterday
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
  end
end
