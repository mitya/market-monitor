class Candle
  class Intraday < Candle
    ValidIntervals = %w[hour 5min 3min 1min]

    scope :openings, -> { where is_opening: true }
    scope :closings, -> { where is_closing: true }

    def previous = time && siblings.find_by(date: date, time: time - interval_duration)
    def whatever_previous = siblings.where(date: date).where('time < ?', time).order(:time).last

    def to_s = "<#{ticker}:#{interval}:#{date}T#{hhmm}>"
    def to_full_s = "#{to_s} #{ohlc_str} P#{prev_close} #{close_change} #{rel_close_change}"

    def datetime = instrument.time_zone.parse("#{date} #{hhmm}")
    # def hhmm = time_before_type_cast.first(5)
    def hhmm = time.strftime('%H:%M')

    def interval_duration_in_mins = interval_duration / 60
    def interval_index = (time.hour * 60 + time.min) / interval_duration_in_mins
    def interval_indexes_between(other) = other ? other.interval_index.upto(interval_index).to_a[1...-1] : []
    def times_between(other) = interval_indexes_between(other).map { self.class.interval_index_to_time _1, interval_duration_in_mins }

    def is_closing! = update!(is_closing: true)
    def is_opening! = update!(is_opening: true)

    def change_since_open     = cached_instrument.today_open && (close - cached_instrument.today_open)
    def rel_change_since_open = cached_instrument.today_open && (close - cached_instrument.today_open / cached_instrument.today_open)
    def up_since_open? = change_since_open.to_f >= 0

    class << self
      def intraday? = true

      def interval_index_to_time(index, interval_duration_in_mins)
        mins_since_midnight = index * interval_duration_in_mins
        hours, mins = mins_since_midnight.divmod(60)
        "#{hours.to_s.rjust(2, '0')}:#{mins.to_s.rjust(2, '0')}"
      end

    end
  end

  class H1 < Intraday
    self.table_name = "candles_h1"
  end

  class M5 < Intraday
    self.table_name = "candles_m5"
  end

  class M3 < Intraday
    self.table_name = "candles_m3"
  end

  class M1 < Intraday
    self.table_name = "candles_m1"
  end

  class DayTinkoff < Candle
    self.table_name = "candles_d1_tinkoff"
  end
end
