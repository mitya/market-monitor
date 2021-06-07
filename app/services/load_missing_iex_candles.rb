class LoadMissingIexCandles
  include StaticService

  def call
    since = Date.parse('2020-07-01')
    Instrument.iex_sourceable.with_first_date.abc.find_each do |inst|
      Current.weekdays_since([since, inst.first_date].max).each do |date|
        loaded = Iex.import_day_candles inst, date: date
        break if !loaded
      end
    end

    nil
  end
end


# CBPO MTSC PRSP RP
