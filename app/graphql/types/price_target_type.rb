module Types
  class PriceTargetType < Types::BaseObject
    field :id, ID, null: false
    field :ticker, String, null: false
    field :date, GraphQL::Types::ISO8601Date, null: true
    field :high, Float, null: true
    field :low, Float, null: true
    field :average, Float, null: true
    field :currency, String, null: true
    field :analysts_count, Integer, null: true
    field :source, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :current, Boolean, null: true
  end
end
