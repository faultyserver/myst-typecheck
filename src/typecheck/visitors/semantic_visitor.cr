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

      private def __make_type(name : String, super_type=nil)
        static = Type.new("Type(#{name})", super_type: super_type.try(&.static_type))
        instance = Type.new(name, static_type: static, super_type: super_type.try(&.instance_type))
        static.instance_type = instance
        static
      end

      private def __set_supertype(static : Type, super_type : Nil)
        # nop
      end

      private def __set_supertype(static : Type, super_type : Type)
        static.super_type = super_type
        static.instance_type.super_type = super_type.instance_type
      end
    end
  end
end
