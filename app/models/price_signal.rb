class PriceSignal < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  class << self
    def analyze_all
      instruments = Instrument.all.abc
      Current.preload_prices_for instruments
      instruments.each { |instrument| analyze instrument, Current.yesterday }
    end

    def analyze(instrument, date)
      instrument = Instrument[instrument]
      date = date.to_date

      today = instrument.candles.day.find_date(date)
      yesterday = today&.previous
      return unless today && yesterday

      if match = today.absorb?(yesterday, 0.05)
        puts "Detect outside-bar on #{date} for #{instrument}"
        create! instrument: instrument, date: today.date, base_date: yesterday.date,
          kind: 'outside-bar',
          direction: today.direction,
          accuracy: (today.spread / yesterday.spread).to_f.round(2),
          exact: match == true
      end

      # if today.pin_bar?
      #   create! instrument: instrument, date: today.date,
      #     kind: 'pin-bar',
      #     direction: today.direction
      # end
    end
  end
end
