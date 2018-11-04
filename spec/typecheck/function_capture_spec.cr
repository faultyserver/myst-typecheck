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

  # Captured functions, when assigned to variables, act just like any other
  # normal variable. Without explicitly writing them as Calls (with
  # parentheses), the functor does not get called.
  it_types %q(
    def foo(a, b); b; end
    bar = &foo
    bar
  ), "Functor(foo)"


  # AnonymousFunctions are similar to FunctionCaptures, where the resulting
  # type is just the full Functor being defined.
  #
  # The name of an AnonymousFunction's Functor type is created using the file
  # location of the definition.
  it_types %q(
    fn ->() { } end
  ), /Functor\(.+eval_input:2:5\)/

  it_types %q(
    fn
      ->() { }
      ->(a, b) { a + b }
    end
  ), /Functor\(.+eval_input:2:5\)/


  # Assigning an anonymous function to a variable acts just like a function
  # capture to that variable.
  it_types %q(
    bar = fn ->(a, b) { b } end
    bar(1, 2)
  ), "Integer"

  # TODO:
  #   ? Test block parameters
end
