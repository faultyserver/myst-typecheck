require "../spec_helper.cr"

describe "Return" do
  # A single return expression at the end of a clause has the same effect as
  # omitting the `return` keyword, whereby the last expression of a clause is
  # the implicit return value.
  it_types %q(
    def foo
      return 1
    end
    foo()
  ), "Integer"

  # Return expressions amend the resulting type of clause structures. They do
  # _not_ affect the resulting type of other scoping structures like `when` or
  # `while`.
  it_types %q(
    def foo
      when true
        return 1
      else
        return "nope"
      end
    end
    foo()
  ), "Integer | String"

  it_types %q(
    def foo
      while true
        when false
          return false
        end
      end
    end
    foo()
  ), "Boolean | Nil"

  # Multiple return clauses within an expression create a union from the type
  # of each expression, plus the type of the last expression in the clause.
  it_types %q(
    def foo
      when true
        return 1
      end

      return "nope"
    end
    foo()
  ), "Integer | String"

  it_types %q(
    def foo
      when true
        return 1
      else
        return nil
      end

      return "nope"
    end
    foo()
  ), "Integer | Nil | String"


  # Returns work the same way regardless of what kind of clause they are in.
  it_types %q(
    def foo(&block); block(); end
    foo do
      when true
        return 1
      else
        return nil
      end
    end
  ), "Integer | Nil"

  it_types %q(
    foo = fn
      ->() {
        when true
          return 1
        else
          return nil
        end
      }
    end
    foo()
  ), "Integer | Nil"


  # When nested within clauses, Returns only effect their immediate clause
  # ancestor and do not leak to the further-containing clauses.
  it_types %q(
    def bar(&block); block(); end
    def foo
      bar{ return 2 }
      nil
    end

    foo()
  ), "Nil"
end
