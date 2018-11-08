require "myst"
require "./ext/**"

require "./typecheck/**"


module Myst
  module TypeCheck
    extend self

    def typecheck(file_name : String)
      program = ::Myst::Parser.for_file(file_name).parse
      typecheck(program)
    end

    def typecheck(program : Node) : Tuple(Environment, Type)
      env = Environment.new

      # The ProgramExpander evaluates all `Require` nodes to create a single
      # program tree with all required files included.
      expander = ProgramExpander.new(env)
      expander.visit(program)

      # The DefVisitor scans the full program tree for all type and method
      # definitions. This allows the typechecker to understand all available
      # methods and types at every point of the main phase.
      def_visitor = DefVisitor.new(env)
      def_visitor.visit(program)

      # The MainVisitor performs the actual typechecking based on the
      # information gathered in previous phases, checking the entire program
      # tree in a single pass.
      main_visitor = MainVisitor.new(env)
      result = main_visitor.visit(program)

      {env, result}
    end
  end
end
