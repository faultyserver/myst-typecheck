require "myst"

require "./visitor.cr"

program = Myst::Parser.for_content(%q(
  deftype Nil; end
  deftype Boolean; end
  deftype Integer; end
  deftype Float; end
  deftype String; end
  deftype Symbol; end
  deftype Type; end
  deftype Module; end
)).parse

typechecker = Myst::TypeCheck::Visitor.new

puts typechecker.visit(program)

typechecker.types.values.each do |t|
  puts t
end
