class IntradayCandleLoader
  def tickers 
    return R.tickers_from_env if R.tickers_from_env.present?
    
    tickers = Setting.synced_tickers
    tickers += Setting.charted_tickers
    tickers += TickerSet.pluck(:tickers).flatten
    tickers.sort
  end
  def instruments = Instrument.for_tickers(tickers).abc  
  def interval = ENV['period'] || '3min'
  def duration = (Candle.interval_duration(interval) / 60)
  
  def schedule
    loop do
      once_in 10,     :load_intraday
      once_in 5 * 60, :load_prices
    end
  end
  
  def sync
    analyze = ENV['analyze'] == '1'
    last_synced_interval = nil
    last_synced_tickers = nil
    last_prices_update_time = Setting.iex_last_update

    loop do
      current_interval = (Time.current.hour * 60 + Time.current.min) / duration
      current_tickers = tickers      
      puts "tick #{Time.current} - #{current_interval} - last #{last_synced_interval}"

      if last_synced_tickers != current_tickers
        load_history 
        last_synced_tickers = current_tickers
      end

      if last_synced_interval != current_interval
        if (current_interval - last_synced_interval.to_i) != 1 || Time.current.sec > 50
          puts 'sync'
          instruments.abc.each do |inst|
            Tinkoff.import_intraday_candles inst, interval
            PriceSignal.analyze_intraday_for inst, interval if analyze
          end
          last_synced_interval = current_interval
        end        
      end

      if last_prices_update_time < 5.minutes.ago
        RefreshPricesFromIex.refresh 
        puts "Refresh prices from IEX".green
        last_prices_update_time = Time.current
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
  
  def load_history
    puts 'Checking history...'
    instruments.abc.each do |inst|
      dates = recent_dates - [Current.date]
      close_time = CLOSE_TIMES[inst.close_hhmm][duration.to_i]
      missing_dates = dates.reject { |date| Candle.interval_class_for(interval).exists?(ticker: inst.ticker, date: date, time: close_time) }
      missing_dates << Current.date if missing_dates.any?
      Tinkoff.import_intraday_candles_for_dates inst, interval, dates: missing_dates
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
  
  def days_to_load = ENV['days'].to_i.nonzero? || 10
  def recent_dates = MarketCalendar.open_days(days_to_load.days.ago)
  
  CLOSE_TIMES = { 
    '16:00' => { 1 => '15:59', 3 => '15:57', 5 => '15:55', 60 => '15:00' },
    '23:50' => { 1 => '23:49', 3 => '23:48', 5 => '23:45', 60 => '23:00' },
    '18:45' => { 1 => '18:45', 3 => '18:45', 5 => '18:45', 60 => '18:00' },
  }  
end
