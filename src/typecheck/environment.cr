require "./primitive_types.cr"

module Myst
  module TypeCheck
    class Environment
      property scope_stack : Array(Scope)
      property self_stack : Array(Type)

      include PrimitiveTypes

      def initialize
        root = Type.new("main")
        create_root_scope(root.scope)
        @scope_stack = [] of Scope
        @self_stack = [root] of Type
        init_primitives
      end

      def create_root_scope(root)
        root["Object"]  = t_object_t
        root["Nil"]     = t_nil_t
        root["Boolean"] = t_boolean_t
        root["Integer"] = t_integer_t
        root["Float"]   = t_float_t
        root["String"]  = t_string_t
        root["Symbol"]  = t_symbol_t
        root["List"]    = t_list_t
        root["Map"]     = t_map_t
        root["Type"]    = t_type_t
        root["Module"]  = t_module_t
        root["Functor"] = t_functor_t
      end


      def root_scope
        @scope_stack.first
      end

      def current_scope
        scope_override || current_self.scope
      end

      def scope_override
        @scope_stack.last?
      end

      def push_scope(scope=nil)
        scope ||= Scope.new(current_scope)
        @scope_stack.push(scope)
      end

      def pop_scope
        @scope_stack.pop
      end

      def merge_scope!(unionize=true, nilify=false)
        scope = pop_scope
        current_scope.merge!(scope, unionize: unionize, nilify: nilify ? t_nil : nil)
      end


      def current_self
        @self_stack.last
      end

      def push_self(this : Type)
        @self_stack.push(this)
      end

      def pop_self
        @self_stack.pop
      end
    end
  end
end
