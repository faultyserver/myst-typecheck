require "myst"

require "./visitor.cr"

program = Myst::Parser.for_content(%q(
  deftype Integer
    def +(other : Integer) : Integer; end
    def +(other : Float) : Float; end
  end

  deftype Float
    def +(other : Integer) : Float; end
    def +(other : Float) : Float; end
  end

  x = 2.0 + 3
  y = 1 + 2.0
  z = x + y
)).parse

typechecker = Myst::TypeCheck::Visitor.new
typechecker.visit(program)

puts typechecker.current_scope["z"]
