class MarketCalendar
  class << self
    def closest_weekday(date)
      date.wday == 0          ? closest_weekday(date - 2) :
      date.wday == 6          ? closest_weekday(date - 1) :
      date.in?(nyse_holidays) ? closest_weekday(date - 1) :
      date
    end

    def nyse_holidays
      @nyse_holidays ||= %w[
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
