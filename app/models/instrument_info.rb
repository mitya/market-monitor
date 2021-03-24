class InstrumentInfo < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :abc, -> { order :ticker }

  def refresh(include_company: false)
    return if stats_updated_at && stats_updated_at > 15.minutes.ago
    puts "Update info for #{ticker}"

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

    if include_company
      puts "Update comp for #{ticker}"
      self.company = IexConnector.company(ticker)
      self.company_updated_at = Time.current
      self.name = company['companyName']
      self.industry = company['industry']&.strip
      self.sector = company['sector']&.strip
      self.country = company['country']
      self.industry = company['industry']
      save!
    end

    if false
      self.advanced_stats = IexConnector.advanced_stats!(ticker)
      self.advanced_stats_updated_at = Time.current
      save!
    end

  rescue RestClient::NotFound
    destroy
  end

  def marketcap = super.to_i.nonzero?
  def marketcap_mil = marketcap && marketcap / 1_000_000
  def industry = super&.strip
  def dividend_yield_percent = dividend_yield && dividend_yield * 100
  def avg_10d_volume = stats['avg10Volume']
  def avg_30d_volume = stats['avg30Volume']

  class << self
    def refresh
      abc.find_each do |info|
        next if info.stats.present?
        puts "Update company & stats for #{info.ticker}"
        info.refresh
        sleep 0.33
      end
    end

    def load_sector_codes_from_tops
      data = JSON.parse File.read "cache/iex/tops.json"
      data.each do |item|
        if instrument = Instrument[item['symbol']]
          instrument.info&.update! sector_code: item['sector']
        end
      end
    end
  end
end

__END__

Instrument.premium.each &:create_info
Instrument.get('AAPL').info.refresh
InstrumentInfo.refresh
InstrumentInfo.group(:industry).order(:count).count
InstrumentInfo.pluck(:industry)
InstrumentInfo.load_sector_codes_from_tops
Instrument['BABA'].info.refresh
