class CreateInstrumentAnnotations < ActiveRecord::Migration[6.1]
  def change
    create_table :instrument_annotations do |t|
      t.string :ticker, null: false
      t.decimal :intraday_levels, precision: 20, scale: 4, array: true
      t.timestamp :updated_at
    end
  end
end
