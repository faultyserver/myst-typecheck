require "../spec_helper.cr"

describe "PatternMatcher" do
  # Any type should successfully match with itself. Currently, the checker
  # does not analyze literals to know if the _value_ matches (which may cause
  # a match failure at runtime).
  #
  # The return of a match expression is the right-side value type
  it_types %q(1 =: 1),        "Integer"
  it_types %q("a" =: "a"),    "String"
  it_types %q(1.0 =: 1.0),    "Float"
  it_types %q(true =: true),  "Boolean"
  it_types %q(:hi =: :hi),    "Symbol"
  it_types %q([] =: []),      "List"
  it_types %q({} =: {}),      "Map"

  # If a match is guaranteed to fail (i.e., the types of each side do not
  # overlap), the typechecker can accurately complain.
  it_does_not_type %q(1 =: "hello")
  it_does_not_type %q(false =: nil)
  it_does_not_type %q([] =: {})

  # Matches can assign variables based on the types on the right side.
  it_types %q(x =: 1), environment: { "x" => "Integer" }
  it_types %q(
    def foo; true; end
    x =: foo
  ), environment: { "x" => "Boolean" }

  # IVars, as always, get typed as T_ANY no matter what
  it_types %q(
    @x =: 1
    @x
  ), "Any"

  # Lists and maps recurse to check and assign the types of their elements.
  # However, this is currently very naive and assigns T_ANY to all elements
  # within them.
  #
  # Improvements for this include: implementing generics, implementing tuples
  # and named tuples for matches, and allowing type restrictions in match
  # patterns.
  it_types %q(
    [x, y] =: [1, 2]
  ), environment: {
    "x" => "Any",
    "y" => "Any"
  }

  # Even though this won't match, the typechecker isn't aware of that, since it
  # treats all list elements as `T_ANY`.
  it_types %q(
    [x, [y, z]] =: [1, 2]
  ), environment: {
    "x" => "Any",
    "y" => "Any",
    "z" => "Any",
  }

  it_types %q(
    {a: b} =: {}
  ), environment: {
    "b" => "Any"
  }

  it_types %q(
    {a: {b: b} } =: {}
  ), environment: {
    "b" => "Any"
  }


  # Splat collectors always assign the target variable as a List object.
  it_types %q(
    [_, *rest] =: [1, 2, 3]
  ), environment: {
    "rest" => "List"
  }
  it_types %q(
    [*rest, _] =: [1, 2, 3]
  ), environment: {
    "rest" => "List"
  }
  it_types %q(
    [_, *rest, _] =: [1, 2, 3]
  ), environment: {
    "rest" => "List"
  }


  # Matches can also assert the type of a value by naming a type in the pattern.
  it_types %q(Integer =: 1), "Integer"
  it_types %q(String =: "hello"), "String"
  it_does_not_type %q(Float =: nil)

  # This also works with user-defined types
  it_types %q(
    deftype Foo; end
    Foo =: %Foo{}
  ), "Foo"
end
