class CreateWatchedTargets < ActiveRecord::Migration[7.0]
  def change
    create_table :watched_targets do |t|
      t.string :ticker, null: false
      t.decimal :start_price, :expected_price, precision: 12, scale: 4
      t.timestamp :created_at
      t.timestamp :hit_at
    end
  end
end
