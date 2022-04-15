class IntradayLevelHitDetector
  include StaticService

  def analyze(instrument, levels: nil, candles: nil)
    @instrument = Instrument[instrument]
    @levels ||= PriceLevel.textual[@instrument.ticker]
    candles ||= instrument.candles_for('1min').on(Current.date).non_analyzed.order(:time).includes(:instrument)
    return if candles.blank?

    @older_hits = @instrument.level_hits.intraday.where(date: candles.first.date).order(time: :desc)

    instrument.transaction do
      candles.each do |candle|
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
          PriceLevelHit.create! instrument: candle.instrument, date: candle.date, time: candle.time, source: 'level',
            level_value: level.value, manual: true, rel_vol: candle.volume_to_average
        end
      end
    end
  end
end

__END__
IntradayLevelHitDetector.analyze instr('agro')
