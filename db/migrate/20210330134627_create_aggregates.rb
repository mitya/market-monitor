class CreateAggregates < ActiveRecord::Migration[6.1]
  def change
    create_table :aggregates do |t|
      t.string :ticker, null: false
      t.date :date, null: false
      t.boolean :current, default: false, null: false
      Aggregate::Accessors.each do |period|
        t.float "#{period.remove '_ago'}"
        t.float "#{period.remove '_ago'}_vol" if period.include?('ago')
      end
      t.integer :days_up
      t.jsonb :data, default: {}
      t.date :lowest_day_date
      t.float :lowest_day_gain
      t.timestamps
      t.index :ticker
      t.index [:ticker, :date], unique: true
    end
  end
end
