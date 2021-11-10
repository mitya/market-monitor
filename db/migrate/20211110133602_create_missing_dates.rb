class CreateMissingDates < ActiveRecord::Migration[6.1]
  def change
    create_table :missing_dates do |t|
      t.string :ticker, index: true, null: false
      t.date :date, null: false
    end
  end
end
