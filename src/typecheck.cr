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


  def infer_return
    x = 2.0 + 3
    y = 1 + 2.0
    z = x + y
  end

  def infer_return(a : Integer)
    "no"
  end

  a = infer_return
  b = infer_return(1)
)).parse

typechecker = Myst::TypeCheck::Visitor.new
typechecker.visit(program)

typechecker.current_scope.each do |name, type|
  puts "#{name} : #{type}"
end
