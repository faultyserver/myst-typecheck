require "../spec_helper.cr"

describe "Match Expressions" do
  # Match expressions are just a syntax sugar for Calls to AnonymousFunctions.
  # The resulting type is the same as a Calls invocation would be.
  it_types %q(
    match 1
      ->(1) { "hello" }
    end
  ), "String"

  it_types %q(
    match 1
      ->(a) { "hello" }
      ->(Integer) { 2 }
    end
  ), "Integer | String"

  # Like Calls, if a clause of the function can never match based on the types
  # of the arguments, it is not considered when determining the resulting type.
  it_types %q(
    match 1
      ->(a : String) { "hello" }
      ->(a : Integer) { 1 }
    end
  ), "Integer"
end
