module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    field :test_field, String, null: false, description: "An example field added by the generator"
    field :instruments, [Types::InstrumentType], null: false, description: "Lists the instruments"
    
    def test_field
      "Hello World!"
    end
    
    def instruments
      Instrument.preload(:price_target).first(50)
    end
  end
end
