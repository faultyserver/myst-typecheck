require "../spec_helper.cr"

describe "Function Captures" do
  # Function captures are actually very simple to type. Since Functors are
  # given their own unique type representation, the only assertion that has
  # to be made is that the value of the capture is indeed a Functor.
  #
  # The resulting type of a function capture is just the functor type being
  # captured.
  it_types %q(
    def foo; end

    &foo
  ), "Functor(foo)"

  # Capturing allows reaching into modules, types, and instances to pull out
  # functions.
  it_types %q(
    defmodule Foo
      def foo; end
    end

    &Foo.foo
  ), "Functor(foo)"

  it_types %q(
    deftype Foo
      defstatic foo; end
    end

    &Foo.foo
  ), "Functor(foo)"

  it_types %q(
    deftype Foo
      def foo; end
    end

    &(%Foo{}.foo)
  ), "Functor(foo)"

  # Captured functions should be directly invocable.
  it_types %q(
    def foo(a, b); b; end
    bar = &foo
    bar(1, 2)
  ), "Integer"

  # TODO:
  #   - Add support for anonymous functions.
  #   ? Test block parameters
end
