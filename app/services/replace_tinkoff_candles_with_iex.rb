class ReplaceTinkoffCandlesWithIex
  include StaticService

  def call
    Current.parallelize_instruments(Instrument.usd.abc, 4) do |instrument|
      instrument.candles.day.tinkoff.where('date > ?', '2021-01-01').find_each do |candle|
        next if not candle.instrument.iex_ticker
        if Iex.import_day_candles(instrument, date: candle.date) == nil
          candle.destroy
        end
      end
    end
  end
end

__END__
