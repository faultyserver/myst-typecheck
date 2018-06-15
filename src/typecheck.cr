require "myst"

require "./typecheck/**"

module Myst
  module TypeCheck
    extend self

    def typecheck(source : String) : Tuple(Environment, Type)
      program = ::Myst::Parser.for_content(source).parse
      env = Environment.new

      def_visitor = DefVisitor.new(env)
      def_visitor.visit(program)

      main_visitor = MainVisitor.new(env)
      result = main_visitor.visit(program)

      {env, result}
    end
  end
end
