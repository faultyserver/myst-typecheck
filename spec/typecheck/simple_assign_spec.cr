require "../spec_helper.cr"

describe "SimpleAssign" do
  it_types %q(x = 1.0), "Float"
  it_types %q(x = 1), environment: { "x" => "Integer" }
  it_types %q(x = 1; y = x), environment: { "y" => "Integer" }

  # Re-assigning a local replaces its type
  it_types %q(x = 1; x = "no"), environment: { "x" => "String" }

  # Different assignments do not affect each other
  it_types %q(
    x = 1
    y = false
  ), environment: {
    "x" => "Integer",
    "y" => "Boolean"
  }

  # Chained assignments affect all elements in the chain
  it_types %q(a = b = 2), environment: { "a" => "Integer", "b" => "Integer" }
end
