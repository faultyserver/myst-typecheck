require "../spec_helper.cr"

describe "Conditionals" do
  # The type of a conditional expression is the union of types of all
  # clauses within it.
  it_types %q(
    when true
      "yes"
    else
      nil
    end
  ), "Nil | String"

  it_types %q(
    when true
      1
    else
      2
    end
  ), "Integer"

  it_types %q(
    when true
      nil
    unless false
      false
    else
      "hello"
    end
  ), "Boolean | Nil | String"

  # If no else clause is provided, the type of the conditional is unioned with
  # Nil, as there is no guarantee that any of the clauses will be taken.
  it_types %q(
    when true
      2
    end
  ), "Integer | Nil"

  it_types %q(
    when true
      2
    unless false
      false
    end
  ), "Boolean | Integer | Nil"


  # Setting different variables in each clause is not the same as setting the
  # same variable in each clause. Each variable would be nilable by default.
  it_types %q(
    when true
      x = :a
    unless false
      y = false
    else
      z = 1
    end
  ), environment: {
    "x" => "Nil | Symbol",
    "y" => "Boolean | Nil",
    "z" => "Integer | Nil"
  }


  # Conditional expressions should have access to variables from the containing
  # scope.
  it_types %q(
    x = 1
    y = 1.0

    when true
      x
    else
      y
    end
  ), "Float | Integer"

  # Assignments within conditionals cause the target to have a union type of the
  # existing type and whatever is being assigned to it.
  it_types %q(
    x = nil
    when true
      x = 1
    end
  ), environment: { "x" => "Integer | Nil" }

  # New variables can also be defined within the conditional and they will be
  # available outside of it.
  it_types %q(
    when true
      x = 1
    unless false
      x = 1.0
    else
      x = false
    end
  ), environment: { "x" => "Boolean | Float | Integer" }

  # However, re-assignments within the conditional overwrite each other.
  it_types %q(
    x = nil

    when true
      x = 1
      x = false
    end
  ), environment: { "x" => "Boolean | Nil" }

  # When creating a variable in a conditional, if an assignment is not guaranteed,
  # `Nil` is added to the type union.
  it_types %q(
    when true
      x = 1
    end
  ), environment: { "x" => "Integer | Nil" }

  it_types %q(
    when true
      x = 1
    unless false
      x = false
    end
  ), environment: { "x" => "Boolean | Integer | Nil" }

  it_types %q(
    when true
      x = 1
    unless false
    else
      x = false
    end
  ), environment: { "x" => "Boolean | Integer | Nil" }

  it_types %q(
    when true
      x = 1
    unless false
      x = 2
      y = 1
    else
      x = false
    end
  ), environment: { "x" => "Boolean | Integer", "y" => "Integer | Nil" }

  # Variables created in the conditional expression are expanded to the scope
  # of the containing block, as if the assignment was moved to the previous
  # line and the condition was performed on a temporary instead.
  it_types %q(
    when x = 2
    end
  ), environment: { "x" => "Integer" }

  it_types %q(
    when x = 2
    else
      x = false
    end
  ), environment: { "x" => "Boolean | Integer" }

  it_types %q(
    when x = nil
    else
      x = false
    end
  ), environment: { "x" => "Boolean | Nil" }

  # Re-assignment in all alternatives can also remove the nilability of the
  # target.
  it_types %q(
    when x = nil
      x = 4
    else
      x = 2
    end
  ), environment: { "x" => "Integer" }


  # Instance variables are always potentially-nilable (because any reference to
  # them _could potentially_ be the first reference in the program).
  it_types %q(
    when @something
      x = 4
    end
  ), environment: { "x" => "Integer | Nil" }

  # Even if the instance variable has been assigned immediately beforehand, it
  # cannot safely be inferred.
  it_types %q(
    @something = 1
    when @something
      x = 4
    end
  ), environment: { "x" => "Integer | Nil" }
end
