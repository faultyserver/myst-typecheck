require "../spec_helper.cr"

describe "Or" do
  it_types %q(1 || 2),        "Integer"
  it_types %q(true || false), "Boolean"

  # If the inferrer knows that the left hand side will not be falsey, it will
  # restrict the type of the result to the left hand side appropriately.
  it_types %q("hi" || :hi),   "String | Symbol"
  it_types %q(1 || nil),      "Integer"
  # If the left hand side _must_ be falsey (e.g., is `Nil`), then it will only
  # be typed with the right hand's type.
  it_types %q(nil || 1),      "Integer"
  it_types %q(nil || nil),    "Nil"
  # Otherwise, the resulting type is the union of both expressions. Currently,
  # Boolean literals are not evaluated for truthiness, so the restriction is
  # not always performed.
  it_types %q(false || 2),    "Boolean | Integer"
  it_types %q(true || 2),     "Boolean | Integer"

  # Nested expressions have all the same behavior
  it_types %q(1 || 2 || 3),           "Integer"
  it_types %q(nil || false || true),  "Boolean"
  it_types %q(false || nil || true),  "Boolean"
  it_types %q(false || true || nil),  "Boolean | Nil"
end


describe "And" do
  it_types %q(1 && 2),        "Integer"
  it_types %q(true && 1.0),   "Boolean | Float"

  # If the inferrer knows that the either side _must_ be falsey, it will
  # restrict the type of the result to that value appropriately.
  it_types %q(nil && :hi),    "Nil"
  it_types %q(nil && false),  "Nil"
  it_types %q(1 && nil),      "Nil"
  # Booleans are not currently evaluated for truthiness.
  it_types %q(false && nil),  "Boolean | Nil"
  it_types %q(false && 2),    "Boolean | Integer"
  it_types %q("hello" && 2),  "Integer"
  it_types %q(1.0 && nil),    "Nil"

  # Nested expressions have all the same behavior
  it_types %q(1 && 2 && 3),           "Integer"
  it_types %q(nil && false && true),  "Nil"
  it_types %q(false && nil && true),  "Boolean | Nil"
  it_types %q(false && true && nil),  "Boolean | Nil"
end


describe "Mixed Or/And" do
  it_types %q(1 && 2 || nil), "Integer"
  # `And` has higher precedence than `Or`, so `Nil` can be removed from
  # expressions like this, where the Or is the top-level expression.

  # Nil && Integer || Integer  ->  Nil || Integer  ->  Integer
  it_types %q(nil && 1 || 2),         "Integer"
  # Nil && Integer || Nil && Integer  ->  Nil || Nil  ->  Nil
  it_types %q(nil && 1 || nil && 2),  "Nil"
  # (Integer || Nil) && Integer  ->  Integer && Integer
  it_types %q((1 || nil) && 2),       "Integer"
  # (Nil || Integer) && Integer  ->  Integer && Integer  ->  Integer
  it_types %q((nil || 1) && 2),       "Integer"
  # (Nil || Integer) && Integer  ->  Integer && Integer  ->  Integer
  it_types %q((nil || 1) && 2),       "Integer"
  # (Nil || Integer) && Nil  ->  Integer && Nil  ->  Nil
  it_types %q((nil || 1) && nil),     "Nil"
end
