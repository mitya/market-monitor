class CreatePriceSignalResults < ActiveRecord::Migration[6.1]
  def change
    create_table :price_signal_results do |t|
      t.string :ticker, null: false
      t.references :signal, null: false, foreign_key: { to_table: :price_signals }
      t.boolean :entered, :stopped
      t.float :d1_close, :d1_max
      t.float :d2_close, :d2_max
      t.float :d3_close, :d3_max
      t.float :d4_close, :d4_max
      t.float :w1_close, :w1_max
      t.float :w2_close, :w2_max
      t.float :w3_close, :w3_max
      t.float :m1_close, :m1_max
      t.float :m2_close, :m2_max
      t.timestamps
    end
  end
end
