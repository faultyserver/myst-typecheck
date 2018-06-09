require "../spec_helper.cr"

# These tests assume that `SimpleAssign` is properly implemented.
describe "References" do
  ["FOO", "local", "_under"].each do |ref|
    it "raises if `#{ref}` does not exist" do
      expect_raises(Exception) do
        typecheck(ref)
      end
    end

    it "returns the last-assigned type of `#{ref}`" do
      typecheck(%Q(
        #{ref} = 2
        #{ref}
      ))
    end
  end
end
