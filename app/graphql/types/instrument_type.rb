module Types
  class InstrumentType < Types::BaseObject
    field :isin, String, null: true
    field :figi, String, null: true
    field :ticker, String, null: false
    field :currency, String, null: true
    field :name, String, null: false
    field :type, String, null: false
    field :lot, Integer, null: true
    field :price_step, Float, null: true
    field :flags, [String], null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :has_logo, Boolean, null: true
    field :exchange, String, null: true
    field :iex_ticker, String, null: true
    field :first_date, GraphQL::Types::ISO8601Date, null: true
    
    # field :exchange_tocker, String, null: true
    
#     def full_name
#   # `object` references the user instance
#   [object.first_name, object.last_name].compact.join(" ")
# end
    
    field :price_target, Types::PriceTargetType, null: true
  end
end
