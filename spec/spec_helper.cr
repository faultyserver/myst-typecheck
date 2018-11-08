require "spec"
require "../src/typecheck.cr"

# Assert that the type inferred type of the given source code
# matches the given type name. The type name should be the path
# that would be used to refer to that type in the given program.
def it_types(source : String, type_name : String, fake_file=__FILE__, line=__LINE__, file=__FILE__, end_line=__END_LINE__)
  it "types `#{source}` as `#{type_name}`", line: line, file: file, end_line: end_line do
    program = ::Myst::Parser.new(IO::Memory.new(source), fake_file).parse
    env, result = typecheck(program)
    result.name.should eq(type_name)
  end
end
def it_types(source : String, type_name : Regex, fake_file=__FILE__, line=__LINE__, file=__FILE__, end_line=__END_LINE__)
  it "types `#{source}` as `#{type_name}`", line: line, file: file, end_line: end_line do
    program = ::Myst::Parser.new(IO::Memory.new(source), fake_file).parse
    env, result = typecheck(program)
    result.name.should match(type_name)
  end
end

def it_types(source : String, *, environment : Hash(String, String), fake_file=__FILE__, line=__LINE__, file=__FILE__, end_line=__END_LINE__)
  it "types the environment of `#{source}`", line: line, file: file, end_line: end_line do
    program = ::Myst::Parser.new(IO::Memory.new(source), fake_file).parse
    env, result = typecheck(program)
    environment.each do |name, type|
      env.current_scope[name].name.should eq(type)
    end
  end
end

def it_does_not_type(source : String, message : Regex?=nil, fake_file=__FILE__, line=__LINE__, file=__FILE__, end_line=__END_LINE__)
  it "raises an error when typing `#{source}`", line: line, file: file, end_line: end_line do
    error = expect_raises(Exception) do
      program = ::Myst::Parser.new(IO::Memory.new(source), fake_file).parse
      typecheck(program)
    end

    if message
      (error.message || "").downcase.should match(message)
    end
  end
end


# Run typechecking on the given source, returning the environment
# generated by the program.
def typecheck(source : Myst::Node)
  Myst::TypeCheck.typecheck(source)
end

def typecheck(source : String)
  program = ::Myst::Parser.for_content(source).parse
  Myst::TypeCheck.typecheck(program)
end
