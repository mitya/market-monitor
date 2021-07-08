class CreateOptionItemSpecs < ActiveRecord::Migration[6.1]
  def change
    create_table :option_item_specs do |t|
      t.string :code, :side, :ticker
      t.date :date
      t.decimal :strike, precision: 20, scale: 4
      t.string :desc
      t.timestamps
    end
  end
end
