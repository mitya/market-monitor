class IntradayLevelHitDetector
  include StaticService

  TRACKED_MA_HITS = %w[
    etln  gazp tcsg vkco gltr ozon five rosn agro enpg
  ].to_set

  def analyze(instrument, levels: nil, candles: nil)
    @instrument = Instrument[instrument]
    @levels = levels || PriceLevel.textual[@instrument.ticker] || []
    @candles = candles || instrument.candles_for('1min').on(Current.date).non_analyzed.order(:time).includes(:instrument)

    if indicators = instrument.indicators
      [20, 50, 100, 200].each do |period|
        important = TRACKED_MA_HITS.include?(instrument.ticker) && period >= 50
        @levels << PriceLevel.new(ticker: instrument.ticker, value: indicators.send("ema_#{period}"),  kind: 'MA', period:  period, important: important)
      end
    end

    return if @candles.blank?
    return if @levels.blank?

    date = @candles.first.date
    @today_hits = @instrument.level_hits.intraday.where(date: date).order(time: :desc).to_a
    @older_hits = @instrument.level_hits.intraday.where(date: date - 2.days .. date).order(time: :desc).to_a

    instrument.transaction do
      @candles.each do |candle|
        analyze_intraday_candle candle
      end
    end

    nil
  end

  def analyze_intraday_candle(candle)
    @levels.each do |level|
      if candle.range.include?(level.value)
        next if @today_hits.detect { |hit| hit.level_value == level.value && hit.datetime >= candle.datetime - 3.hours }
        next if level.ma? && @older_hits.detect { |hit| hit.ma? && hit.ma_length == level.period }
        puts "Level hit for #{candle.ticker}: #{level.value}".magenta
        hit = PriceLevelHit.create! instrument: candle.instrument, date: candle.date, time: candle.time,
          source: level.source_type, ma_length: level.period, positive: candle.up?,
          level_value: level.value, manual: level.manual?, rel_vol: candle.volume_to_average, important: level.important
        @today_hits << hit
      end
    end
  end
end

__END__
Instrument.active.each { IntradayLevelHitDetector.analyze _1 }
