class CreateSpikes < ActiveRecord::Migration[6.1]
  def change
    create_table :spikes do |t|
      t.string :ticker, index: true
      t.date :date, index: true
      t.float :spike, :change
    end
  end
end
