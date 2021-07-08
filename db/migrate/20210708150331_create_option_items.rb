class CreateOptionItems < ActiveRecord::Migration[6.1]
  def change
    create_table :option_items do |t|
      t.string :code, :ticker, :side
      t.date :date
      t.decimal :strike, precision: 20, scale: 4
      t.integer :open_interest
      t.integer :volume
      t.decimal :open, :close, precision: 20, scale: 4
      t.timestamp :created_at
      t.date :updated_on
      t.index :ticker
      t.index [:code, :updated_on], unique: true
    end
  end
end
