require "./type.cr"

module Myst
  module TypeCheck
    class Scope < Hash(String, Type)
      property parent : Scope?

      def initialize(@parent : Scope? = nil)
        super
      end
    end
  end
end
