namespace :candles do
  envtask :set_prev_closes do
      klasses = [Candle]
      # klasses = [Candle::H1, Candle::M1, Candle::M3, Candle::M5, Candle::DayTinkoff]
      klasses.each do |klass|
        klass.where('date >= ?', '2021-12-01').includes(:instrument).find_in_batches do |candles|
          klass.transaction do
            candles.each do |candle|
              puts "#{candle.class} #{candle.ticker}"
              candle.update! prev_close: candle.previous&.close # unless candle.prev_close
            end
          end
        end
      end
  end

  envtask(:set_average_volume)          { Instrument.transaction { Instrument.active.find_each { _1.info.set_average_volume }}}
  envtask(:set_average_change)          { Instrument.transaction { Instrument.active.find_each { _1.info.set_average_change }}}
  envtask(:set_d5_volume)               { Instrument.transaction { Instrument.active.find_each { _1.info.set_d5_volume }}}
  envtask(:set_average_intraday_volume) { Instrument.transaction { Instrument.active.find_each { _1.info.set_average_1min_volume }}}
end


__END__
r candles:set_prev_closes
r candles:set_average_change
r m3:load tickers='CLF DK'
