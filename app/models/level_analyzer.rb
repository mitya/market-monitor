class LevelAnalyzer
  attr :instrument

  def initialize(instrument)
    @instrument = Instrument[instrument]
    @candles = instrument.candles.day.find_date_or_before(date)
  end

  def search

  end
end

__END__
