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

    dates.uniq.sort.each do |date|
      date = Date.parse(date) if String === date

      instruments = (R.instruments_from_env || Instrument.all).abc
      instruments = instruments.reject { |inst| inst.first_date && inst.first_date > date } unless force
      with_missing_date = instruments.select { |inst| inst.candles.day.final.where(date: date).none? }
      missing_tinkoff_instruments = with_missing_date.reject(&:iex_ticker)
      missing_iex_instruments     = with_missing_date.select(&:iex_ticker)

      missing_tinkoff_instruments = [] if MarketCalendar.moex_holidays.include?(date)

      puts "#{date} #{date.strftime '%a'} #{with_missing_date.count.to_s.rjust 4} #{missing_iex_instruments.join(' ').blue} #{missing_tinkoff_instruments.join(' ').yellow}"
      puts if date.monday?

      next unless confirmed
      Current.parallelize_instruments(missing_iex_instruments, IEX_RPS) { | inst| Iex.import_day_candles inst, date: date }
    end
  end
end
