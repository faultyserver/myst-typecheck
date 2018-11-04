require "../spec_helper.cr"

describe "TypeDef" do
  # typedefs return the static type they define
  it_types %q(deftype Foo; end), "Type(Foo)"

  it "creates a new type in the current scope" do
    env, _ = typecheck(%q(
      deftype Foo; end
    ))

    env.current_scope.has_key?("Foo").should eq(true)
  end

  it "allows re-opening existing types" do
    env, _ = typecheck(%q(
      deftype Foo; end
      deftype Foo; end
    ))

    env.current_scope.has_key?("Foo").should eq(true)
  end

  it "handles types defined within other types" do
    env, _ = typecheck(%q(
      deftype Foo
        deftype Bar; end
        deftype Baz; end
      end
    ))

    foo = env.current_scope["Foo"]
    foo.scope.has_key?("Bar").should eq(true)
    foo.scope.has_key?("Baz").should eq(true)
  end

  it "handles types defined within modules" do
    env, _ = typecheck(%q(
      defmodule Foo
        deftype Bar; end
        deftype Baz; end
      end
    ))

    foo = env.current_scope["Foo"]
    foo.scope.has_key?("Bar").should eq(true)
    foo.scope.has_key?("Baz").should eq(true)
  end

  it "handles nested types with the same name" do
    env, _ = typecheck(%q(
      deftype Foo
        deftype Foo; end
      end
    ))

    base_foo  = env.current_scope["Foo"]
    foo_foo   = base_foo.scope["Foo"]
    base_foo.should_not eq(foo_foo)
  end

  it "handles types within modules with the same name" do
    env, _ = typecheck(%q(
      defmodule Foo
        deftype Foo; end
      end
    ))

    base_foo  = env.current_scope["Foo"]
    foo_foo   = base_foo.scope["Foo"]
    base_foo.should_not eq(foo_foo)
  end

  it "handles types with the same name in different namespaces" do
    env, _ = typecheck(%q(
      deftype Foo; end
      defmodule Bar;
        deftype Foo; end
      end
    ))

    base_foo  = env.current_scope["Foo"]
    bar       = env.current_scope["Bar"]
    bar_foo   = bar.scope["Foo"]
    base_foo.should_not eq(bar_foo)
  end
end
