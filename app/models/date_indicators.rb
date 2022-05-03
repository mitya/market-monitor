class DateIndicators < ApplicationRecord
  self.table_name = "indicators"

  belongs_to :instrument, foreign_key: 'ticker'
  scope :current, -> { where current: true }

  def datetime = date.end_of_day
  def charting_timestamp = date.end_of_day.to_time.to_i
  def cached_instrument = InstrumentCache.get(ticker)

  class << self
    def create_recursive(instrument, date: Current.yesterday)
      puts "Update EMAs for #{instrument}"
      last_indicator = instrument.indicators_history.order(:date).where('date < ?', date).last
      MarketCalendar.open_days(last_indicator&.date || 1.year.ago, date).each { |date| create_for instrument, date: date }
    end

    def create_for(instrument, date: Current.yesterday, length_min_dates: nil)
      candle = instrument.day_candles!.find_date(date) || return
      close = candle.close

      prev = instrument.indicators_history.where('date < ?', date).order(:date).last
      record = find_or_initialize_by instrument: instrument, date: date
      return if record.persisted?

      {20 => 20, 50 => 50, 100 => 100, 200 => 200}.each do |length, real_length|
        next if length_min_dates && length_min_dates[length] && date < length_min_dates[length]

        accessor = "ema_#{length}"

        if close < 0.01
          record.send "#{accessor}=", close
          record.send "#{accessor}_trend=", 0
          next
        end

        prev_ema   = prev.try(accessor) || close
        prev_trend = prev.try("#{accessor}_trend") || 0
        record.send "#{accessor}=", calculate_ema(close, prev_ema, real_length)
        record.send "#{accessor}_trend=", close.to_d > record.send(accessor).to_d ?
          (prev_trend > 0 ? prev_trend + 1 :  1) :
          (prev_trend < 0 ? prev_trend - 1 : -1)
      end

      record.save!
    end

    def create_for_all(date: Current.yesterday, instruments: Instrument.active)
      instruments = instruments.sort_by &:ticker
      transaction do
        Current.preload_day_candles_for_dates instruments, [date.to_date]
        Current.parallelize_instruments(instruments, 6) { |inst| create_recursive inst, date: date }
      end
    end

    def set_current(date = DateIndicators.maximum(:date))
      where('date < ?', date).where(current: true).update_all current: false
      where('date = ?', date).update_all current: true
    end

    def recreate_for_all(instruments = Instrument.active)
      # try without the threads at all
      # delete_all
      Current.parallelize_instruments(Instrument.normalize(instruments), 6) { |inst| recreate_for inst }
    end

    def recreate_for(instrument, since: Current.y2019)
      instrument = Instrument[instrument]
      transaction do
        instrument.indicators_history.delete_all
        MarketCalendar.open_days(since, Date.yesterday).each do |date|
          DateIndicators.create_for instrument, date: date, length_min_dates: {
             20 =>  4.months.ago,
             50 =>  9.months.ago,
            100 => 20.months.ago,
          }
        end
        instrument.indicators_history.reload.last.update! current: true
      end
    end

    private def calculate_ema(close, prev_ema, length)
      prev_ema = close if prev_ema.to_d == 0
      smoothing_factor = 2.0 / (length + 1)
      (close - prev_ema) * smoothing_factor + prev_ema
    end
  end

  def last = @last_indicator ||= LastIndicator.new(self)

  class LastIndicator
    attr :prev

    def initialize(prev)
      @prev = prev
      @emas = {}
    end

    def ema_20  = calculate_last_ema(20)
    def ema_50  = calculate_last_ema(50)
    def ema_200 = calculate_last_ema(200)
    def date = Current.date
    def datetime = date.end_of_day
    def charting_timestamp = date.end_of_day.to_time.to_i

    def calculate_last_ema(length)
      @emas[length] ||= begin
        last = prev.cached_instrument.last
        prev_ema = prev.send("ema_#{length}")
        smoothing_factor = 2.0 / (length + 1)
        ((last - prev_ema) * smoothing_factor + prev_ema).round(4)
      end
    end
  end

end

__END__
MarketCalendar.open_days(4.month.ago, Date.yesterday).each { |date| DateIndicators.create_for_all date: date, instruments: Instrument.all }
DateIndicators.set_current
DateIndicators.create_recursive instr('AAPL')
DateIndicators.recreate_for_all %w[RIOT]
