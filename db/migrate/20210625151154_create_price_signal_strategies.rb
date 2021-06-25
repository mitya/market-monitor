class CreatePriceSignalStrategies < ActiveRecord::Migration[6.1]
  def change
    create_table :price_signal_strategies do |t|
      t.string :signal
      t.string :direction
      t.daterange :period
      t.numrange :change, :spy_change
      t.numrange :prev_1w_low, :prev_2w_low, :prev_1w_high, :prev_2w_high, :next_1d_change, :next_1d_open, :next_1d_close

      t.integer :count, :entered_count, :stopped_count
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
