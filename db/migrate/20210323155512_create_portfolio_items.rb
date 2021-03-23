class CreatePortfolioItems < ActiveRecord::Migration[6.1]
  def change
    create_table :portfolio_items, id: false do |t|
      t.primary_key :ticker, :string
      t.integer :lots
      t.string :lots_expr
      t.decimal :price, precision: 20, scale: 4
      t.timestamps
    end
  end
end
