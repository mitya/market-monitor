class Instrument < ApplicationRecord
  self.inheritance_column = nil

  has_many :candles, foreign_key: 'ticker', dependent: :delete_all
  has_many :day_candles, -> { where interval: 'day' }, class_name: 'Candle', foreign_key: 'ticker'
  has_one :price, class_name: 'InstrumentPrice', foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :info, class_name: 'InstrumentInfo',   foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete

  validates_presence_of :isin, :ticker, :name

  scope :tinkoff, -> { where "'tinkoff' = any(flags)" }
  scope :spb, -> { where "'spb' = any(flags)" }
  scope :iex, -> { joins :info }
  scope :usd, -> { where currency: 'USD' }
  scope :abc, -> { order :ticker }
  scope :in_set, -> key { where ticker: InstrumentSet.get(key)&.unprefixed_symbols if key }
  scope :main, -> { in_set :main }
  scope :small, -> { in_set :small }

  def to_s = ticker

  def today         = @today     ||= day_candles!.find_date(Current.today)
  def yesterday     = @yesterday ||= day_candles!.find_date(Current.yesterday)
  def daybeforelast = @daybeforelast ||= day_candles!.find_date(Current.yesterday.yesterday)
  def week_ago      = @week_ago  ||= day_candles!.find_date_before(1.week.ago.to_date)
  def month_ago     = @month_ago ||= day_candles!.find_date_before(1.month.ago.to_date)
  def feb19         = @feb19     ||= day_candles!.find_date(Date.new 2020,  2, 19)
  def mar23         = @mar23     ||= day_candles!.find_date(Date.new 2020,  3, 23)
  def nov06         = @nov06     ||= day_candles!.find_date(Date.new 2020, 11,  6)
  def y2019         = @y2019     ||= day_candles!.find_date(Date.new 2019,  1,  3)
  def y2020         = @y2020     ||= day_candles!.find_date(Date.new 2020,  1,  3)
  def y2021         = @y2021     ||= day_candles!.find_date(Date.new 2021,  1,  4)
  def last          = @last      ||= price!.value
  def last_or_open  = last || today_open

  %w[usd eur rub].each { |currency| define_method("#{currency}?") { self.currency == currency.upcase } }

  %w[low high open close].each do |price|
    %w[today yesterday daybeforelast week_ago month_ago feb19 mar23 nov06 y2019 y2020 y2021].each do |date|
      define_method("#{date}_#{price}") { send(date).try(price) }
      define_method("#{date}_#{price}_rel") { |curr_price = 'last'| rel_diff "#{date}_#{price}", curr_price }
      define_method("#{date}_#{price}_diff") { |curr_price = 'last'| diff "#{date}_#{price}", curr_price }
    end
  end

  attribute :current_price_selector, default: "last"

  def diff(old_price, new_price = current_price_selector)
    old_price, new_price = send(old_price), send(new_price)
    new_price - old_price if old_price && new_price
  end

  def rel_diff(old_price, new_price = current_price_selector)
    old_price, new_price = send(old_price), send(new_price)
    new_price / old_price - 1.0 if old_price && new_price
  end

  def logo_path = Pathname("public/logos/#{ticker}.png")
  def check_logo = update_column(:has_logo, logo_path.exist?)

  def price! = Current.prices_cache&.for_instrument(self) || price || create_price!
  def day_candles! = Current.day_candles_cache ? Current.day_candles_cache.scope_to_instrument(self) : day_candles

  def iex? = info.present?

  class << self
    def get(ticker = nil, figi: nil)
      return ticker if self === ticker
      figi ? find_by_figi(figi) : find_by_ticker(ticker.to_s.upcase)
    end
  end
end

__END__
Instrument.find_each &:check_logo
Instrument.find_each &:price!

Candle.day.where(ticker: 'BGS', date: Current.date)
Instrument.get('BGS').day_candles.where(date: Current.date)
puts Instrument.get('BGS').today_open
Instrument.get('CCL').nov06_low
Instrument.get('CCL').today_open
Instrument.join(:info).count
