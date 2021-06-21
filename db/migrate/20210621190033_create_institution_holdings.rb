class CreateInstitutionHoldings < ActiveRecord::Migration[6.1]
  def change
    create_table :institution_holdings do |t|
      t.string :ticker, null: false
      t.string :holder, null: false, index: true
      t.integer :shares, :shares_na
      t.integer :value
      t.date :date, :reported_on
      t.timestamps
    end
  end
end


# {
#   "symbol": "CLF",
#   "entityProperName": "CITADEL ADVISORS LLC",
#   "adjHolding": 8134483,
#   "reportedHolding": 8134483,
#   "adjMv": 44901,
#   "reportDate": 1593475200000,
#   "date": 1607472000000,
#   "filingDate": "2020-06-30",
# },
