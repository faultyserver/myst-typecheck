require "./type.cr"

module Myst
  module TypeCheck
    class Functor < Type
      struct Clause
        property node : Def
        property call_cache = Hash(Array(Type), Type).new

        def initialize(@node : Def)
        end

        delegate body, params, block_param, block_param?, return_type, return_type?,
          to: node
      end


      property name : String
      property clauses : Array(Clause)

      def initialize(name : String)
        super(name)
        @clauses = [] of Clause
      end

      def add_clause(node : Def)
        clauses.push(Clause.new(node))
        self
      end

      def name
        "Functor(#{@name})"
      end


      def_equals_and_hash name, clauses
    end
  end
end
