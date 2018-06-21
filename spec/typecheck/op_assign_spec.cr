require "../spec_helper.cr"

private I_PLUS = %q(
  deftype Integer
    def +(other : Integer); 1; end
  end
)

describe "OpAssign" do
  # OpAssigns are shorthand from `a op= b` to either `a = a op b`, or something
  # close to `a op a = b` for `||` and `&&`. The typing results should be
  # expected to match between them in all cases.
  #
  # However, to force the typechecker to assign the target value, the expansion
  # is wrapped in a second assignment, like `a = (a op= b)`.

  # TODO: uncomment when the typechecker can understand Calls with receivers.
  # it_types I_PLUS + %q(
  #   a = 1
  #   a += 1
  # ), environment: {
  #   "a" => "Integer"
  # }
  # it_types I_PLUS + %q(
  #   a = 1
  #   a += 2
  # ), "Integer"

  it_types %q(
    a = false
    a ||= 1
  ), environment: {
    "a" => "Boolean | Integer"
  }

  it_types %q(
    a = nil
    a ||= 2
  ), environment: {
    "a" => "Integer"
  }

  # Here, `a` is a Float, and thus cannot be falsey, so the Or assignment is
  # guaranteed to not occur, and `a` is _not_ given the Integer type.
  it_types %q(
    a = 1.0
    a ||= 2
  ), environment: {
    "a" => "Float"
  }
end
