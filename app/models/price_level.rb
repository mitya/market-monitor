class PriceLevel < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  has_many :hits, class_name: 'PriceLevelHit', foreign_key: 'level_id', dependent: :delete_all

  scope :manual, -> { where manual: true }
  scope :auto, -> { where manual: nil }
  scope :important, -> { where important: true }

  HISTORY_START = Date.parse('2020-01-01')
  ACCURACY = 0.02
  PERIOD = 15

  def candles = instrument.candles.day.where(date: dates)
  def calc_total_volume = candles.map(&:volume).sum
  def calc_average_volume = candles.map(&:volume).average
  def cache_volume = update!(total_volume: calc_total_volume, average_volume: calc_average_volume)
  def value_plus(delta) = value + value * delta
  def inspect = "<Level #{ticker} #{value} #{period}>".strip
  def source_type = kind == 'MA' ? 'ma' : 'level'
  def ma? = kind == 'MA'
  def direct? = !ma?


  class << self
    memoize def textual
      Pathname("db/levels.txt").readlines(chomp: true).map do |line|
        next [] if line.blank?
        ticker, *values = line.split
        [ticker.upcase, values.map { PriceLevel.new(ticker: ticker.upcase, value: _1, manual: true) }]
      end.to_h
    end
  end


  class Extremum
    attr :candle, :selector

    def initialize(candle, selector) = (@candle, @selector = candle, selector)
    def high? = @selector == 'high'
    def low?  = @selector == 'low'
    def value = @candle.send(@selector)
    def date  = @candle.date
  end
end

__END__
PriceLevel.textual
