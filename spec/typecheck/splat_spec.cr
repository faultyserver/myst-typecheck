require "../spec_helper.cr"

describe "Splat" do
  # This is naive and does not assert that Splats _will_ always return Lists,
  # just that they _should_ always return splats. To properly guarantee this,
  # the typechecker should analyze any definitions of `splat` methods and
  # assert that they return a List object.
  it_types %q(*[1, 2, 3]), "List"
  it_types %q(*{a: 1, b: 2}), "List"
end
