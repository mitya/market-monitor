class CreateOrderbooks < ActiveRecord::Migration[6.1]
  def change
    create_table :orderbooks do |t|
      t.string :ticker
      t.string :status
      t.jsonb :bids
      t.jsonb :asks
      t.decimal :last, precision: 20, scale: 4
      t.timestamps
    end
  end
end
