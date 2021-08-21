class DateIndicators < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  scope :current, -> { where current: true }

  class << self
    def create_for(instrument, date: Current.yesterday)
      candle = instrument.day_candles!.find_date(date) || return
      close = candle.close

      prev = instrument.all_indicators.where('date < ?', date).order(:date).last
      record = find_or_initialize_by ticker: instrument.ticker, date: date
      return if record.persisted?

      {20 => 21, 50 => 55, 200 => 200}.each do |length, real_length|
        accessor = "ema_#{length}"

        if close < 0.01
          record.send "#{accessor}=", close
          record.send "#{accessor}_trend=", 0
          return
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

    def create_for_all(date: Current.yesterday, instruments: Instrument.all)
      instruments = instruments.sort_by &:ticker
      transaction do
        Current.preload_day_candles_for_dates instruments, [date.to_date]
        Current.parallelize_instruments(instruments, 6) { |inst| create_for inst, date: date }
      end
    end

    def set_current(date = Current.yesterday)
      where('date < ?', date).where(current: true).update_all current: false
      where('date = ?', date).update_all current: true
    end

    private def calculate_ema(close, prev_ema, length)
      prev_ema = close if prev_ema.to_d == 0
      smoothing_factor = 2.0 / (length + 1)
      (close - prev_ema) * smoothing_factor + prev_ema
    end
  end
end

__END__
MarketCalendar.open_days(4.month.ago, Date.yesterday).each { |date| DateIndicators.create_for_all date: date, instruments: Instrument.all }
DateIndicators.set_current
