require "../spec_helper.cr"

describe "Self" do
  # Not much to this, just return the type of the current value of `self`.
  # This is contextual, and should probably be updated with more tests as
  # different contexts are supported (modules, types, methods, etc.)
  it_types %q(self), "main"


  it_types %q(
    deftype Foo
      def get_self; self; end
    end

    %Foo{}.get_self
  ), "Foo"

  # `self` inside of static methods leak the static type
  it_types %q(
    deftype Foo
      defstatic get_self; self; end
    end

    Foo.get_self
  ), "Type(Foo)"

  # `self` inside of static methods leak the static type
  it_types %q(
    defmodule Foo
      def get_self; self; end
    end

    Foo.get_self
  ), "Foo"
end
