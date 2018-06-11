require "../spec_helper.cr"

describe "Self" do
  # Not much to this, just return the type of the current value of `self`.
  # This is contextual, and should probably be updated with more tests as
  # different contexts are supported (modules, types, methods, etc.)
  it_types %q(
    x = nil
    deftype Foo
      x = self
    end
  ), environment: { "x" => "Foo" }
end
