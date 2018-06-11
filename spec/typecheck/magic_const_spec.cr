require "../spec_helper.cr"

describe "Magic Constants" do
  it_types %q(__LINE__), "Integer"
  it_types %q(__FILE__), "String"
  it_types %q(__DIR__), "String"
end
