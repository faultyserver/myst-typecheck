require "../spec_helper.cr"

describe "Call" do
  # Calls are typed in the main phase, after all definitions have been found
  # and all possible types are known.
  #
  # The process of inferring the type of a Call is:
  # - evaluate the types of any arguments given to the call.
  # - lookup the functor by name in the current scope
  # - find all clauses of the functor that could match with the given arguments
  # - for each matching clause:
  #   - create a new temporary scope
  #   - assign all parameter values from the given arguments
  #   - evaluate the body of the clause to determine the return type.
  #   ? check that the return type matches what was declared for the clause
  # - return the union of the return types of all matching clauses.

  # The simplest case is when there is a free functor with only one clause to
  # match against, and that takes no arguments.
  it_types %q(
    def foo; 1; end
    foo()
  ), "Integer"

  it_types %q(
    def foo; 1; end
    def bar; nil; end

    x = foo()
    y = bar()
  ), environment: {
    "x" => "Integer",
    "y" => "Nil"
  }

  # By default, an empty body for a clause returns Nil.
  it_types %q(
    def foo; end
    foo()
  ), "Nil"

  # If no function with the given name exists, a "does not exist" error is raised.
  it_does_not_type %q(bar()), /no function with the name `bar` exists for type `main`/
  it_does_not_type %q(
    deftype Foo; end
    Foo.bar()
  ), /no function with the name `bar` exists for type `type\(foo\)`/
  it_does_not_type %q(
    deftype Foo; end
    %Foo{}.bar()
  ), /no function with the name `bar` exists for type `foo`/


  # With arguments, clauses can potentially not match. If no matching clause
  # for a Call is found for the given arguments, it should raise an error.
  it_does_not_type %q(
    def foo(a); end
    foo()
  ), /no matching clause/

  it_does_not_type %q(
    def foo(a, b); end
    foo(1)
  ), /no matching clause/

  it_does_not_type %q(
    def foo(a); end
    foo(1, 2)
  ), /no matching clause/

  # But, if multiple clauses could match, the resulting type is the union of
  # the return types from each clause.
  it_types %q(
    def foo(a : Boolean); :error; end
    def foo(a : String); "hello"; end

    foo(true || "maybe")
  ), "String | Symbol"

  it_types %q(
    def foo(a : Integer); 1; end
    def foo(a : String); "hello"; end
    def foo(a); nil; end

    foo(@something)
  ), "Integer | Nil | String"


  # Type restrictions can also cause matches to fail if the argument type does
  # not match what is given.
  it_does_not_type %q(
    def foo(a : Integer); end
    foo("Hello")
  ), /no matching clause/

  it_does_not_type %q(
    def foo(a, b : Integer); end
    foo(2, "hello")
  ), /no matching clause/

  it_does_not_type %q(
    def foo(a : Integer, b : Integer); end
    foo(2, "hello")
  ), /no matching clause/

  it_does_not_type %q(
    def foo(a : Integer); end
    foo("Hello")
  ), /no matching clause/

  # Additionally, in multi-clause functions, some clauses may match while
  # others do not. The return type in this situation is only the union of those
  # that match the arguments
  it_types %q(
    def foo(a : Integer); 1; end
    def foo(a : Float); 1.0; end

    x = foo(1)
    y = foo(1.0)
  ), environment: {
    "x" => "Integer",
    "y" => "Float"
  }


  # Named parameters have their types set according to the given arguments.
  # This can cause the return type of a clause to change dynamically if the
  # type is dependent on the type of a parameter.
  it_types %q(
    def foo(a); a; end
    foo(1)
  ), "Integer"

  it_types %q(
    def foo(a, b)
      when true
        a
      else
        b
      end
    end
    foo(1, "hello")
  ), "Integer | String"

  # Parameters can also be re-assigned inside the method body, changing their
  # types.
  it_types %q(
    def foo(a)
      a = false
      a
    end
    foo(1)
  ), "Boolean"


  # Type restrictions for parameters can be given as type unions. When a Call
  # is made to a function with a union parameter, though, the parameter is
  # given only the type of the argument.
  it_types %q(
    def foo(a : Integer | String)
      a
    end

    foo("hello")
  ), "String"



  # Calls with receivers perform lookups based on the type of the receiver.
  it_types %q(
    deftype Integer
      def +(other : Integer); 1; end
    end

    1 + 1
  ), "Integer"

  # If that receiver is a union type, lookup is performed on all types included
  # in the union.
  it_types %q(
    deftype Integer
      def something; nil; end
    end

    deftype Boolean
      def something; :yes; end
    end

    (false || 1).something
  ), "Nil | Symbol"

  # If any member of the receiver's type union does not have a potentially-
  # successful match for it, the typechecker fails.
  it_does_not_type %q(
    deftype Integer
      def something; nil; end
    end

    (false || 1).something
  )

  # Even if all types respond to the method name, they must also have matching
  # clauses to be considered valid.
  it_does_not_type %q(
    deftype Integer
      def something; nil; end
    end

    deftype Boolean
      def something(a, b); nil; end
    end

    (false || 1).something
  )


  # Calls can also be performed off of arbitrary expressions, in which case the
  # expression must resolve to a Functor.
  it_types %q(
    def foo; 1; end
    (&foo)()
  ), "Integer"

  it_types %q(
    def bar; 1; end
    def foo; &bar; end

    foo()()
  ), "Integer"

  # Immediate invocation of an AnonymousFunction is a Call to an expression.
  it_types %q(
    (fn ->(a) { a } end)(1)
  ), "Integer"

  it_does_not_type %q(
    (1)()
  ), /did not resolve to a callable object/

  # The expression raises an error if there is any chance that the expression is
  # not a Functor.
  it_does_not_type %q(
    def foo; 1; end
    (false || (&foo))()
  ), /did not resolve to a callable object/
end
