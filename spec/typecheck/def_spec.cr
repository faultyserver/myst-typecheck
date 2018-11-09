require "../spec_helper.cr"

describe "Def" do
  # Def returns the functor that it defines/appends. Every functor is
  # considered its own type to simplify managing uniqueness of functions,
  # handling function capturing, and analysis as part of the existing
  # scopes for types.
  it_types %q(
    def foo(a, b); end
  ), "Functor(foo)"

  it_types %q(
    def foo(a : Integer) : Float; end
  ), "Functor(foo)"

  it_types %q(
    def foo(a : Integer | Float) : String | Nil; end
  ), "Functor(foo)"

  it_types %q(
    def foo; end
  ), "Functor(foo)"

  it_types %q(
    def foo
      1
    end
  ), "Functor(foo)"

  it_types %q(
    def foo(a, b)
      false
    end
  ), "Functor(foo)"

  it_types %q(
    def foo(a, b)
      when false
        x
      else
        "nope"
      end
    end
  ), "Functor(foo)"


  describe "inside a type definition" do
    it "creates a new functor on the type if one does not exist" do
      env, _ = typecheck(%q(
        deftype Foo
          def foo; end
        end
      ))
      foo = env.current_scope["Foo"].instance_type
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(1)
    end

    it "does not leak the functor outside of the type" do
      env, _ = typecheck(%q(
        deftype Foo
          def foo; end
        end
      ))
      foo = env.current_scope.has_key?("foo").should be_false
    end

    it "adds a clause to the existing functor if one exists" do
      env, _ = typecheck(%q(
        deftype Foo
          def foo; end
          def foo(a); end
        end
      ))
      foo = env.current_scope["Foo"].instance_type
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(2)
    end

    it "does not merge clauses with different names" do
      env, _ = typecheck(%q(
        deftype Foo
          def foo; end
          def bar; end
        end
      ))
      foo = env.current_scope["Foo"].instance_type
      functor1 = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor1.clauses.size.should eq(1)
      functor2 = foo.scope["bar"].as(Myst::TypeCheck::Functor)
      functor2.clauses.size.should eq(1)
    end

    it "can merge clauses in different openings of the type" do
      env, _ = typecheck(%q(
        deftype Foo
          def foo; end
        end

        deftype Foo
          def foo(a); end
        end
      ))
      foo = env.current_scope["Foo"].instance_type
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(2)
    end


    it "places static definitions on the static type" do
      env, _ = typecheck(%q(
        deftype Foo
          defstatic foo; end
        end
      ))
      foo = env.current_scope["Foo"].static_type
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(1)
    end

    it "adds static clauses to existing functors" do
      env, _ = typecheck(%q(
        deftype Foo
          defstatic foo; end
          defstatic foo(a); end
        end
      ))
      foo = env.current_scope["Foo"].static_type
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(2)
    end

    it "does not merge static clauses with different names" do
      env, _ = typecheck(%q(
        deftype Foo
          defstatic foo; end
          defstatic bar; end
        end
      ))
      foo = env.current_scope["Foo"].static_type
      functor1 = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor1.clauses.size.should eq(1)
      functor2 = foo.scope["bar"].as(Myst::TypeCheck::Functor)
      functor2.clauses.size.should eq(1)
    end
  end


  describe "inside a module definition" do
    it "creates a new functor on the type if one does not exist" do
      env, _ = typecheck(%q(
        defmodule Foo
          def foo; end
        end
      ))
      foo = env.current_scope["Foo"]
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(1)
    end

    it "does not leak the functor outside of the type" do
      env, _ = typecheck(%q(
        defmodule Foo
          def foo; end
        end
      ))
      foo = env.current_scope.has_key?("foo").should be_false
    end

    it "adds a clause to the existing functor if one exists" do
      env, _ = typecheck(%q(
        defmodule Foo
          def foo; end
          def foo(a); end
        end
      ))
      foo = env.current_scope["Foo"]
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(2)
    end

    it "does not merge clauses with different names" do
      env, _ = typecheck(%q(
        defmodule Foo
          def foo; end
          def bar; end
        end
      ))
      foo = env.current_scope["Foo"]
      functor1 = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor1.clauses.size.should eq(1)
      functor2 = foo.scope["bar"].as(Myst::TypeCheck::Functor)
      functor2.clauses.size.should eq(1)
    end

    it "can merge clauses in different openings of the module" do
      env, _ = typecheck(%q(
        defmodule Foo
          def foo; end
        end

        defmodule Foo
          def foo(a); end
        end
      ))
      foo = env.current_scope["Foo"].instance_type
      functor = foo.scope["foo"].as(Myst::TypeCheck::Functor)
      functor.clauses.size.should eq(2)
    end


    # TODO: This should be checked, but I don't know how/when. Doing so
    # immediately from the first pass of typing feels weird.
    #
    # it "does not allow static definitions" do
    #   expect_raises(Exception) do
    #     env, _ = typecheck(%q(
    #       defmodule Foo
    #         defstatic foo; end
    #       end
    #     ))
    #   end
    # end
  end


  describe "return type restrictions" do
    # Specifying a return type explicitly on a method definition creates a
    # check on the type that results from calling that clause, and guarantees
    # that the resulting type is the one given by the restriction.
    it_types %q(
      def foo : Integer;
        1
      end
      foo()
    ), "Integer"

    it_types %q(
      def foo(a) : Integer;
        a
      end
      foo(1)
    ), "Integer"

    # If the resulting type from a Call does not match the restriction given by
    # a definition, an error is raised.
    it_does_not_type %q(
      def foo : Integer;
        "hello"
      end

      foo()
    ), /expected call to return `Integer` but .+ `String`/i

    # Each clause of a functor is considered individually when checking return
    # type restrictions
    it_types %q(
      def foo(a : Integer) : Integer; 1; end
      def foo(a : Symbol) : Symbol; :b; end
      foo(1)
      foo(:a)
    ), "Symbol"

    # Return types must be an exact match with the restriction type to succeed.
    it_types %q(
      def foo(a) : Integer | Nil
        when a
          1
        end
      end
      foo(1)
    ), "Integer | Nil"

    # If the type is not an exact match, the typechecker should
    # TODO: emit warnings.
    it_does_not_type %q(
      def foo(a) : Integer | Nil
        1
      end
      foo(1)
    ), /expected call to return `Integer | Nil` but .+ `Integer`/i
  end
end
