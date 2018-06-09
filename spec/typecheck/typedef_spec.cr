require "../spec_helper.cr"

describe "TypeDef" do
  # typedefs return the type they define
  it_types %q(deftype Foo; end), "Foo"

  it "creates a new type in the current scope" do
    tc = typecheck(%q(
      deftype Foo; end
    ))

    tc.current_scope.has_key?("Foo").should eq(true)
  end

  it "allows re-opening existing types" do
    tc = typecheck(%q(deftype Foo; end))
    foo1 = tc.current_scope["Foo"]

    tc = typecheck(%q(deftype Foo; end), tc)
    foo2 = tc.current_scope["Foo"]

    foo1.should eq(foo2)
  end
end
