require "../spec_helper.cr"

describe "Literals" do
  it_types %q(nil),       "Nil"

  it_types %q(true),      "Boolean"
  it_types %q(false),     "Boolean"

  it_types %q(0),         "Integer"
  it_types %q(1000),      "Integer"
  it_types %q(1_23_45),   "Integer"

  it_types %q(0.0),       "Float"
  it_types %q(123.456),   "Float"

  it_types %q("hello"),   "String"
  it_types %q("<(2)>"),   "String"

  it_types %q(:hi),       "Symbol"
  it_types %q(:"a b"),    "Symbol"

  it_types %q([]),        "List"
  it_types %q([1, 2]),    "List"
  it_types %q([nil, :a]), "List"

  it_types %q({}),              "Map"
  it_types %q({a: nil}),        "Map"
  it_types %q({a: 1, b: nil}),  "Map"
end
