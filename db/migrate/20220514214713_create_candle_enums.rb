class CreateCandleEnums < ActiveRecord::Migration[7.0]
  def change
    create_enum :candle_interval, %w[day hour m5 m3 m1]
    create_enum :candle_source, %w[tinkoff iex virtual close]
  end
end
