class IntradayCandleLoader
  def tickers 
    return R.tickers_from_env if R.tickers_from_env.present?
    
    tickers = Setting.sync_tickers
    tickers += Setting.chart_tickers
    tickers += TickerSet.pluck(:tickers).flatten if Setting.sync_ticker_sets
    tickers.sort
  end
  
  def instruments = Instrument.for_tickers(tickers).abc  
  
  def interval
    value = ENV['period'] || Setting.chart_period
    value = '3min' unless value.in?(Candle::Intraday::ValidIntervals)
    value
  end
  
  def interval_in_seconds = (Candle.interval_duration(interval) / 60)
    
  def should_analyze = ENV['analyze'] == '1'
  
  # def schedule
  #   loop do
  #     once_in 10,     :load_intraday
  #     once_in 5 * 60, :load_prices
  #   end
  # end
  
  def sync
    last_tickers = nil
    last_interval = nil
    last_interval_index = nil
    last_iex_update_time = Setting.iex_last_update

    loop do
      current_tickers = tickers      
      current_interval = interval
      current_interval_index = (Time.current.hour * 60 + Time.current.min) / interval_in_seconds
      puts "tick #{Time.current} - #{current_interval}##{current_interval_index} - last #{last_interval_index}"

      change_last_params = -> do
        last_tickers = current_tickers
        last_interval = current_interval
        last_interval_index = current_interval_index
      end
            
      if last_tickers != current_tickers || last_interval != current_interval
        load_history days: 2
        sync_latest
        change_last_params.call
        load_history
      elsif last_interval_index != current_interval_index
        unless current_interval_index - last_interval_index == 1 && Time.current.sec < 50
          sync_latest
          change_last_params.call
        end
      end      

      if Current.us_market_open? && (Setting.iex_update_pending? || last_iex_update_time < 5.minutes.ago)
        RefreshPricesFromIex.refresh 
        puts "refresh IEX prices".green
        last_iex_update_time = Time.current
      end

      if Setting.tinkoff_update_pending?
        RefreshPricesFromTinkoff.refresh Instrument.rub.abc
        puts "refresh Tinkoff prices".green
      end

      sleep 5
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
  
  def load_history(days: 10, include_today: false)
    puts 'check history...'
    dates = recent_dates(days) - [Current.date]
    instruments.abc.each do |inst|      
      close_time = CLOSE_TIMES[inst.closing_hhmm][interval_in_seconds.to_i]
      missing_dates = dates.reject do |date|
        inst.candles_for(interval).on(date).closings.exists? ||
        inst.candles_for(interval).on(date).where(time: close_time).exists?
      end
      missing_dates << Current.date if include_today && missing_dates.any?
      Tinkoff.import_intraday_candles_for_dates inst, interval, dates: missing_dates      
      Tinkoff.import_today_opening_candle inst if interval != '3min'
    end    
  end
  
  def sync_latest(analyze: should_analyze)
    puts 'sync latest'
    instruments.abc.each do |inst|
      Tinkoff.import_intraday_candles_for_today inst, interval
      PriceSignal.analyze_intraday_for inst, interval if analyze
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
  
  def recent_dates(days_number = 10) = MarketCalendar.open_days(days_number.days.ago)
  
  CLOSE_TIMES = { 
    '16:00' => { 1 => '15:59', 3 => '15:57', 5 => '15:55', 60 => '15:00' },
    '23:50' => { 1 => '23:49', 3 => '23:48', 5 => '23:45', 60 => '23:00' },
    '18:45' => { 1 => '18:45', 3 => '18:45', 5 => '18:45', 60 => '18:00' },
  }  
end
