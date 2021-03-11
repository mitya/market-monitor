class Instrument < ApplicationRecord
  self.inheritance_column = nil
  has_many :candles, foreign_key: 'isin'
  has_many :day_candles, class_name: 'Candle', foreign_key: 'isin'

  scope :tinkoff, -> { where "'tinkoff' = any(flags)" }
  scope :abc, -> { order :ticker }

  def to_s = ticker
  def current = 1234

  def today     = @today     ||= day_candles.date_is(Date.today).take
  def yesterday = @yesterday ||= day_candles.date_before(Date.today).take
  def week_ago  = @week_ago  ||= day_candles.date_before(1.week.ago.to_date.tomorrow).take
  def month_ago = @month_ago ||= day_candles.date_before(1.month.ago.to_date.tomorrow).take
  def jan01     = @jan01     ||= day_candles.date_before(Date.today.beginning_of_year).take
  def mar20     = @mar20     ||= day_candles.date_before(Date.new 2020, 3, 20).take
  def nov08     = @nov08     ||= day_candles.date_before(Date.new 2020, 11, 8).take
  def bc        = @bc        ||= day_candles.date_before(Date.new 2020, 2, 20).take

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

  class << self
    def get(ticker = nil, figi: nil)
      figi ? find_by_figi(figi) : find_by_ticker(ticker.to_s.upcase)
    end
  end
end
