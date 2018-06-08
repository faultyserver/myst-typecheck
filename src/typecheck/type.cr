module Myst
  module TypeCheck
    struct Type
      @@next_id = 1_u64
      property id : UInt64

      property name : String
      property instance_methods : Hash(String, Method)
      property static_methods : Hash(String, Method)


      def initialize(@name : String, @id : UInt64 = @@next_id)
        @instance_methods = {} of String => Method
        @static_methods = {} of String => Method
        @@next_id += 1
      end

      def_equals_and_hash id
    end
  end
end
