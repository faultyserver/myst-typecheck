require "../spec_helper.cr"

describe "Instantiation" do
  # Instantiations return the instance type of a given static type.
  it_types %q(%Nil{}), "Nil"
  it_types %q(%Boolean{}), "Boolean"
  it_types %q(%Integer{}), "Integer"
  it_types %q(%Float{}), "Float"
  it_types %q(%String{}), "String"
  it_types %q(%Symbol{}), "Symbol"
  it_types %q(%List{}), "List"
  it_types %q(%Map{}), "Map"
  it_types %q(%Type{}), "Type"

  it "does not allow instantiation of instance types" do
    # 1 is an _instance type_ of the Integer _static type_.
    expect_raises(Exception) do
      tc = typecheck(%q(%<1>{}))
    end
  end

  it "does not allow instantiation of modules" do
    expect_raises(Exception) do
      tc = typecheck(%q(
        defmodule Foo; end
        %<Foo>{}
      ))
    end
  end

  # Instantiation should work with user-defined types as well.
  it_types %q(
    deftype Foo; end
    %Foo{}
  ), "Foo"

  # The arguments given to an instantiation have no effect on the return type,
  # since an instantiation _must_ return a new instance of the given type.
  it_types %q(
    deftype Foo
      def initialize(a, b, c, d, e); end
    end

    %Foo{1, 2, 3, 4, 5}
  ), "Foo"
end
