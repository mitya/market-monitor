class RefreshPricesFromTinkoff
  include StaticService

  def refresh(instruments)
    instruments = Instrument.get_all(instruments).sort_by(&:ticker).reject(&:premium?)
    Current.parallelize_instruments(instruments, 1) { | inst| update_tinkoff_price inst }
    SyncChannel.push 'prices'
  end

  alias call refresh

  private

  def update_tinkoff_price(instrument, **opts)
    instrument = Instrument[instrument]
    response_json = Tinkoff.last_hour_candles instrument, 2.hours.ago

    return puts "Refresh Tinkoff price for #{instrument} failed: #{response_json}".red if response_json['candles'] == nil
    candles = response_json.dig 'candles'
    candle = candles[-1]

    last = candle&.dig 'c'
    low = candles.map { |c| c['l'] }.min
    volume = candles.map { |c| c['v'] }.sum

    printf "Refresh Tinkoff price for %-7s %3i candles last=#{last}\n", instrument.ticker, candles.count
    instrument.price!.update! value: last, last_at: candle['time'], source: 'tinkoff', low: low, volume: volume if last
  end
end
