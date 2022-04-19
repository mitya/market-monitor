class IntradayLevelHitDetector
  include StaticService

  def analyze(instrument, levels: nil, candles: nil)
    @instrument = Instrument[instrument]
    @levels = levels || PriceLevel.textual[@instrument.ticker] || []
    @candles = candles || instrument.candles_for('1min').on(Current.date).non_analyzed.order(:time).includes(:instrument)

    if indicators = instrument.indicators
      [20, 50, 100, 200].each do |period|
        @levels << PriceLevel.new(ticker: instrument.ticker, value: indicators.send("ema_#{period}"),  kind: 'MA', period:  period)
      end
    end

    return if @candles.blank?
    return if @levels.blank?

    @older_hits = @instrument.level_hits.intraday.where(date: @candles.first.date).order(time: :desc).to_a

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
        unless @older_hits.detect { _1.level_value == level.value && _1.datetime >= candle.datetime - 2.hours }
          puts "Level hit for #{candle.ticker}: #{level.value}".magenta
          hit = PriceLevelHit.create! instrument: candle.instrument, date: candle.date, time: candle.time,
            source: level.source_type, ma_length: level.period,
            level_value: level.value, manual: level.manual?, rel_vol: candle.volume_to_average
          @older_hits << hit
        end
      end
    end
  end
end

__END__
Instrument.active.each { IntradayLevelHitDetector.analyze _1 }
