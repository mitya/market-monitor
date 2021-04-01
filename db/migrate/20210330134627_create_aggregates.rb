class CreateAggregates < ActiveRecord::Migration[6.1]
  def change
    create_table :aggregates do |t|
      t.string :ticker, null: false
      t.date :date, null: false
      t.boolean :current, default: false, null: false
      Aggregate::Accessors.each do |period|
        t.float "#{period.delete '_ago'}"
        t.float "#{period.delete '_ago'}_vol"
      end
      t.jsonb :data, default: {}
      t.timestamps
      t.index :ticker
      t.index [:ticker, :date], unique: true
    end
  end
end
