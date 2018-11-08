class Myst::Require
  property! required_tree : Node?

  def accept_children(visitor)
    path.accept(visitor)
    required_tree?.try(&.accept(visitor))
  end
end
