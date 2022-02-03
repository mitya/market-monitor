class IntradayCandleLoader
  attr_reader :instruments, :interval, :duration
  
  def initialize
    @instruments = R.instruments_from_env || InstrumentSet[:trading].scope
    @duration = (ENV['period'] || '3').to_i
    @interval = Candle.minutes_to_interval(duration)
  end
  
  def sync
    analyze = ENV['analyze'] == '1'

    load_previous

    last_synced_interval = nil
    loop do
      intervals_since_midnight = (Time.current.hour * 60 + Time.current.min) / duration

      next if last_synced_interval != nil && Time.current.sec < 50

      if last_synced_interval != intervals_since_midnight
        puts "Sync #{interval}..."
        instruments.each do |inst|
          Tinkoff.import_intraday_candles inst, interval
          PriceSignal.analyze_intraday_for inst, interval if analyze
        end
        last_synced_interval = intervals_since_midnight
      end

      sleep 10
    end
  end
  
  def load
    instruments.abc.each do |inst|
      dates = recent_dates
      last = Candle.interval_class_for(interval).where(ticker: inst.ticker).order(:date, :time).last
      dates.reject! { |date| date < last.date } if last unless ENV['force']
      Tinkoff.import_intraday_candles_for_dates(inst, interval,  dates: dates)
    end
  end
  
  def load_previous
    instruments.abc.each do |inst|
      dates = recent_dates - [Current.date]
      close_time = CLOSE_TIMES[inst.close_hhmm][duration]
      dates.each do |date|
        unless Candle.interval_class_for(interval).exists?(ticker: inst.ticker, date: date, time: close_time)
          Tinkoff.import_intraday_candles_for_dates(inst, interval, dates: [date])
        end        
      end
    end    
  end
  
  private
  
  def recent_dates = MarketCalendar.open_days(8.days.ago).last(5)
  
  CLOSE_TIMES = { 
    '16:00' => { 1 => '15:59', 3 => '15:57', 5 => '15:55', 60 => '15:00' },
    '00:00' => { 1 => '23:59', 3 => '23:57', 5 => '23:55', 60 => '23:00' },
    '18:40' => { 1 => '18:39', 3 => '18:37', 5 => '18:35', 60 => '18:00' },
  }  
end



namespace :intraday do
  envtask(:sync) { IntradayCandleLoader.new.sync }
  envtask(:load) { IntradayCandleLoader.new.load }
end



__END__
rake intraday:load tickers='OZON SBER GAZP FIVE' period=1 force=1
rake intraday:sync tickers='OZON SBER GAZP FIVE' period=1
