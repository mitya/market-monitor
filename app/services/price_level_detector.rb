class PriceLevelDetector
  include StaticService

  def repo = PriceLevel
  
  def search_all
    Instrument.all.abc.each { |inst| search inst }
  end

  def search(instrument)
    candles = instrument.candles.day.where(date: HISTORY_START..Date.current).order(:date)
    inner_candles = candles[PERIOD..-PERIOD]
    return if not inner_candles

    lows, highs = %w[low high].map do |selector|
      operator = selector == 'low' ? :>= : :<=
      extremums = inner_candles.select.with_index do |current, index|
        is_extremum = candles[index, PERIOD * 2].without(current).all? { |other| other.send(selector).send(operator, current.send(selector)) }
      end
      extremums.map { |candle| PriceLevel::Extremum.new(candle, selector) }
    end

    extremums = highs + lows

    groups = []
    extremums.each do |extremum|
      if group = groups.detect { |group| group.any? { |other| Math.in_delta?(extremum.value, other.value, ACCURACY) } }
        group << extremum
      else
        groups << [extremum]
      end
    end

    groups.each do |extremums|
      average = extremums.map(&:value).sum / extremums.count
      value = average.round(1)

      find_or_create_by!(ticker: instrument.ticker, value: value) do |level|
        level.dates = extremums.map(&:date)
        level.accuracy = ACCURACY
        level.period = PERIOD
        level.total_volume = extremums.map { |e| e.candle.volume }.sum
        level.average_volume = extremums.map { |e| e.candle.volume }.average

        is_low  = extremums.any?(&:low?)
        is_high = extremums.any?(&:high?)
        level.kind = is_low && is_high ? 'multi' : is_low ? 'low' : 'high'
      end
    end

    nil
  end

  def cache_volume
    find_each(&:cache_volume)
  end

  def load_manual
    manual_tickers = []

    Pathname("db/levels.txt").readlines(chomp: true).each do |line|
      next if line.blank?
      ticker, *values = line.split
      manual_tickers << ticker
      if instrument = Instrument.get(ticker)
        instrument.levels.manual.where.not(value: values).each &:destroy
        values.each do |value|
          repo.find_or_create_by! instrument: instrument, value: value, manual: true, important: true
        end
      end
    end

    repo.manual.where.not(ticker: manual_tickers.map(&:upcase)).destroy_all

    nil
  end
end

__END__

PriceLevelHit.levels.delete_all
PriceLevelDetector.delete_all
PriceLevelDetector.search_all

PriceLevelDetector.search instr('DOCU')
PriceLevelDetector.load_manual
PriceLevelDetector.cache_volume
