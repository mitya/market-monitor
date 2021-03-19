class CreateRecommendations < ActiveRecord::Migration[6.1]
  def change
    create_table :recommendations do |t|
      t.string :ticker, null: false, index: true
      t.integer :buy, :overweight, :hold, :underweight, :sell, :none
      t.float :scale, :scale15
      t.boolean :current, index: true
      t.date :corporate_action_date, :starts_on, :ends_on
      t.timestamps
    end
  end
end
