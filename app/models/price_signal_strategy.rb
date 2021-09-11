class PriceSignalStrategy < ApplicationRecord
  def up? = direction == 'up'

  def test!
    results = PriceSignalResult.joins(:signal)
    results = results.where 'price_signals.date': period                 if period
    results = results.param_in_range :change, change                     if change
    results = results.param_in_range :prev_2w_low, prev_2w_low           if prev_2w_low
    results = results.where 'price_signals.volume_change', volume_change if volume_change

    %i[d1_close d1_max d2_close d2_max d3_close d3_max d4_close d4_max w1_close w1_max w2_close w2_max w3_close w3_max m1_close m1_max m2_close m2_max].each do |attr|
      self[attr] = results.average(attr)&.round(4)
    end

    self.count = results.count
    self.entered_count = results.where(entered: true).count
    self.stopped_count = results.where(stopped: true).count

    save!
  end

  class << self
    def create_some
      periods = [ nil, *MarketCalendar.periods ]
      changes = (0.06.to_d ... 0.30.to_d).step(0.01.to_d).map { |low| range_up(low) } + [0.30..1.00]
      changes_from_recent = (-0.20.to_d .. 0.20.to_d).step(0.01.to_d).map { |low| range_up low }
      volume_diffs = [0...0.5, 0.5...1, 1...1.5, 1.5...2, 2...3, 3...5, 5...10, 10...nil]

      periods.each do |period|
        changes.each { |change| test_breakout_up period: period, change: change }
      end
      changes_from_recent.each { |change| test_breakout_up prev_2w_low: change }
      changes_from_recent.each { |change| test_breakout_up prev_1w_low: change }
      volume_diffs.each { |change| test_breakout_up prev_1w_low: change }
    end

    def test_earnings_breakouts
      # changes = (0.06.to_d ... 0.30.to_d).step(0.01.to_d).map { |low| range_up(low) } + [0.30..1.00]
      # changes.each { |change| test_breakout_up prev_2w_low: change }

      create_earnings_breakout_test
    end

    def create_earnings_breakout_test(**params)
      find_or_initialize_by(signal: 'earnings-breakout', direction: 'up', **params).test!
    end


    def test_breakout_up(**params)
      strategy = find_or_initialize_by signal: 'breakout', direction: 'up', **params
      strategy.test!
    end

    def range_up(value, inc = 0.01)
      value .. value + inc
    end
  end
end

__END__

PriceSignalStrategy.create_some
PriceSignalStrategy.test_earnings_breakouts
