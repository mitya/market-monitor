class CreateInstrumentPrices < ActiveRecord::Migration[6.1]
  def change
    create_table :prices, id: false do |t|
      t.primary_key :figi, :string
      t.string :ticker, null: false, index: { unique: true }
      t.decimal :value, precision: 20, scale: 4
      t.timestamp :updated_at
    end
  end
end