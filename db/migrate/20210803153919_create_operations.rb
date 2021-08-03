class CreateOperations < ActiveRecord::Migration[6.1]
  def change
    create_table :operations do |t|
      t.string :ticker, null: false
      t.string :kind, :status
      t.datetime :datetime
      t.integer :lots, :lots_executed
      t.decimal :price, :payment, :commission, precision: 20, scale: 2
      t.string :currency
      t.integer :trades_count
      t.timestamps
    end
  end
end
