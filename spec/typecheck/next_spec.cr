require "../spec_helper.cr"

describe "Next" do
  # `Next` is semantically equivalent to `Return` in the context of a Call.
  # It is mainly used for looping and block constructs to disambiguate them
  # from the common usage of `return` in method clauses.
  it_types %q(
    def foo(&block); block(); end
    foo{ next 1 }
  ), "Integer"

  # Return expressions amend the resulting type of clause structures. They do
  # _not_ affect the resulting type of other scoping structures like `when` or
  # `while`.
  it_types %q(
    def foo(&block); block(); end
    foo do
      when true
        next 1
      else
        next "nope"
      end
    end
  ), "Integer | String"

  it_types %q(
    def foo(&block); block(); end
    foo do
      while true
        when false
          next false
        end
      end
    end
  ), "Boolean | Nil"

  # Multiple next clauses within an expression create a union from the type
  # of each expression, plus the type of the last expression in the clause.
  it_types %q(
    def foo(&block); block(); end
    foo do
      when true
        next 1
      end

      next "nope"
    end
  ), "Integer | String"

  it_types %q(
    def foo(&block); block(); end
    foo do
      when true
        next 1
      else
        next nil
      end

      next "nope"
    end
  ), "Integer | Nil | String"

  it_types %q(
    foo = fn
      ->() {
        when true
          next 1
        else
          next nil
        end
      }
    end
    foo()
  ), "Integer | Nil"


  # When nested within clauses, Nexts only effect their immediate clause
  # ancestor and do not leak to the further-containing clauses.
  it_types %q(
    def bar(&block); block(); end
    def foo
      bar{ next 2 }
      nil
    end

    foo()
  ), "Nil"
end
