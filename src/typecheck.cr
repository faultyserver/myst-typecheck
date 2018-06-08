require "myst"

require "./visitor.cr"

program = Myst::Parser.for_content(%q(
  deftype Integer
    def +(other : Integer) : Integer; end
    def +(other : Float) : Float; end
  end

  x = 2 + 3.0
)).parse

typechecker = Myst::TypeCheck::Visitor.new
typechecker.visit(program)

puts typechecker.current_scope["x"]
