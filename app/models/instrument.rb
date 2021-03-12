class Instrument < ApplicationRecord
  self.inheritance_column = nil
  has_many :candles, foreign_key: 'isin'
  has_many :day_candles, class_name: 'Candle', foreign_key: 'isin'
  has_one :price, class_name: 'InstrumentPrice', foreign_key: 'figi', inverse_of: :instrument

  scope :tinkoff, -> { where "'tinkoff' = any(flags)" }
  scope :usd, -> { where currency: 'USD' }
  scope :abc, -> { order :ticker }

  def to_s = ticker

  def today     = @today     ||= day_candles.date_is(Current.date).take
  def yesterday = @yesterday ||= day_candles.date_before(Current.date).take
  def week_ago  = @week_ago  ||= day_candles.date_before(1.week.ago.to_date.tomorrow).take
  def month_ago = @month_ago ||= day_candles.date_before(1.month.ago.to_date.tomorrow).take
  def jan01     = @jan01     ||= day_candles.date_before(Current.date.beginning_of_year).take
  def mar20     = @mar20     ||= day_candles.date_before(Date.new 2020, 3, 20).take
  def nov08     = @nov08     ||= day_candles.date_before(Date.new 2020, 11, 8).take
  def bc        = @bc        ||= day_candles.date_before(Date.new 2020, 2, 20).take
  def current   = @current   ||= price.value

  %w[usd eur rub].each { |currency| define_method("#{currency}?") { self.currency == currency.upcase } }

  %w[low high open close].each do |price|
    %w[yesterday today week_ago month_ago jan01 mar20 nov08 bc].each do |date|
      define_method("#{date}_#{price}") { send(date).try(price) }

      define_method("#{date}_#{price}_rel") do |curr_price = 'current'|
        base, curr = send("#{date}_#{price}"), send(curr_price)
        curr / base if curr && base
      end

      define_method("#{date}_#{price}_diff") do |curr_price = 'current'|
        base, curr = send("#{date}_#{price}"), send(curr_price)
        curr - base if curr && base
      end

      define_method("#{date}_#{price}_rel_diff") do |curr_price = 'current'|
        diff, curr = send("#{date}_#{price}_diff", curr_price), send(curr_price)
        diff / curr if diff && curr
      end
    end
  end

  def logo_path = Pathname("public/logos/#{ticker}.png")
  def check_logo = update_column(:has_logo, logo_path.exist?)

  def price! = price || create_price!

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
