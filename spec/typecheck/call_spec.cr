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
end
