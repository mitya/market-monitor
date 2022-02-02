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
  
  envtask :load do
    instruments = R.instruments_from_env || InstrumentSet[:trading].scope
    period = ENV['PERIOD'] || '3min'
    instruments.abc.each do |inst|
      dates = MarketCalendar.open_days(8.days.ago).last(5)
      last = Candle.interval_class_for(period).where(ticker: inst.ticker).order(:date, :time).last
      dates.reject! { |date| date < last.date } if last
      Tinkoff.import_intraday_candles_for_dates(inst, period,  dates: dates)
    end
  end
end

__END__

rake intraday:load
