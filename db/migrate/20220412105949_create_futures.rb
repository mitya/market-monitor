class CreateFutures < ActiveRecord::Migration[7.0]
  def change
    create_table :futures, id: false do |t|
      t.string :ticker, primary_key: true
      t.string :base_ticker
      t.integer :base_lot
      t.date :expiration_date
    end
  end
end
