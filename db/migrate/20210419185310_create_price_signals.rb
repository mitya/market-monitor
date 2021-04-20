class CreatePriceSignals < ActiveRecord::Migration[6.1]
  def change
    create_table :price_signals do |t|
      t.string :ticker, null: false
      t.date :date, null: false
      t.date :base_date, null: false
      t.string :kind, null: false
      t.string :direction, null: false
      t.boolean :exact
      t.decimal :enter, :stop, precision: 20, scale: 4
      t.float :accuracy, :stop_size
      t.jsonb :data
      t.timestamp :created_at
    end
  end
end
