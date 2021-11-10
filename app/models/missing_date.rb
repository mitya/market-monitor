class MissingDate < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'
end
