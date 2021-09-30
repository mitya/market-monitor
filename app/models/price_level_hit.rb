class PriceLevelHit < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  belongs_to :level, class_name: 'PriceLevel', optional: true

  DELTA = 0.01

  scope :exact, -> { where exact: true }
  scope :important, -> { where important: true }

  def loose? = !exact?
  def source_name = "#{source}#{ma_length}"
  def ma? = source == 'ma'

  PositiveKinds = %w[up-break up-gap down-test].to_set

  before_validation do
    self.instrument ||= level&.instrument
    self.level_value ||= level&.value
    self.important = level.important if level
    self.manual = level.manual? if level
    self.positive = PositiveKinds.include?(kind)
    self.exact = true if exact == nil
  end

  before_save do
    self.continuation = instrument.level_hits.where(date: MarketCalendar.prev2(date)).any?
  end

  class << self
    def analyze(instrument, date: Current.yesterday, levels: instrument.levels)
      curr = instrument.day_candles!.find_date(date)
      prev = curr&.previous
      return unless curr && prev

      instrument.level_hits.where(date: date).delete_all

      # recent = curr.previous_n(10)
      # recent_ref = recent[-4]
      #
      # levels.order(:value).each do |level|
      #   if is_nearby = curr.range_with_delta(DELTA).include?(level.value)
      #     exact = is_nearby && curr.range.include?(level.value)
      #     delta = exact ? 0 : DELTA
      #     was_on_level_recently = recent.any? { |candle| candle.range_with_delta(delta).include?(level.value) }
      #     kind = 'level'
      #
      #     if prev
      #       if prev > curr && prev.close > level.value_plus(delta)
      #         kind = was_on_level_recently ? 'retest-down' : 'fall'
      #       elsif prev < curr && prev.close < level.value_plus(exact ? 0 : -DELTA)
      #         kind = was_on_level_recently ? 'retest-up' : 'rise'
      #       end
      #     end
      #
      #     record! level: level, date: curr.date, kind: kind, exact: exact
      #   end
      # end
      #
      # where(date: MarketCalendar.prev(curr.date)).each do |yday|
      #   if curr.up? && curr.close > yday.level.value_plus(DELTA)
      #     kind = 'rebound-up' # or just pass through
      #   elsif curr.down? && curr.close < yday.level.value_plus(-DELTA)
      #     kind = 'rebound-down'
      #   end
      #
      #   record! level: yday.level, date: curr.date, kind: kind
      # end

      levels.order(:value).each do |level|
        value = level.value
        attrs = { source: 'level', date: curr.date, level: level }
        check_level curr, prev, value, attrs
      end

      indicators = instrument.indicators_history.find_by(date: curr.date)
      { 50 => indicators.ema_50, 200 => indicators.ema_200 }.each do |length, value|
        next unless value
        attrs = { source: 'ma', ma_length: length, date: curr.date, ticker: instrument.ticker, level_value: value }
        check_level curr, prev, value, attrs
      end
    end

    def analyze_all
      Instrument.all.abc.each { |inst| analyze inst }
    end

    def analyze_manual(date: Current.yesterday)
      Instrument.all.abc.each { |inst| analyze inst, levels: inst.levels.manual, date: date }; nil
    end

    def analyze_dates(dates)
      dates.each { |date| analyze_manual date: date }
    end

    def check_level(curr, prev, value, attrs)
      open    = curr.open
      close   = curr.close
      high    = curr.high
      low     = curr.low
      y_close = prev.close
      attrs[:close_distance] = ((close - value).abs / value.to_d).round(3)

      case
      when open < value && close >= value
        record! 'up-break', **attrs
      when open > value && close > value && low <= value
        record! 'down-test', **attrs.merge(max_distance: ((low - value).abs / value.to_d).round(3))
      when open > value && close >= value && y_close < value
        record! 'up-gap', **attrs

      when open > value && close <= value
        record! 'down-break', **attrs
      when open < value && close < value && high >= value
        record! 'up-test', **attrs.merge(max_distance: ((high - value).abs / value.to_d).round(2))
      when open < value && close < value && y_close > value
        record! 'down-gap', **attrs
      end
    end

    def record!(kind, **attrs)
      hit = find_or_create_by! kind: kind, **attrs
      puts "#{hit.date} hit #{hit.ticker.ljust 8} #{hit.source_name.ljust(5)} #{hit.kind.ljust(10)} #{hit.level_value}".
        colorize(hit.positive?? :green : :red)
    end
  end
end

__END__
PriceLevelHit.delete_all
PriceLevelHit.analyze_manual date: Current.yesterday
PriceLevelHit.analyze_manual date: Current.yesterday - 1

level
fall
rise
rebound-up/down (was on level in 6c, tested level, closed up)


down-test
down-break
down-gap

up-test open lower & close lower & high higher
up-break open lower & close higher
up-gap open higher & close higher & yesterday.close lower

ticker, date, kind=(down-test, down-break, ...), target=(level/ma), level, ma, manual, positive
