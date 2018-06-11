require "../spec_helper.cr"

describe "Value Interpolations" do
  # Value Interpolations are just typed as the value they contain. For the most
  # part, interpolations are just a syntax sugar for dynamic values in various
  # places.
  it_types %q(<nil>),       "Nil"
  it_types %q(<false>),     "Boolean"
  it_types %q(<1>),         "Integer"
  it_types %q(<1.0>),       "Float"
  it_types %q(<"Hello">),   "String"
  it_types %q(<:hello>),    "Symbol"
  it_types %q(<[1, 2, 3]>), "List"
  it_types %q(<{a: 2}>),    "Map"
end
