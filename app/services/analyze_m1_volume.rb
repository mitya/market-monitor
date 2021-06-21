class AnalyzeM1Volume
  include StaticService

  def call
    instruments = R.instruments_from_env || Instrument.where(Candle::M1.distinct.pluck(:ticker))
    instruments.each do |i|
      info = i.info!
      average_volume = info.avg_m1_volume
      printf "%-6s %12s %10.2f$ %15s$\n", i.ticker, average_volume.to_s(:delimited), i.price.value, (i.price.value.to_f * average_volume).to_i.to_s(:delimited)
    end
    puts

    last_date = nil

    instruments.each do |i|
      i.m1_candles.order(:date, :time).
          where('volume > ?', i.info.avg_m1_volume.to_i * 3).
          # where('time >= ?', '10:00').
          # where('time <= ?', '15:30').
          each do |candle|
        puts if last_date != candle.date
        last_date = candle.date
        date_time = "#{candle.date} #{candle.time.to_s :time}"
        volume_increase = candle.volume / i.info.avg_m1_volume.to_f
        volume_chart = '|' * [volume_increase, 100].min
        change_percent = candle.rel_change * 100
        change_chart = '|' * (change_percent / 0.1).abs
        color = change_percent >= 0 ? :green : :red
        printf "%-6s %s %4.0fx %10s %6.2f%% %10s %8.2f$ %-s\n".send(color), i.ticker, date_time, volume_increase, candle.volume.to_s(:delimited), change_percent, change_chart, candle.close, volume_chart
      end
    end
  end
end
