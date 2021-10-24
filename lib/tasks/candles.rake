namespace :m1 do
  envtask :load do
    tickers = %w[DK FANG CLF X MAC M HRTX ATRA]
    tickers = %w[DK FANG CLF]
    period = '2021-06-01'.to_date .. Current.yesterday

    tickers.each do |ticker|
      MarketCalendar.open_days(period).each { |date| Iex.import_intraday_candles(ticker, date) }
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
            candles.each { |candle| candle.update! prev_close: candle.previous&.close unless candle.prev_close }
          end
        end
      end
  end

  envtask(:set_average_volume)  { Stats.find_each &:set_average_volume  }
  envtask(:set_average_change)  { Stats.find_each &:set_average_change  }
  envtask(:set_d5_money_volume) { Stats.find_each &:set_d5_money_volume }
end


__END__
rake candles:set_prev_closes
