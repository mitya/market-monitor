class CreatePriceTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :price_targets do |t|
      t.string :ticker, null: false
      t.date :date
      t.decimal :high, :low, :average, precision: 20, scale: 4
      t.string :currency
      t.integer :analysts_count
      t.string :source
      t.timestamps
      t.index [:ticker, :date], unique: true
    end
  end
end
