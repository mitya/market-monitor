class CheckMissingDates
  include StaticService

  def call(dates: nil, weeks: nil, since: nil, till: nil, special: false, confirmed: false, force: false)
    dates = dates ? dates.to_s.split(',').presence : []
    dates += Current.last_n_weeks(weeks.to_i)         if weeks
    dates += Current.weekdays_since(since.to_date)    if since
    dates += Current::SpecialDates.dates_plus         if special
    dates -= [Current.date]

    if till = till.to_s.to_date
      dates.reject! { |date| date > till }
    end

    dates = Current.last_2_weeks if dates.empty?
    dates = dates - MarketCalendar.nyse_holidays.to_a

    dates.uniq.sort.reverse.each do |date|
      date = Date.parse(date) if String === date
      instruments = (R.instruments_from_env || Instrument.iex_sourceable).abc
      instruments = instruments.reject { |inst| inst.first_date && inst.first_date > date } unless force
      instruments = instruments.select(&:iex_ticker)
      with_missing_date = instruments.select { |inst| inst.candles.day.final.where(date: date).none? }

      puts if date.monday?
      puts "#{date} #{date.strftime '%a'} #{with_missing_date.count} #{with_missing_date.join(',')}".yellow

      next unless confirmed
      Current.parallelize_instruments(with_missing_date, IEX_RPS) { | inst| Iex.import_day_candles inst, date: date }
    end
  end
end
