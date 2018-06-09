require "../spec_helper.cr"

describe "Conditionals" do
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
end
