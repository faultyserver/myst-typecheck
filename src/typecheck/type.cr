module Myst
  module TypeCheck
    struct Type
      property name : String
      property instance_methods : Hash(String, Method)
      property static_methods : Hash(String, Method)

      def initialize(@name : String)
        @instance_methods = {} of String => Method
        @static_methods = {} of String => Method
      end

      def_equals_and_hash name
    end
  end
end
