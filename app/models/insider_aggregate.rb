class InsiderAggregate < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def refresh
    end_of_month = Date.current.beginning_of_month - 1.day

    [1,2,3].each do |months|
      period = (end_of_month - (months - 1).month).beginning_of_month .. Date.current
      %w[buys sells].each do |type|
        transactions = instrument.insider_transactions.where(date: period).send(type)

        self.send "m#{months}_#{type}_total=", transactions.sum(&:full_cost)
        prices = transactions.map(&:price).compact
        self.send "m#{months}_#{type}_avg=", prices.sum / prices.size if prices.any?
      end
    end

    sa_reviews = PublicSignal.sa.where(ticker: ticker).order(date: :desc).limit(3)
    [1,2,3].each do |index|
      if review = sa_reviews[index - 1]
        self.send "sa_#{index}_score=", review.score
        self.send "sa_#{index}_price=", review.price
      end
    end

    save!
  end

  class << self
    def aggregate
      Instrument.usd.find_each do |inst|
        find_or_initialize_by(ticker: inst.ticker).refresh
      end
    end
  end
end

__END__
InsiderAggregate.aggregate
