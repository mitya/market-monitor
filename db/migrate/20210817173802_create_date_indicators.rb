class CreateDateIndicators < ActiveRecord::Migration[6.1]
  def change
    create_table :date_indicators do |t|
      t.string :ticker, null: false
      t.date :date, null: false
      t.boolean :current, default: false, null: false, index: true
      t.decimal :ema_20, :ema_50, :ema_200, precision: 20, scale: 2
      t.integer :ema_20_trend, :ema_50_trend, :ema_200_trend
      t.timestamps

      t.index :ticker
      t.index [:ticker, :date], unique: true
      t.index [:ticker, :current], unique: true      
    end
  end
end
