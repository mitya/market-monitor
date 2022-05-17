class Current < ActiveSupport::CurrentAttributes
  attribute :ticker_sets

  # def date
  #   date = Time.now.hour > 20 ? Date.tomorrow : Date.current
  #   date.on_weekend?? date.prev_weekday : date
  # end

  def date = Time.now.to_date
  def last_day = @last_day ||= Candle.maximum(:date)
  def prev_day = MarketCalendar.prev(last_day, :rub)

  def ytd = date.beginning_of_year
  def est = Time.find_zone!('Eastern Time (US & Canada)')
  def msk = Time.find_zone!('Moscow')
  def ru_time = msk.now
  def us_time = est.now
  def us_date = us_time.to_date
  def us_market_open? = date.on_weekday? && us_time.to_s(:time) >= '09:30'
  def uk_market_open? = date.on_weekday? && Time.current.to_s(:time) >= '11:00'
  def ru_market_open? = workday?(:rub) && Time.current.to_s(:time).between?('10:00', '19:00')
  def ru_market_open_time = ru_time.change(hour: 7).utc
  def weekend? = us_date.on_weekend? # || MarketCalendar.nyse_holidays.include?(us_date)
  def workday?(currency = nil) = MarketCalendar.market_open?(Date.current, currency)
  def zero_day = Time.utc(2000)

  def us_market_open_time      = Current.us_time.change(hour:  9, min: 30)
  def us_market_close_time     = Current.us_time.change(hour: 16, min: 00)
  def ru_premarket_open_time   = Current.ru_time.change(hour:  7, min: 00)
  def ru_market_open_time      = Current.ru_time.change(hour: 10, min: 00)
  def ru_market_close_time     = Current.ru_time.change(hour: 23, min: 50)
  def ru_2nd_market_open_time  = Current.ru_time.change(hour: 10, min: 00)
  def ru_2nd_market_close_time = Current.ru_time.change(hour: 18, min: 45)
  def us_market_work_period     = us_market_open_time..us_market_close_time
  def ru_market_work_period     = ru_market_open_time..ru_market_close_time
  def ru_2nd_market_work_period = ru_2nd_market_open_time..ru_2nd_market_close_time


  def yesterday = MarketCalendar.closest_weekday(date.prev_weekday, :rub)
  def d2_ago    = MarketCalendar.closest_weekday(yesterday.prev_weekday)
  def d3_ago    = MarketCalendar.closest_weekday(d2_ago.prev_weekday)
  def d4_ago    = MarketCalendar.closest_weekday(d3_ago.prev_weekday)
  def d5_ago    = MarketCalendar.closest_weekday(d4_ago.prev_weekday)
  def d6_ago    = MarketCalendar.closest_weekday(d5_ago.prev_weekday)
  def d7_ago    = MarketCalendar.closest_weekday(d6_ago.prev_weekday)
  def d10_ago   = MarketCalendar.closest_weekday(d7_ago.prev_weekday.prev_weekday.prev_weekday)
  def m1_ago    = MarketCalendar.closest_weekday(1.month.ago.to_date)
  def m3_ago    = MarketCalendar.closest_weekday(3.month.ago.to_date)
  def y1_ago    = MarketCalendar.closest_weekday(1.year.ago.to_date)
  def y2017     = Date.new(2017,  1,  3)
  def y2018     = Date.new(2018,  1,  3)
  def y2019     = Date.new(2019,  1,  3)
  def y2020     = Date.new(2020,  1,  3)
  def y2021     = Date.new(2021,  1,  4)
  def y2022     = Date.new(2022,  1,  3)

  alias today date
  alias d0_ago today
  alias d1_ago yesterday
  alias w1_ago d5_ago
  alias w2_ago d10_ago
  alias week_ago w1_ago
  alias year_ago y1_ago
  alias month_ago m1_ago

  def us_open_time_in_minutes_utc = 13 * 60 + 30

  def last_closed_day = workday? ? yesterday : today
  def last_closed_day_as_iex = yesterday

  def weekdays_since(date) = date.upto(Current.today).to_a.select { |date| MarketCalendar.market_open?(date) }.reverse
  def last_n_weeks(n) = weekdays_since(n.weeks.ago.to_date)
  def last_2_weeks = last_n_weeks(2)



  def in_usd(amount, currency)
    return unless amount
    case currency
    when 'USD' then amount
    when 'EUR' then amount * 1.2
    when 'RUB' then amount / 74
    end
  end



  def parallelize(threads_count, &block)
    threads_count.times.map { |i| Thread.new(&block) }.each &:join
  end

  def parallelize_instruments(instruments, threads_count, &block)
    queue = instruments.to_a
    threads_count.times.map do |index|
      Thread.new do
        while instr = queue.shift
          yield instr, index
        end
      end
    end.each &:join
  end
end
