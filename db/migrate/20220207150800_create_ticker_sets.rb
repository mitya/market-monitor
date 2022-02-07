class CreateTickerSets < ActiveRecord::Migration[6.1]
  def change
    create_table :ticker_sets do |t|
      t.string :key
      t.string :tickers, array: true
      t.timestamp :updated_at
    end
  end
end
