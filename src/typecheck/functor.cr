require "./type.cr"

module Myst
  module TypeCheck
    class Functor < Type
      record Clause,
        node : Def,
        call_cache = Hash(Array(Type), Type).new

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

      def clause_for(arguments : Array(Type))
        matching_clause =
          @clauses.find do |clause|
            next unless clause.parameters.size == arguments.size

            clause.parameters.each.with_index.all? do |param, idx|
              param == arguments[idx]
            end
          end

        matching_clause || raise "No matching clause for #{name} given #{arguments}"
      end

      def_equals_and_hash name, clauses
    end
  end
end
