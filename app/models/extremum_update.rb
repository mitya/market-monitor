class ExtremumUpdate < ApplicationRecord
  belongs_to :instrument_record, foreign_key: 'ticker', class_name: 'Instrument'
  scope :new_lows, -> { where kind: 'low' }
  scope :new_highs, -> { where kind: 'high' }

  def instrument = PermaCache.instrument(ticker)
  def candle = instrument.day_candles!.find_date(date)

  def new_high? = kind == 'high'
  def new_low? = kind == 'low'

  class << self
    def search_for(instruments = Instrument.active, date: Current.yesterday)
      CandleCache.preload instruments, dates: [date]
      start_date = date - 6.months
      Instrument.normalize(instruments).each do |inst|
        day_candles = inst.day_candles.where('date > ?', start_date)
        older_updates = where(ticker: inst.ticker).where('date > ?', start_date)

        if candle = inst.day_candles!.find_date(date)
          if not day_candles.where('high > ?', candle.high).exists?
            find_or_create_by! ticker: inst.ticker, date: date, price: candle.high, kind: 'high', volume: candle.volume
          end
          if not day_candles.where('low < ?', candle.low).exists?
            find_or_create_by! ticker: inst.ticker, date: date, price: candle.low, kind: 'low', volume: candle.volume
          end

          # if not older_updates.new_highs.where('high > ?', candle.high).exists?
          #   create! ticker: inst.ticker, date: date, price: candle.high, kind: 'high', volume: candle.volume
          # end
          # if not older_updates.new_lows.where('low < ?', candle.low).exists?
          #   create! ticker: inst.ticker, date: date, price: candle.low, kind: 'low', volume: candle.volume
          # end
        end
      end
    end
  end
end

__END__

MarketCalendar.ru.open_days('2022-01-01').each { |date| ExtremumUpdate.search_for(Instrument.active.rub, date: date) }
MarketCalendar.us.open_days('2022-01-01').each { |date| ExtremumUpdate.search_for(Instrument.active.usd, date: date) }

ExtremumUpdate.search_for(Instrument.active.usd, date: '2022-05-11'.to_date)
