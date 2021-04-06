class CreateStatss < ActiveRecord::Migration[6.1]
  def change
    create_table :instrument_infos, id: false do |t|
      t.primary_key :ticker, :string
      t.string :name, :industry, :sector, :country
      t.bigint :marketcap, :shares
      t.float :beta, :pe, :dividend_yield
      t.date :next_earnings_date, :ex_divident_date
      t.jsonb :company
      t.timestamp :company_updated_at
      t.jsonb :stats
      t.timestamp :stats_updated_at
      t.timestamps
    end
  end
end
