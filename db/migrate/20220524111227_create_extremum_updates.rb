class CreateExtremumUpdates < ActiveRecord::Migration[7.0]
  def change
    create_enum :extremum_update_kind, %w[high low]
    create_table :extremum_updates do |t|
      t.string :ticker, null: false, index: true
      t.date :date, null: false, index: true
      t.decimal :price, null: false, precision: 12, scale: 4
      t.enum :kind, null: false, enum_type: 'extremum_update_kind'
      t.integer :volume
      t.date :last_on
      t.timestamp :created_at
    end
  end
end
