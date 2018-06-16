module Myst
  module TypeCheck
    class Environment
      property scope_stack : Array(Scope)
      property self_stack : Array(Type)

      def initialize
        root = Type.new("main")
        create_root_scope(root.scope)
        @scope_stack = [] of Scope
        @self_stack = [root] of Type
      end

      def create_root_scope(root)
        root["Object"]  = T_OBJECT_T
        root["Nil"]     = T_NIL_T
        root["Boolean"] = T_BOOLEAN_T
        root["Integer"] = T_INTEGER_T
        root["Float"]   = T_FLOAT_T
        root["String"]  = T_STRING_T
        root["Symbol"]  = T_SYMBOL_T
        root["List"]    = T_LIST_T
        root["Map"]     = T_MAP_T
        root["Type"]    = T_TYPE_T
        root["Module"]  = T_MODULE_T
        root["Functor"] = T_FUNCTOR_T
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

      def merge_scope(unionize=true, nilify=false)
        scope = pop_scope
        current_scope.merge!(scope, unionize: unionize, nilify: nilify)
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
