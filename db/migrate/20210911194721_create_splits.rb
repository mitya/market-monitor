class CreateSplits < ActiveRecord::Migration[6.1]
  def change
    create_table :splits do |t|
      t.string :ticker
      t.date :declared_date, :ex_date
      t.string :desc
      t.float :ratio
      t.integer :from_factor, :to_factor
      t.timestamp :created_at
    end
  end
end
