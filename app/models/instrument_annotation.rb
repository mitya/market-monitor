class InstrumentAnnotation < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def clean_intraday_levels
    intraday_levels.sort.map { _1 % 1 == 0 ? _1.to_i : _1 }
  end

  def intraday_levels_line
    "#{ticker} #{clean_intraday_levels.join(' ')}"
  end
  
  class << self
    def update_intraday_levels_from_lines(lines)
      transaction do
        lines.each do |line|
          ticker, *levels = line.squish.split(' ')
          levels = levels.map(&:to_d)
          if inst = Instrument.get(ticker)
            inst.annotation!.update! intraday_levels: levels.sort
          end
        end      
      end      
    end
    
    def with_intraday_levels
      where.not(intraday_levels: nil).order(:ticker)
    end
  end
end
