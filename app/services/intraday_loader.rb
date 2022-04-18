class IntradayLoader
  def initialize(instruments: nil, interval: nil, include_history: true, mode: nil)
    @wide_market       = mode != nil
    @instruments       = instruments
    @interval          = interval
    @include_history   = include_history
    @sync_today_candle = @wide_market
    @should_analyze    = @wide_market
    @sync_futures      = @mode == :ru
  end

  def tickers
    return R.tickers_from_env if R.tickers_from_env.present?

    tickers = Setting.sync_tickers
    tickers += Setting.chart_tickers
    tickers += TickerSet.pluck(:tickers).flatten if Setting.sync_ticker_sets
    tickers.sort
  end

  def instruments = @instruments || Instrument.for_tickers(tickers).abc

  def interval
    return @interval if @interval
    value = ENV['period'] || Setting.chart_period
    value = '3min' unless value.in?(Candle::Intraday::ValidIntervals)
    value
  end

  def interval_in_minutes = (Candle.interval_duration_for(interval) / 60)

  def should_analyze = @should_analyze

  def sync
    last_tickers = nil
    last_interval = nil
    last_interval_index = nil
    last_iex_update_time = Setting.iex_last_update
    today_candle_updated_at = 1.hour.ago
    larger_candles_updated_at = 1.hour.ago
    futures_synced_at = 1.hour.ago

    InstrumentCache.set instruments

    loop do
      now = Time.current
      current_tickers = tickers
      current_interval = interval
      interval_in_minutes = 1
      current_interval_index = (Time.current.hour * 60 + Time.current.min) / interval_in_minutes
      # puts "#{Time.now} tick - #{current_interval}##{current_interval_index} - last #{last_interval_index}"

      change_last_params = -> do
        last_tickers = current_tickers
        last_interval = current_interval
        last_interval_index = current_interval_index
      end

      if last_tickers != current_tickers || last_interval != current_interval
        load_history days: 2
        sync_latest
        analyze_latest
        change_last_params.call
        load_history
      elsif last_interval_index != current_interval_index
        # unless current_interval_index - last_interval_index == 1 && now.sec < 50
        sync_latest
        analyze_latest
        change_last_params.call

        Price.sync_with_last_candles instruments
      end

      # if Current.us_market_open? && (Setting.iex_update_pending? || last_iex_update_time < 5.minutes.ago)
      #   RefreshPricesFromIex.refresh
      #   puts "refresh IEX prices".green
      #   last_iex_update_time = Time.current
      # end

      # if Setting.tinkoff_update_pending?
      #   RefreshPricesFromTinkoff.refresh Instrument.rub.abc
      #   puts "refresh Tinkoff prices".green
      # end

      # analyze

      if @sync_today_candle
        if today_candle_updated_at < 1.minutes.ago
          update_today_candles
          today_candle_updated_at = Time.current
        end
        if larger_candles_updated_at < 1.minutes.ago
          update_larger_candles
          larger_candles_updated_at = Time.current
        end
      end

      if @sync_futures && futures_synced_at < 10.minutes.ago
        Future.import_intraday
        futures_synced_at = Time.current
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

  def load_history(days: interval == 'hour' ? 30 : 10, include_today: false)
    return if !@include_history
    puts "check history: #{days} days, today=#{include_today}"
    dates = recent_dates(days) - [Current.date]
    instruments.abc.each do |inst|
      close_time = CLOSE_TIMES[inst.closing_hhmm][interval_in_minutes.to_i]
      missing_dates = dates.reject do |date|
        inst.candles_for(interval).on(date).closings.exists? ||
        inst.candles_for(interval).on(date).where(time: close_time).exists?
      end
      missing_dates << Current.date if include_today && missing_dates.any?
      Tinkoff.import_intraday_candles_for_dates inst, interval, dates: missing_dates
      Tinkoff.import_today_opening_candle inst if interval != '3min'
    end
  end

  def sync_latest
    puts "#{Time.now} sync latest"
    instruments.abc.each { |inst| Tinkoff.import_intraday_candles_for_today inst, interval }
    SyncChannel.push 'candles'
  end

  def analyze_latest
    return if should_analyze == false || interval != '1min'
    puts "#{Time.now} analyze latest"
    instruments.includes(:info).abc.each do |inst|
      new_candles = inst.candles_for(interval).on(Current.date).non_analyzed.order(:time).includes(:instrument)
      IntradayAnalyzer.analyze inst, new_candles
      IntradayLevelHitDetector.analyze inst, candles: new_candles, levels: PriceLevel.textual[inst.ticker]
    end
  end

  def update_today_candles
    instruments.each &:update_today_candle_intraday
  end

  def update_larger_candles
    instruments.each &:update_larger_candles
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
    # '23:50' => { 1 => '23:49', 3 => '23:48', 5 => '23:45', 60 => '23:00' },
    # '18:45' => { 1 => '18:45', 3 => '18:45', 5 => '18:45', 60 => '18:00' },
    '18:50' => { 1 => '18:49', 3 => '18:48', 5 => '18:45', 60 => '18:00' },
  }

  class << self
    def sync_charts
      new.sync
    end

    def sync_ru
      new(instruments: Instrument.active.stocks.rub, interval: '1min', include_history: false, mode: :ru).sync
    end

    def sync_us
      new(instruments: Instrument.active.stocks.usd.current, interval: '1min', include_history: false, mode: :us).sync
    end
  end
end
