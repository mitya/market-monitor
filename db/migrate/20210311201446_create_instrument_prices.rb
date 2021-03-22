class CreateInstrumentPrices < ActiveRecord::Migration[6.1]
  def change
    create_table :prices, id: false do |t|
      t.primary_key :ticker
      t.decimal :value, precision: 20, scale: 4
      t.string :source
      t.timestamp :updated_at
      t.timestamp :last_at
    end
  end
end
