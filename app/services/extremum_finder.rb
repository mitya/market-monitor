class ExtremumFinder
  include StaticService

  def find_for(candles)
    periods = [10, 20, 30, 50, 100, 200, 400]
    extremums = []
    periods.each do |candle_count|
      last_candles = candles.last(candle_count)
      max = last_candles.maximum(:high)
      min = last_candles.minimum(:low)
      extremums << max << min
    end
    extremums.map { round _1 }.uniq
    # extremums.flat_map do |extremum|
    #   extremums.select { ((_1 - extremum) / extremum).abs < 0.05 }.average
    # end.map { round _1 }.uniq
  end

  private

  def round(level)
    case
      when level < 1 then level.round(2)
      when level < 5 then level.round(1)
      when level < 20 then level.round(1)
      when level < 100 then level.to_i
      when level >= 100 then level.to_i.round(-1)
    end
  end
end

__END__
ExtremumCache.get('TCSG', '2022-04-01'.to_date, :high)
