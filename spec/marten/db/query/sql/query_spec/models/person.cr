module Marten::DB::Query::SQL::QuerySpec
  class Person < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :email, :string, max_size: 255
    field :address, :many_to_one, to: Marten::DB::Query::SQL::QuerySpec::Address

    def __query_spec_address
      @address
    end
  end
end
