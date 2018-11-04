require "../spec_helper.cr"

describe "ModuleDef" do
  # ModuleDefs return the module type they define. Unlike TypeDef, ModuleDef
  # only creates a static type, so the name is just the given name for the
  # module (instead of `Module(Foo)` to differentiate static vs instance types)
  it_types %q(defmodule Foo; end), "Foo"

  it "creates a new type in the current scope" do
    env, _ = typecheck(%q(
      defmodule Foo; end
    ))

    env.current_scope.has_key?("Foo").should eq(true)
  end

  it "allows re-opening existing types" do
    env, _ = typecheck(%q(
      defmodule Foo; end
      defmodule Foo; end
    ))

    env.current_scope.has_key?("Foo").should eq(true)
  end

  it "handles modules defined within other modules" do
    env, _ = typecheck(%q(
      defmodule Foo
        defmodule Bar; end
        defmodule Baz; end
      end
    ))

    foo = env.current_scope["Foo"]
    foo.scope.has_key?("Bar").should eq(true)
    foo.scope.has_key?("Baz").should eq(true)
  end

  it "handles modules defined within types" do
    env, _ = typecheck(%q(
      deftype Foo
        defmodule Bar; end
        defmodule Baz; end
      end
    ))

    foo = env.current_scope["Foo"]
    foo.scope.has_key?("Bar").should eq(true)
    foo.scope.has_key?("Baz").should eq(true)
  end

  it "handles nested modules with the same name" do
    env, _ = typecheck(%q(
      defmodule Foo
        defmodule Foo; end
      end
    ))

    base_foo  = env.current_scope["Foo"]
    foo_foo   = base_foo.scope["Foo"]
    base_foo.should_not eq(foo_foo)
  end

  it "handles modules within types with the same name" do
    env, _ = typecheck(%q(
      deftype Foo
        defmodule Foo; end
      end
    ))

    base_foo  = env.current_scope["Foo"]
    foo_foo   = base_foo.scope["Foo"]
    base_foo.should_not eq(foo_foo)
  end

  it "handles modules with the same name in different namespaces" do
    env, _ = typecheck(%q(
      defmodule Foo; end
      deftype Bar;
        defmodule Foo; end
      end
    ))

    base_foo  = env.current_scope["Foo"]
    bar       = env.current_scope["Bar"]
    bar_foo   = bar.scope["Foo"]
    base_foo.should_not eq(bar_foo)
  end
end
