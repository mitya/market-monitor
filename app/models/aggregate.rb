class Aggregate < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  store_accessor :data, :change
  store_accessor :data, :volatility

  Accessors = %w[d1 d2 d3 d4 d5 d6 d7 w1 w2 m1].map { |p| "#{p}_ago" } + %w[y2021]

  class << self
    def create_for(instrument, date)
      puts "Aggregate data on #{date} for #{instrument}"
      aggregate = find_or_initialize_by instrument: instrument, date: date, current: true
      Accessors.each do |accessor|
        if candle = instrument.send(accessor)
          aggregate.send "#{accessor.delete '_ago'}_vol=", candle.volatility.to_f.round(3)
        end
      end

      Accessors.each do |accessor|
        price = instrument.send("#{accessor}_open")
        base_price = instrument.base_price
        if price && base_price
          ratio = price / base_price - 1.0
          aggregate.send "#{accessor.delete '_ago'}=", ratio.to_f.round(3)
        end
      end

      aggregate.save!
    end

    def create_for_all
      instruments = Instrument.all.abc
      Current.preload_day_candles_for instruments

      instruments.each do |instrument|
        create_for instrument, Current.date
      end
    end
  end
end


__END__

Aggregate.create_for_all
Aggregate.create_for Instrument['AA'], Date.current
Aggregate.create_for Instrument['AA'], Date.new(2021, 03, 30)
