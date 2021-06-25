class PriceSignalStrategy < ApplicationRecord
  def up? = direction == 'up'

  def test!
    results = PriceSignalResult.joins(:signal)
    results = results.where 'price_signals.date': period        if period
    results = results.param_in_range :change, change            if change
    results = results.param_in_range :prev_2w_low, prev_2w_low  if prev_2w_low

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
      periods.each do |period|
        changes.each { |change| test_breakout_up period: period, change: change }
      end
      # (-20...20).each { |prev_2w_low| test_breakout_up prev_2w_low: prev_2w_low }
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
