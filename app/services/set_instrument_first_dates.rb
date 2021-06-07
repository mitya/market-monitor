class SetInstrumentFirstDates
  include StaticService

  def call
    # Instrument.iex_sourceable.find_each do |inst|
    #   if inst.candles.day.where(date: Current.y2019).exists?
    #     inst.update! first_date: Current.y2019
    #   end
    # end

    date = MarketCalendar.closest_weekday Date.parse('2021-06-01')

    instruments = Instrument.iex_sourceable.without_first_date.abc
    Current.parallelize_instruments(instruments, 3) do | inst|
      Iex.import_day_candles inst, date: date
    end

    instruments.find_each do |inst|
      if inst.candles.day.where(date: date).exists?
        inst.update! first_date: date
      end
    end

    nil
  end
end


__END__

Instrument.iex_sourceable.with_first_date.count
Instrument.iex_sourceable.without_first_date.count
