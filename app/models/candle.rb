class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'figi'
end
