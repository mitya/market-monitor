class CreateNews < ActiveRecord::Migration[6.1]
  def change
    create_table :news do |t|
      t.string :title, :body
      t.string :ticker
      t.string :tickers, array: true, index: true
      t.datetime :datetime, index: true
      t.integer :external_id
      t.string :url
      t.string :source
      t.timestamp :created_at
    end
  end
end
