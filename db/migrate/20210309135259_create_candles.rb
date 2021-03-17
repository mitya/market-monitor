class CreateCandles < ActiveRecord::Migration[6.1]
  def change
    create_table :candles do |t|
      t.string :ticker, index: true
      t.string :interval, null: false
      t.datetime :date, null: false
      t.datetime :time, null: false
      t.decimal :open, :close, :high, :low, null: false, precision: 20, scale: 4
      t.integer :volume, null: false
      t.string :source
      t.boolean :ongoing, default: false, null: false
      t.timestamps
      t.index [:ticker, :interval, :date], unique: true
    end
  end
end
