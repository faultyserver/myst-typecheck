require "../spec_helper.cr"

describe "IVars" do
  # Until instance variables can have type restrictions applied to them,
  # we can't effectively/efficiently declare an exact type for them,
  # because their mutations are not directly trackable from the AST. So,
  # at least for now, they are always just typed as generic `Object`s.
  #
  # This is a bit of a cop-out, but is arguably nicer than trying to
  # determine some exact typing that isn't helpfully-accurate at the time
  # of use.
  it_types %q(
    @something = 1
    @something = :hello || "hello"
    @something
  ), "Any"

  it_types %q(
    @something = 1
    @something
  ), "Any"

  # IVars are also valid if they have not been assigned anything yet, in which
  # case they are Nil. But, we still type them as `Any` for consistency.
  it_types %q(@something), "Any"
end
