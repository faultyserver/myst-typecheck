module Myst
  module TypeCheck
    class SemanticVisitor
      property env : Environment

      def initialize(@env : Environment)
      end

      def visit(node : Node)
        node.accept_children(self)
        return env.t_nil
      end


      private def __is_maybe_falsey?(type)
        type.includes?(env.t_nil) || type.includes?(env.t_boolean) || type == env.t_any
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
