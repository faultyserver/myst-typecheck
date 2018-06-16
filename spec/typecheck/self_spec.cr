require "../spec_helper.cr"

describe "Self" do
  # Not much to this, just return the type of the current value of `self`.
  # This is contextual, and should probably be updated with more tests as
  # different contexts are supported (modules, types, methods, etc.)
  #
  # However, leaking the type of `self` requires method lookup and evaluation,
  # which is not currently supported.
  it_types %q(self), "main"
end
