class Tinkoff
  concerning :CandlesApi do
    def load_intervals(instrument, interval, since, till, delay: 0)
      call_js_api "candles #{instrument.figi} #{interval} #{since.xmlschema} #{till.xmlschema}", delay: delay
    end

    def last_minute_candles(instrument, since = 10.minutes.ago, till = 1.minute.from_now)
      load_intervals instrument, '1min', since.beginning_of_minute, till.beginning_of_minute
    end

    def last_hour_candles(instrument, since = 1.hour.ago, till = 1.minute.from_now)
      load_intervals instrument, 'hour', since.beginning_of_minute, till.beginning_of_minute
    end

    def load_day(instrument, since = Current.date, till = since.to_date.end_of_day)
      load_intervals instrument, 'day', since, till
    end

    def import_candles_from_hash(data, candle_class: nil)
      if data['error']
        puts "Candle import error: #{data.dig('error', 'payload', 'message') || data['error']}".red
        return []
      end
      interval = data['interval']
      instrument = Instrument.get!(figi: data['figi'])
      candles = data['candles'].to_a

      # return if instrument.candles.where(interval: interval).where(Candle.arel_table[:time].gteq 1.day.ago.midnight).exists?
      # puts "Import #{candles.count} #{interval} candles for #{instrument}"
      candle_class ||= Candle.interval_class_for(interval)
      return "Missing candles for #{instrument}".red if candle_class == nil

      candle_class.transaction do
        candles = candles.sort_by { _1['time' ]}
        puts "Import Tinkoff #{instrument} - no candles".colorize(:white) if candles.empty?
        candles.map do |hash|
          timestamp = Time.parse(hash['time']).in_time_zone(instrument.time_zone)
          date = timestamp.to_date
          hhmm = timestamp.to_s(:time) if interval != 'day'
          ongoing = interval == 'day' && date == Current.date && !Current.weekend? ||
                    candle_class.intraday? && timestamp + candle_class.interval_duration >= Time.current

          candle = candle_class.find_or_initialize_by({ instrument: instrument, interval: interval, date: date, time: hhmm }.compact)

          next puts "Skip   Tinkoff #{date} #{hhmm} #{interval} #{instrument} because of IEX".white if candle.iex?
          puts      "Import Tinkoff #{date} #{hhmm} #{interval} #{instrument} #{ongoing ? '...' : ''}".colorize(candle.new_record?? :green : :yellow)

          candle.ticker  = instrument.ticker
          candle.source  = 'tinkoff'
          candle.open    = hash['o']
          candle.close   = hash['c']
          candle.high    = hash['h']
          candle.low     = hash['l']
          candle.volume  = hash['v'] > Integer::Max31 ? Integer::Max31 : hash['v']
          candle.date    = date
          candle.ongoing = ongoing

          if candle_class.intraday? && !candle_class.is_a?(Candle::H1)
            candle.is_opening! if hhmm == instrument.opening_hhmm
          end

          candle.save!
          candle
        end
      end
    end

    # import_day_candle_for_date
    def import_day_candle(instrument, date, delay: 0.25)
      return if instrument.candles.day.final.tinkoff.where(date: date).exists?
      data = load_day instrument, date - 1, date
      import_candles_from_hash data
      sleep delay
    rescue
      puts "Import #{instrument} failed: #{$!}"
    end

    # import_day_candles_between
    def import_day_candles(instrument, since:, till: Date.tomorrow, delay: 0.01, candle_class: nil)
      data = load_day instrument, since, till
      import_candles_from_hash data, candle_class: candle_class
      sleep delay
    rescue
      puts "Import #{instrument} failed: #{$!}"
    end

    # import_day_candles_since
    def import_latest_day_candles(instrument, today: true, since: nil)
      # return if instrument.candles.day.where('date > ?', 2.weeks.ago).none?
      # return if instrument.candles.day.today.where('updated_at > ?', 3.hours.ago).exists?
      since ||= instrument.candles.day.final.last_loaded_date.tomorrow rescue 1.month.ago
      till = today ? Current.date.end_of_day : instrument.calendar.yesterday.end_of_day
      return if till < since
      import_day_candles instrument, since: since, till: till
    end

    # import_day_candles_for_years
    def import_all_day_candles(instrument, years: [2019, 2020, 2021, 2022], candle_class: nil)
      import_day_candles instrument, since: Date.parse('2019-01-01'), till: Date.parse('2019-12-31').end_of_day, candle_class: candle_class if years.include?(2019)
      import_day_candles instrument, since: Date.parse('2020-01-01'), till: Date.parse('2020-12-31').end_of_day, candle_class: candle_class if years.include?(2020)
      import_day_candles instrument, since: Date.parse('2021-01-01'), till: Date.parse('2021-12-31').end_of_day, candle_class: candle_class if years.include?(2021)
      import_day_candles instrument, since: Date.parse('2022-01-01'), till: Date.current.end_of_day,             candle_class: candle_class if years.include?(2022)
    end


    def import_intraday_candles(instrument, interval, since: nil, till: nil)
      return if !instrument.tinkoff?
      # return if !instrument.market_open? && since&.today?

      since = since.change(min: 00) if interval == 'hour' && instrument.usd? && since && since.hour == 9 && since.min == 30
      till ||= since.end_of_day

      # day_start = instrument.market_open_time
      # last_loaded_candle = instrument.candles_for(interval).today.by_time.last
      # since ||= last_loaded_candle ? last_loaded_candle.datetime + 1 : day_start

      return if since + Candle.interval_duration_for(interval) > Time.current

      # puts "load tinkoff #{instrument} #{since} #{till}".magenta
      data = load_intervals instrument, interval, since, till, delay: 0.05
      candles = import_candles_from_hash data

      # inject empty candles for illiquid names
      # candles.select { !_1.prev_close && !_1.is_opening? }.each do |candle|
      #   last_prev = candle.whatever_previous
      #   candle.times_between(last_prev).each do |time|
      #     candle.class.create! ticker: instrument, date: candle.date, time: time,
      #       open: candle.open, close: candle.open, high: candle.open, log: candle.open, volume: 0,
      #       source: candle.source, prev_close: last_prev.close
      #   end
      # end

    end

    def import_intraday_candles_for_today(instrument, interval)
      last_loaded = instrument.candles_for(interval).today.by_time.final.last
      return if last_loaded&.is_closing?

      since = last_loaded ?
        last_loaded.datetime + (last_loaded.ongoing? ? 0 : 1.second) :
        instrument.today_opening
      till  = instrument.today_closing

      import_intraday_candles instrument, interval, since: since, till: till

      if Time.current > instrument.today_closing
        instrument.candles_for(interval).on(since.to_date).order(:time).last&.is_closing!
      end
    end

    def import_intraday_candles_for_dates(instrument, interval, dates: [Current.date])
      dates.each do |date|
        import_intraday_candles instrument, interval, since: instrument.opening_on(date), till: instrument.closing_on(date)

        if date.past? || Time.current > instrument.today_closing
          instrument.candles_for(interval).on(date).order(:time).last&.is_closing!
        end
      end
    end


    def import_today_opening_candle(instrument, interval: '3min')
      return if !instrument.tinkoff?
      return if instrument.candles_for(interval).today.openings.exists?
      import_candles_from_hash load_intervals instrument, interval, instrument.today_opening, instrument.today_opening + 1.second
    end

    def import_closing_5m_candles(instruments)
      return if !instrument.tinkoff?
      return if instrument.rub? || instrument.eur?
      return puts "Last 5m already loaded on #{date} for #{instrument}".yellow if Candle::M5.where(instrument: instrument, date: date, time: '19:55').exists?

      est_midnight = date.in_time_zone Current.est
      import_candles_from_hash load_intervals instrument, '5min', est_midnight.change(hour: 15, min: 50), est_midnight.change(hour: 16, min: 00), delay: 0.1
    end
  end
end

__END__

Tinkoff.load_day(instr(:rig), Current.yesterday)
