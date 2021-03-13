class Instrument < ApplicationRecord
  self.inheritance_column = nil
  has_many :candles, foreign_key: 'isin'
  has_many :day_candles, -> { where interval: 'day' }, class_name: 'Candle', foreign_key: 'isin'
  has_one :price, class_name: 'InstrumentPrice', foreign_key: 'figi', inverse_of: :instrument

  validates_presence_of :isin, :ticker, :name

  scope :tinkoff, -> { where "'tinkoff' = any(flags)" }
  scope :usd, -> { where currency: 'USD' }
  scope :abc, -> { order :ticker }
  scope :in_set, -> key { where ticker: InstrumentSet.get(key)&.unprefixed_symbols if key }
  scope :main, -> { in_set :main }
  scope :small, -> { in_set :small }

  def to_s = ticker

  def today     = @today     ||= day_candles!.find_date(Current.today)
  def yesterday = @yesterday ||= day_candles!.find_date(Current.yesterday)
  def week_ago  = @week_ago  ||= day_candles!.find_date_before(1.week.ago.to_date.tomorrow)
  def month_ago = @month_ago ||= day_candles!.find_date_before(1.month.ago.to_date.tomorrow)
  def jan04     = @jan04     ||= day_candles!.find_date(Date.new 2021, 1,  4)
  def mar23     = @mar23     ||= day_candles!.find_date(Date.new 2020, 3, 23)
  def nov06     = @nov06     ||= day_candles!.find_date(Date.new 2020, 11, 6)
  def bc        = @bc        ||= day_candles!.find_date(Date.new 2020, 2, 19)
  def last      = @last      ||= price!.value

  %w[usd eur rub].each { |currency| define_method("#{currency}?") { self.currency == currency.upcase } }

  %w[low high open close].each do |price|
    %w[yesterday today week_ago month_ago jan04 mar23 nov06 bc].each do |date|
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
