class CreatePublicSignals < ActiveRecord::Migration[6.1]
  def change
    create_table :public_signals do |t|
      t.string :ticker, null: false
      t.string :source, null: false
      t.date :date
      t.decimal :price, precision: 20, scale: 4
      t.integer :score
      t.timestamp :created_at
    end
  end
end
