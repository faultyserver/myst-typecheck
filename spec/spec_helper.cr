require "spec"
require "../src/typecheck.cr"

# Assert that the type inferred type of the given source code
# matches the given type name. The type name should be the path
# that would be used to refer to that type in the given program.
def it_types(source : String, type_name : String, line=__LINE__, file=__FILE__, end_line=__END_LINE__)
  it "types `#{source}` as `#{type_name}`", line: line, file: file, end_line: end_line do
    program = Myst::Parser.for_content(source).parse
    typechecker = Myst::TypeCheck::Visitor.new
    resulting_type = typechecker.visit(program)
    resulting_type.name.should eq(type_name)
  end
end

def it_types(source : String, *, environment : Hash(String, String), line=__LINE__, file=__FILE__, end_line=__END_LINE__)
  it "types the environment of `#{source}`", line: line, file: file, end_line: end_line do
    program = Myst::Parser.for_content(source).parse
    typechecker = Myst::TypeCheck::Visitor.new
    typechecker.visit(program)
    environment.each do |name, type|
      typechecker.current_scope[name].name.should eq(type)
    end
  end
end


def typecheck(source : String, typechecker : Myst::TypeCheck::Visitor? = nil)
  program = Myst::Parser.for_content(source).parse
  typechecker ||= Myst::TypeCheck::Visitor.new
  typechecker.visit(program)
  typechecker
end
