class CreateArbitrageCases < ActiveRecord::Migration[6.1]
  def change
    create_table :arbitrage_cases do |t|
      t.string :ticker, index: true
      t.decimal :percent, precision: 8, scale: 2
      t.boolean :long, :delisted
      t.string :exchange_code
      t.decimal :spb_bid, precision: 20, scale: 4
      t.integer :spb_bid_size
      t.decimal :spb_ask, precision: 20, scale: 4
      t.integer :spb_ask_size
      t.decimal :foreign_bid, precision: 20, scale: 4
      t.integer :foreign_bid_size
      t.decimal :foreign_ask, precision: 20, scale: 4
      t.integer :foreign_ask_size
      t.date :date, index: true
      t.timestamps
      t.index [:ticker, :date]
    end
  end
end
