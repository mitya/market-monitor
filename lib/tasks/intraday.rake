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
      # tickers = Setting.get('sync_tickers', [])
      
      
      intervals_since_midnight = (Time.current.hour * 60 + Time.current.min) / duration

      next if last_synced_interval != nil && Time.current.sec < 50

      if last_synced_interval != intervals_since_midnight
        instruments.abc.each do |inst|
          Tinkoff.import_intraday_candles inst, interval
          PriceSignal.analyze_intraday_for inst, interval if analyze
        end
        puts
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
  
  def check_moex_closings
    moex_1 = []
    moex_2 = []
    Instrument.rub.abc.each do |inst|
      data = Tinkoff.load_intervals inst, '1min', '2022-02-02T22:00:00+03:00'.to_time, '2022-02-02T22:01:00+03:00'.to_time
      if data['candles'].any?
        moex_1 << inst.ticker
        puts "\t #{inst}"
      else
        puts inst
        moex_2 << inst.ticker
      end
    end    
    
    puts "1st: #{moex_1.join(' ')}"
    puts "2nd: #{moex_2.join(' ')}"
  end
  
  private
  
  def days_to_load = ENV['days'].to_i.nonzero? || 8
  def recent_dates = MarketCalendar.open_days(days_to_load.days.ago).last(5)
  
  CLOSE_TIMES = { 
    '16:00' => { 1 => '15:59', 3 => '15:57', 5 => '15:55', 60 => '15:00' },
    '23:50' => { 1 => '23:49', 3 => '23:48', 5 => '23:45', 60 => '23:00' },
    '18:45' => { 1 => '18:45', 3 => '18:45', 5 => '18:45', 60 => '18:00' },
  }  
end



namespace :intraday do
  envtask(:sync) { IntradayCandleLoader.new.sync }
  envtask(:load) { IntradayCandleLoader.new.load }
  
  envtask(:check_moex_closings) { IntradayCandleLoader.new.check_moex_closings }
end



__END__
rake intraday:load tickers='AGRO' period=3 force=1 days=1
rake intraday:sync tickers='OZON SBER GAZP FIVE MVID' period=3
