class PortfolioItem < ApplicationRecord
end

__END__

InstrumentSet.get('portfolio').symbols.each { |ticker| PortfolioItem.find_or_create_by! ticker: ticker }
