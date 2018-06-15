require "../spec_helper.cr"

describe "ModuleDef" do
  # ModuleDefs return the module type they define. Unlike TypeDef, ModuleDef
  # only creates a static type, so the name is just the given name for the
  # module (instead of `Module(Foo)` to differentiate static vs instance types)
  it_types %q(defmodule Foo; end), "Foo"

  it "creates a new type in the current scope" do
    tc = typecheck(%q(
      defmodule Foo; end
    ))

    tc.current_scope.has_key?("Foo").should eq(true)
  end

  it "allows re-opening existing types" do
    tc = typecheck(%q(defmodule Foo; end))
    foo1 = tc.current_scope["Foo"]

    tc = typecheck(%q(defmodule Foo; end), tc)
    foo2 = tc.current_scope["Foo"]

    foo1.should eq(foo2)
  end
end
