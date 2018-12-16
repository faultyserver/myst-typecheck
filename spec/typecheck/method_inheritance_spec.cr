require "../spec_helper.cr"

describe "Method Inheritance and Lookup" do
  # Method lookup follows the Myst interpreter's implementation, starting
  # with the current scope, then the current `self`, then checking each
  # entry in the ancestry of `self` for a matching functor. Clause matching
  # then happens, and if no matching clause is found, the process continues
  # up the ancestry. If no match is found, an error is raised.

  # Bar redefines `foo`, so lookup resolves to that clause.
  it_types %q(
    deftype Foo
      def foo; 1; end
    end

    deftype Bar : Foo
      def foo; :symbol; end
    end

    %Bar{}.foo()
  ), "Symbol"

  # Bar does not redefine `foo`, so lookup continues to `Foo`.
  it_types %q(
    deftype Foo
      def foo; 1; end
    end

    deftype Bar : Foo
    end

    %Bar{}.foo()
  ), "Integer"

  # Bar defines a non-matching clause of `foo`.
  it_types %q(
    deftype Foo
      def foo; 1; end
    end

    deftype Bar : Foo
      def foo(a); :symbol; end
    end

    %Bar{}.foo()
  ), "Integer"

  # Using a supertype doesn't check the subtype for matches.
  it_types %q(
    deftype Foo
      def foo; 1; end
    end

    deftype Bar : Foo
      def foo; :symbol; end
    end

    %Foo{}.foo()
  ), "Integer"


  # TODO: test captured functors resolving parent type clauses.
end
