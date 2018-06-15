module Myst
  module TypeCheck
    class Environment
      property scope_stack : Array(Scope)
      property self_stack : Array(Type)

      def initialize
        @scope_stack = [create_root_scope]
        @self_stack = [Type.new("main")] of Type
      end

      def create_root_scope
        Scope.new.tap do |scope|
          scope["Object"]  = T_OBJECT_T
          scope["Nil"]     = T_NIL_T
          scope["Boolean"] = T_BOOLEAN_T
          scope["Integer"] = T_INTEGER_T
          scope["Float"]   = T_FLOAT_T
          scope["String"]  = T_STRING_T
          scope["Symbol"]  = T_SYMBOL_T
          scope["List"]    = T_LIST_T
          scope["Map"]     = T_MAP_T
          scope["Type"]    = T_TYPE_T
          scope["Module"]  = T_MODULE_T
          scope["Functor"] = T_FUNCTOR_T
        end
      end


      def root_scope; @scope_stack.first; end
      def current_scope; @scope_stack.last; end

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


      def current_self;  @self_stack.last;  end

      def push_self(this : Type)
        @self_stack.push(this)
      end

      def pop_self
        @self_stack.pop
      end
    end
  end
end
