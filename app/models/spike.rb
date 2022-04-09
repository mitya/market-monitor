class Spike < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  scope :up,   -> { where 'spike > 0' }
  scope :down, -> { where 'spike < 0' }

  THRESHOLD = 0.04

  def up?   = spike > 0
  def down? = spike < 0

  class << self
    def scan_all(since: Current.yesterday)
      Instrument.active.abc.each { |inst| scan_for inst, since: since }
    end

    def scan_for(instrument, since: Current.y2020, threshold: THRESHOLD)
      instrument = Instrument[instrument]
      return if instrument.eur?
      instrument.candles.day.since(since).each do |candle|
        if candle.larger_tail_range.abs >= threshold
          find_or_create_by! instrument: instrument, date: candle.date do |spike|
             spike.assign_attributes spike: candle.larger_tail_range.round(3), change: candle.rel_close_change.round(3)
          end
        end
      end
    end
  end

end

__END__

Spike.scan_all since: 1.week.ago
Spike.scan_for 'NKNCP'
instr('NKNCP').price_on!('2021-03-12').larger_tail_range
