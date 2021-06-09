class CreatePriceLevels < ActiveRecord::Migration[6.1]
  def change
    create_table :price_levels do |t|
      t.string :ticker, null: false
      t.decimal :value, precision: 20, scale: 4
      t.float :accuracy
      t.integer :period
      t.string :kind
      t.boolean :important, :manual
      t.date :dates, array: true
      t.integer :total_volume, :average_volume
      t.timestamps
    end
  end
end
