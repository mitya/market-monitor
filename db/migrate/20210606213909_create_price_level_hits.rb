class CreatePriceLevelHits < ActiveRecord::Migration[6.1]
  def change
    create_table :price_level_hits do |t|
      t.string :ticker, null: false
      t.references :level, null: false, foreign_key: { to_table: 'price_levels' }
      t.decimal :level_value, precision: 20, scale: 4
      t.string :kind
      t.date :date
      t.timestamps
    end
  end
end
