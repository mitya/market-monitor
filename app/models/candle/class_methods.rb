class Candle
  IntervalShorthands = {
     1   => '1min',   3  => '3min',   5  => '5min',  60  => 'hour',
    '1'  => '1min',  '3' => '3min',  '5' => '5min', '60' => 'hour',
    '1m' => '1min', '3m' => '3min', '5m' => '5min', '1h' => 'hour', '1d' => 'day'
  }

  IntervalDurations = { 'day' => 1.day, 'hour' => 1.hour, '5min' => 5.minutes, '3min' => 3.minutes, '1min' => 1.minute }
  IntervalClasses = { 'day' => self, 'hour' => H1, '5min' => M5, '3min' => M3, '1min' => M1 }
  ClassIntervals = IntervalClasses.invert

  module ClassMethods
    def find_date_before(date)    = order(date: :desc).where('date <  ?', date.to_date).take
    def find_date_or_before(date) = order(date: :desc).where('date <= ?', date.to_date).take
    def find_date_or_after(date)  = order(date: :asc) .where('date >= ?', date.to_date).take
    def find_date(date)        = for_date(date).take
    def find_dates_in(period)  = where(date: period)

    def last_loaded_date = final.maximum(:date)
    def intraday? = false

    def interval = ClassIntervals[self]
    def normalize_interval(interval)    = IntervalShorthands[interval] || interval
    def interval_duration_for(interval) = IntervalDurations[interval]
    def interval_class_for(interval)    = IntervalClasses[normalize_interval interval]
    def interval_duration = interval_duration_for(interval)
    def interval_duration_in_mins(interval) = interval_duration_for(interval).to_i / 60

    def remove_dups
      iex.find_each do |candle|
        exist = logger.silence do
          day.where.not(id: candle.id).where(ticker: candle.ticker, date: candle.date).exists?
        end
        if exist
          day.where.not(id: candle.id).where(ticker: candle.ticker, date: candle.date).delete_all
        end
      end
    end
  end
end
