class MarketCalendar
  class << self
    def closest_weekday(date)
      date.wday == 0 ? date - 2 :
      date.wday == 6 ? date - 1 :
      date
    end
  end
end
