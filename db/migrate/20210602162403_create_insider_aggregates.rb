class CreateInsiderAggregates < ActiveRecord::Migration[6.1]
  def change
    create_table :insider_aggregates do |t|
      t.string :ticker, null: false

      t.bigint  :m1_buys_total
      t.decimal :m1_buys_avg, precision: 20, scale: 4
      t.bigint  :m1_sells_total
      t.decimal :m1_sells_avg, precision: 20, scale: 4

      t.bigint  :m2_buys_total
      t.decimal :m2_buys_avg, precision: 20, scale: 4
      t.bigint  :m2_sells_total
      t.decimal :m2_sells_avg, precision: 20, scale: 4

      t.bigint  :m3_buys_total
      t.decimal :m3_buys_avg, precision: 20, scale: 4
      t.bigint  :m3_sells_total
      t.decimal :m3_sells_avg, precision: 20, scale: 4

      t.bigint  :m6_buys_total
      t.decimal :m6_buys_avg, precision: 20, scale: 4
      t.bigint  :m6_sells_total
      t.decimal :m6_sells_avg, precision: 20, scale: 4

      t.string :sa_1_score
      t.string :sa_1_price
      t.string :sa_2_score
      t.string :sa_2_price
      t.string :sa_3_score
      t.string :sa_3_price

      t.timestamps
    end
  end
end
