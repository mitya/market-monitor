class CreateInstruments < ActiveRecord::Migration[6.1]
  def change
    create_table :instruments, id: false do |t|
      t.string :ticker, primary_key: true
      t.string :isin, index: { unique: true }
      t.string :figi, index: { unique: true }
      t.string :currency
      t.string :name, null: false
      t.string :type, null: false, default: 'Stock'
      t.integer :lot
      t.float :price_step
      t.string :flags, array: true, default: []
      t.boolean :has_logo
      t.string :exchange
      t.timestamps
    end
  end
end
