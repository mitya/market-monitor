class PriceLevelHit < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  belongs_to :level, class_name: 'PriceLevel', optional: true

  scope :exact, -> { where exact: true }
  scope :important, -> { where important: true }
  scope :levels, -> { where source: 'level' }
  scope :ma, -> { where source: 'ma' }
  scope :intraday, -> { where.not time: nil }
  scope :today, -> { where date: Current.date }

  PositiveKinds = %w[up-break up-gap down-test].to_set

  before_validation do
    self.instrument ||= level&.instrument
    self.level_value ||= level&.value
    self.important = level.important?.presence if level
    self.manual = level.manual?.presence if level
    self.positive = PositiveKinds.include?(kind) if positive == nil
  end

  before_save do
    next if intraday?
    self.continuation = instrument.level_hits.where(date: MarketCalendar.prev2(date)).any?
  end

  def inspect = "<Hit##{id} #{ticker} #{date} #{source}#{ma_length} #{level_value}>"
  def source_name = "#{source}#{ma_length}"

  def loose? = !exact?
  def ma? = source == 'ma'
  def watch? = kind == 'watch'
  def intraday? = time != nil

  memoize def datetime = instrument!.time_zone.parse("#{date} #{time.to_hhmm}")
  def instrument! = PermaCache.instrument(ticker)

  def check_importance!
    return if important?
    sibling_params = ma?? { source:, ma_length: } : { level_value: }
    update! important: !instrument.level_hits.where(sibling_params).where('date > ?', 2.weeks.ago).exists?    
  end
end
