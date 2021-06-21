class CreateInsiderSummaries < ActiveRecord::Migration[6.1]
  def change
    create_table :insider_summaries do |t|
      t.string :ticker, null: false
      t.string :name, :title
      t.integer :net, :bought, :sold
      t.date :date
      t.string :source
      t.timestamps
    end
  end
end
