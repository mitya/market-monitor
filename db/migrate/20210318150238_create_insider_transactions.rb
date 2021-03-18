class CreateInsiderTransactions < ActiveRecord::Migration[6.1]
  def change
    create_table :insider_transactions do |t|
      t.string :ticker
      t.string :insider_name, :insider_title
      t.date :date, :filling_date
      t.string :kind
      t.integer :shares, :shares_final
      t.decimal :price, :cost, precision: 20, scale: 4
      t.string :sec_code
      t.string :source
      t.jsonb :data
      t.timestamps

      t.index :ticker
      t.index :date
    end
  end
end
