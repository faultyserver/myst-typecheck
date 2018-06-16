module Myst
  module TypeCheck
    class SemanticVisitor
      property env : Environment

      def initialize(@env : Environment)
      end

      def visit(node : Node)
        node.accept_children(self)
        return T_NIL
      end


      private def __is_maybe_falsey?(type)
        type.includes?(T_NIL) || type.includes?(T_BOOLEAN) || type == T_ANY
      end

      private def __make_type(name : String)
        static = Type.new("Type(#{name})")
        instance = Type.new(name, static_type: static)
        static.instance_type = instance
        static
      end
    end
  end
end
