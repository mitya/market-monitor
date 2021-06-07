class ReplaceTinkoffCandlesWithIex
  include StaticService

  def call
    Current.parallelize_instruments(Instrument.usd.abc, 4) do |instrument|
      instrument.candles.day.tinkoff.where('date > ?', '2021-01-01').find_each do |candle|
        next if candle.instrument.iex_ticker == nil
        imported = Iex.import_day_candles(instrument, date: candle.date)
        candle.destroy unless imported
      end
    end
  end
end

__END__
