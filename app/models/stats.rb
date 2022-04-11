class Stats < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :abc, -> { order :ticker }

  def refresh(include_company: false)
    # return if stats_updated_at && stats_updated_at > 15.minutes.ago
    puts "Update info for #{ticker}"

    self.stats = Iex.stats(iex_ticker)
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
      self.company = Iex.company(iex_ticker)
      self.company_updated_at = Time.current
      self.name = company['companyName']
      self.industry = company['industry']&.strip
      self.sector = company['sector']&.strip
      self.country = company['country']
      self.industry = company['industry']
      save!
    end

    if false
      self.advanced_stats = Iex.advanced_stats!(ticker)
      self.advanced_stats_updated_at = Time.current
      save!
    end

  # rescue RestClient::NotFound
  #   destroy
  end

  def marketcap = super.to_i.nonzero?
  def marketcap_mil = marketcap && marketcap / 1_000_000.0
  def marketcap_bil = marketcap && marketcap / 1_000_000_000.0
  def last_marketcap = shares * instrument.last rescue nil
  def last_marketcap_mil = shares * instrument.last / 1_000_000.0 rescue nil
  # def last_marketcap_mil = marketcap_mil

  def industry = super&.strip
  def dividend_yield_percent = dividend_yield && dividend_yield * 100
  def avg_10d_volume = stats['avg10Volume']
  def avg_30d_volume = stats['avg30Volume']
  def avg_m1_volume = extra['avg_m1_volume']
  def avg_d5_money_volume = d5_money_volume.to_d / 5
  def accessible_peers = peers.to_a.select { |ticker| Instrument.defined? ticker }
  def accessible_peers_and_self = accessible_peers + [ticker]
  def iex_ticker = instrument.global_iex_ticker
  def relative_volume = instrument.today&.volume.to_f / avg_volume


  def country_code
    COUNTRY_NAMES_TO_ISO3[country.to_s]
  end

  def vtb_long_risk = extra&.dig('vtb_long_risk')
  def vtb_short_risk = extra&.dig('vtb_short_risk')

  def tinkoff_long_risk = extra&.dig('tinkoff_long_risk')
  def tinkoff_short_risk = extra&.dig('tinkoff_short_risk')
  def tinkoff_can_short? = extra&.dig('tinkoff_can_short')


  def candles_for_averaging = instrument.day_candles.where('date >= ?', '2022-03-24').order(date: :desc).limit(20)

  def set_average_volume(n_candles = 10)
    update! avg_volume: candles_for_averaging.average(:volume).to_i
  end

  def set_average_change(n_candles = 10)
    update! avg_change: candles_for_averaging.map(&:rel_true_range).compact.average.round(3)
  end

  def set_d5_volume
    money_vol = instrument.day_candles.order(:date).last(5).pluck(:volume).sum * instrument.lot * instrument.last
    marketcap_vol = (money_vol / marketcap).round(3) if marketcap
    update! d5_money_volume: money_vol, d5_marketcap_volume: marketcap_vol
  end

  def sync_earning_dates
    update! earning_dates: (earning_dates.to_a + [next_earnings_date]).uniq.compact.sort
  end

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
          next unless instrument.usd?
          instrument.info&.update! sector_code: item['sector']
        end
      end
    end

    def load_peers
      Instrument.iex.usd.find_each do |inst|
        next if inst.info!.peers
        peers = Iex.peers(inst.iex_ticker)
        puts "Load peers for #{inst.ticker}: #{peers.join(' ')}"
        inst.info.update! peers: peers
        sleep 0.33
      rescue RestClient::NotFound
        puts "Miss peers for #{inst.ticker}".red
      end
    end

    def load_non_us_info
      Instrument.rub.abc.each { |inst| inst.info!.refresh include_company: true }
      Instrument.eur.abc.each { |inst| inst.info!.refresh include_company: true }
    end
  end

  COUNTRY_NAMES_TO_ISO3 = {
    'Argentina'        => 'arg',
    'Australia'        => 'aus',
    'BE'               => 'usa',
    'Belgium'          => 'bel',
    'Bermuda'          => 'bmu',
    'Brazil'           => 'bra',
    'Canada'           => 'can',
    'Cayman Islands'   => 'cym',
    'Chile'            => 'chl',
    'China (Mainland)' => 'chn',
    'CN'               => 'cny',
    'France'           => 'fra',
    'Germany'          => 'deu',
    'Hong Kong'        => 'hkg',
    'India'            => 'ind',
    'Ireland'          => 'irl',
    'Israel'           => 'isr',
    'Italy'            => 'ita',
    'Japan'            => 'jpn',
    'Luxembourg'       => 'lux',
    'Netherlands'      => 'nld',
    'Russia'           => 'rus',
    'South Africa'     => 'zaf',
    'Sweden'           => 'swe',
    'Switzerland'      => 'che',
    'US'               => 'usa',
    'Greece'           => 'grc',
    'United States'    => 'usa',
  }
end

__END__

Instrument.premium.each &:create_info
Instrument.get('AAPL').info.refresh
Stats.refresh
Stats.group(:industry).order(:count).count
Stats.pluck(:industry)
Stats.load_sector_codes_from_tops
Instrument['BABA'].info.refresh

Stats.find_each &:sync_earning_dates
Stats.find_each {  |s| p (s.earning_dates.to_a + [s.next_earnings_date]).uniq.compact.sort }; nil

Stats.load_non_us_info
Instrument.rub.each &:info!
