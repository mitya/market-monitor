class Extremum < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
end
