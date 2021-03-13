class InstrumentInfo < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker', primary_key: 'ticker'

  scope :abc, -> { order :ticker }

  def refresh
    self.company = IexConnector.company(ticker)
    self.company_updated_at = Time.current
    self.name = company['companyName']
    self.industry = company['industry']
    self.sector = company['sector']
    self.country = company['country']
    self.industry = company['industry']
    save!

    self.stats = IexConnector.stats(ticker)
    self.stats_updated_at = Time.current
    self.marketcap = stats['marketcap']
    self.shares = stats['sharesOutstanding']
    self.beta = stats['beta']&.round(2)
    self.pe = stats['peRatio']&.round(2)
    self.dividend_yield = stats['dividendYield']&.round(4)
    self.next_earnings_date = stats['nextEarningsDate']
    self.ex_divident_date = stats['exDividendDate']
    save!

  rescue RestClient::NotFound
    destroy
  end

  class << self
    def refresh
      abc.find_each do |info|
        info.refresh
        sleep 0.33
      end
    end
  end
end

__END__

Instrument.abc.each &:create_info
Instrument.get('AAPL').info.refresh
InstrumentInfo.refresh
