class PortfolioItem < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :empty, -> { where tinkoff_lots: nil, tinkoff_iis_lots: nil, vtb_lots: nil }

  def cost
    lots = total_lots
    lots * instrument.last if lots && instrument.last
  end

  def cost_in_usd
    Current.in_usd cost, instrument.currency
  end

  def total_lots
    [tinkoff_lots, tinkoff_iis_lots, vtb_lots].compact.sum
  end

  def ideal_cost
    ideal_lots * instrument.last if ideal_lots && instrument.last
  end

  def ideal_cost_in_usd
    Current.in_usd ideal_cost, instrument.currency
  end

  class << self
    def cleanup
      empty.delete_all
    end
  end
end

__END__

InstrumentSet.get('portfolio').symbols.each { |ticker| PortfolioItem.find_or_create_by! ticker: ticker }
PortfolioItem.cleanup
