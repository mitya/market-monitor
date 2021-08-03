class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders do |t|
      t.bigint :account_id
      t.string :ticker, null: false
      t.string :operation, :kind, :status
      t.integer :lots, :executed_lots
      t.decimal :price, precision: 20, scale: 4
      t.timestamps
    end
  end
end
