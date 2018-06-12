require "../spec_helper.cr"

describe "Loops (While/Until)" do
  # The return type of a loop is a nilable variant of its last expression
  it_types %q(
    while true; 1; end
  ),              "Integer | Nil"
  it_types %q(
    while true; nil; end
  ),              "Nil"
  it_types %q(
    while true
      false
      [1, 2, 3]
      :hello
    end
  ),              "Nil | Symbol"
  it_types %q(
    x = 1
    when true
      x
    end
  ),              "Integer | Nil"

  # If the loop is guaranteed to be visited at least once, the result is
  # not unioned with Nil.
  it_types %q(
    while 1; false; end
  ),              "Boolean"

  # Simlar to conditionals, assignments within a loop can result in nilable
  # types for those targets.
  it_types %q(
    while true
      x = :a
    end
  ), environment: { "x" => "Nil | Symbol" }

  it_types %q(
    x = false
    while true
      x = 1
    end
  ), environment: { "x" => "Boolean | Integer" }

  it_types %q(
    x = 1.0
    while true
      x = 1
      x = false
    end
  ), environment: { "x" => "Boolean | Float" }

  it_types %q(
    while x = 2
    end
  ), environment: { "x" => "Integer" }


  # Re-assigning a variable used in the condition of the loop will cause
  # another typing iteration of the loop with the new type.
  it_types %q(
    x = false
    while x
      y = x
      x = 1
    end
  ), environment: {
    "x" => "Boolean | Integer",
    "y" => "Boolean | Integer | Nil"
  }

  # If the condition is guaranteed to not succeed, iteration of the loop
  # stops immediately.
  #
  # Here, the typing iteration is expected to only happen once. After that,
  # `x` becomes `Nil`, meaning the actual loop would stop, so the typing can
  # stop as well. Because of this, `y` does not get assigned the
  # `Boolean | Nil` union that it would get on the second iteration.
  it_types %q(
    x = true
    y = false
    while x
      y = x
      x = nil
    end
  ), environment: { "x" => "Boolean | Nil", "y" => "Boolean" }

  it_types %q(
    x = true
    y = false
    while x
      y = x
      x = 2
    end
  ), environment: { "x" => "Boolean | Integer", "y" => "Boolean | Integer" }

  it_types %q(
    x = 1
    y = false
    while x
      y = 2
      x = nil
    end
  ), environment: { "x" => "Nil", "y" => "Integer" }

  # This can also mean that typing the loop body is skipped entirely if the
  # condition is immediately Nil.
  it_types %q(
    x = 2
    while nil
      x = false
    end
  ), environment: { "x" => "Integer" }
  it_types %q(
    x = 2
    until 1
      x = false
    end
  ), environment: { "x" => "Integer" }

  it_types %q(
    x = 1
    y = false
    until x
      y = 2
      x = nil
    end
  ), environment: { "x" => "Integer", "y" => "Boolean" }
end
