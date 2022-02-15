class PriceLevelHit < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
  belongs_to :level, class_name: 'PriceLevel', optional: true

  scope :exact, -> { where exact: true }
  scope :important, -> { where important: true }
  scope :levels, -> { where source: 'level' }
  scope :ma, -> { where source: 'ma' }

  PositiveKinds = %w[up-break up-gap down-test].to_set

  before_validation do
    self.instrument ||= level&.instrument
    self.level_value ||= level&.value
    self.important = level.important if level
    self.manual = level.manual? if level
    self.positive = PositiveKinds.include?(kind)
    self.exact = true if exact == nil
  end

  before_save do
    self.continuation = instrument.level_hits.where(date: MarketCalendar.prev2(date)).any?
  end
  
  def loose? = !exact?
  def source_name = "#{source}#{ma_length}"
  def ma? = source == 'ma'  
end
