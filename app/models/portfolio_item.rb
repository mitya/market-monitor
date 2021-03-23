class PortfolioItem < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def total
    lots * instrument.last if lots && instrument.last
  end

  def total_in_usd
    Current.in_usd total, instrument.currency
  end
end

__END__

InstrumentSet.get('portfolio').symbols.each { |ticker| PortfolioItem.find_or_create_by! ticker: ticker }
