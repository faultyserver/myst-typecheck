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
end
