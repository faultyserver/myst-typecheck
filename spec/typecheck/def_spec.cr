require "../spec_helper.cr"

describe "Def" do
  # Currently, all function definitions return a generic `Functor` type.
  # Eventually, it would be nice to provide "specialized" Functor types based
  # on the argument and return types. How advantageous this would actually be
  # is not yet clear, though.
  it_types %q(
    def foo(a, b); end
  ), "Functor"

  it_types %q(
    def foo(a : Integer) : Float; end
  ), "Functor"

  it_types %q(
    def foo(a : Integer | Float) : String | Nil; end
  ), "Functor"

  it_types %q(
    def foo; end
  ), "Functor"

  it_types %q(
    def foo
      1
    end
  ), "Functor"

  it_types %q(
    def foo(a, b)
      false
    end
  ), "Functor"

  it_types %q(
    def foo(a, b)
      when false
        x
      else
        "nope"
      end
    end
  ), "Functor"


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
end
