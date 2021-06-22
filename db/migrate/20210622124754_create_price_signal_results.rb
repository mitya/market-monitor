class CreatePriceSignalResults < ActiveRecord::Migration[6.1]
  def change
    create_table :price_signal_results do |t|
      t.string :ticker, null: false
      t.references :signal, null: false, foreign_key: { to_table: :price_signals }
      t.boolean :entered, :stopped
      t.float :d1_close, :d1_max, :d2_close, :d2_max, :w1_close, :w1_max, :w1_max_close
      t.timestamps
    end
  end
end
