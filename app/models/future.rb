class Future < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker', inverse_of: :future
end
