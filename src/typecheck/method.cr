module Myst
  module TypeCheck
    struct Clause
      property node : Def
      property parameters : Array(Type)
      property returns : Type

      def initialize(@node : Def, @parameters : Array(Type), @returns : Type)
      end

      def_equals_and_hash parameters, returns
    end

    struct Method
      property name : String
      property clauses : Array(Clause)

      def initialize(@name : String)
        @clauses = [] of Clause
      end

      def add_clause(node : Def, parameters : Array(Type), returns : Type)
        clauses.push(Clause.new(node, parameters, returns))
        self
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
