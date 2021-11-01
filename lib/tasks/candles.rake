namespace :m1 do
  envtask :load do
    period = '2021-06-01'.to_date .. Current.yesterday
    tickers = %w[DK FANG CLF X MAC M HRTX ATRA]
    tickers.each do |ticker|
      MarketCalendar.open_days(period).each { |date| Iex.import_intraday_candles(ticker, date) }
    end
  end
end


namespace :m3 do
  envtask :load do
    R.instruments_from_env!.abc.each do |inst|
      Tinkoff.import_intraday_candles_for_dates(inst, '3min',  dates: MarketCalendar.open_days(10.days.ago))
    end
  end
end

namespace :intraday do
  envtask :sync do
    last_synced_interval = nil
    loop do
      duration = 3
      interval = "#{duration}min"
      intervals_since_midnight = (Time.current.hour * 60 + Time.current.min / duration)

      next if last_synced_interval != nil && Time.current.sec < 50

      if last_synced_interval != intervals_since_midnight
        puts "Sync M#{duration}..."
        InstrumentSet[:trading].instruments.each do |inst|
          Tinkoff.import_intraday_candles inst, interval
          PriceSignal.analyze_intraday_for inst, interval
        end
        last_synced_interval = intervals_since_midnight
      end

      sleep 10
    end
  end
end

namespace :candles do
  envtask :set_prev_closes do
      klasses = [Candle]
      klasses = [Candle::H1, Candle::M1, Candle::M3, Candle::M5, Candle::DayTinkoff]
      klasses.each do |klass|
        klass.where(prev_close: nil).includes(:instrument).find_in_batches do |candles|
          klass.transaction do
            candles.each do |candle|
              puts "#{candle.class} #{candle.ticker}"
              candle.update! prev_close: candle.previous&.close unless candle.prev_close
            end
          end
        end
      end
  end

  envtask(:set_average_volume)  { Stats.find_each &:set_average_volume  }
  envtask(:set_average_change)  { Stats.find_each &:set_average_change  }
  envtask(:set_d5_money_volume) { Stats.find_each &:set_d5_money_volume }
end


__END__
r candles:set_prev_closes
r candles:set_average_change
r m3:load tickers='CLF DK'
