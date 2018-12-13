require "../spec_helper.cr"

describe "Inheritance and Composition" do
  # Types that inherit from some super type are considered as matching that
  # super type in all instances where types are checked.

  it_types %(
    deftype Foo; end
    deftype Bar : Foo; end

    def foo(_f : Foo); 1; end

    foo(%Bar{})
  ), "Integer"

  # While subtypes match their supertypes, the subtype information is not lost
  # during evaluation.
  it_types %(
    deftype Foo; end
    deftype Bar : Foo; end

    def foo(b : Foo); b; end

    foo(%Bar{})
  ), "Bar"

  # Supertypes are not considered as matching to their subtypes.
  it_does_not_type %(
    deftype Foo; end
    deftype Bar : Foo; end

    def foo(b : Bar); 1; end

    foo(%Foo{})
  ), /no matching clause/
end
