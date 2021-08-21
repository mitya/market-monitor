class CreateExtremums < ActiveRecord::Migration[6.1]
  def change
    create_table :extremums do |t|
      t.string :ticker, index: true
      t.date :date, index: true
      t.decimal :value, :close, precision: 20, scale: 2
      t.string :kind
      t.integer :period, :last_low_in, :last_high_in
      t.timestamp :created_at
    end
  end
end
