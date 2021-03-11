class CreateCandles < ActiveRecord::Migration[6.1]
  def change
    create_table :candles do |t|
      t.string :isin, index: true
      t.string :ticker, index: true
      t.string :interval, null: false
      t.datetime :date
      t.datetime :time, null: false
      t.decimal :open, :close, :high, :low, null: false, precision: 20, scale: 4
      t.integer :volume, null: false
      t.string :source
      t.timestamp :created_at, null: false, default: -> { 'current_date' }

      t.foreign_key :instruments, column: :isin, primary_key: :isin
      t.index [:isin, :interval, :date], unique: true
    end
  end
end
