require "../spec_helper.cr"

describe "Require" do
  # Require loads code from another file into a subtree in the program. The
  # typechecker is only able to work with `require` expressions that have a
  # static path given, otherwise the result is only determinable at runtime.
  #
  # The typechecker _does_ load the code from those require expressions and
  # the code that follows should be able to reference it as if the other file
  # was pasted in place of the `require` expression.
  #
  # Currently, `require` is implemented by copying the file resolution logic
  # from the Myst interpreter. This is not safe in the long term and should
  # change to call out to Myst itself for this resolution to ensure perfect
  # consistency. Myst needs to change to support this first.

  # `./support/foo.mt` defines a method `foo` that returns a Symbol
  it_types %q(
    require "./support/foo.mt"
    foo()
  ), "Symbol"

  it_does_not_type %q(
    require "./support/foo.mt"
    bar()
  ), /no function with the name `bar` exists for type `main`/

  # The `require` expression itself always returns a boolean.
  it_types %q(
    require "./support/foo.mt"
  ), "Boolean"
  it_types %q(
    require "./support/foo.mt"
    require "./support/foo.mt"
  ), "Boolean"


  # If the requested file does not exist or is not readable, the typechecker
  # notices and raises an error.
  it_does_not_type %q(
    require "./support/something_that_does_not_exist.mt"
  ), /file either doesn't exist or is not readable/
end
