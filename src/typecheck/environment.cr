module Myst
  module TypeCheck
    class Environment
      property scope_stack : Array(Scope)
      property self_stack : Array(Type)

      property return_stack : Array(Type?)
      property break_stack : Array(Type?)

      # Crystal's macro evaluation doesn't let this block of definitions live
      # anywhere but in the original definition of this class. Not even in a
      # macro that gets called here.
      getter t_any          = AnyType.new

      getter t_object_t     = Type.new("Type(Object)")
      getter t_object       = Type.new("Object")

      getter t_nil_t        = Type.new("Type(Nil)")
      getter t_nil          = Type.new("Nil")

      getter t_boolean_t    = Type.new("Type(Boolean)")
      getter t_boolean      = Type.new("Boolean")

      getter t_integer_t    = Type.new("Type(Integer)")
      getter t_integer      = Type.new("Integer")

      getter t_float_t      = Type.new("Type(Float)")
      getter t_float        = Type.new("Float")

      getter t_string_t     = Type.new("Type(String)")
      getter t_string       = Type.new("String")

      getter t_symbol_t     = Type.new("Type(Symbol)")
      getter t_symbol       = Type.new("Symbol")

      getter t_list_t       = Type.new("Type(List)")
      getter t_list         = Type.new("List")

      getter t_map_t        = Type.new("Type(Map)")
      getter t_map          = Type.new("Map")

      getter t_type_t       = Type.new("Type(Type)")
      getter t_type         = Type.new("Type")

      getter t_module_t     = Type.new("Type(Module)")
      getter t_module       = Type.new("Module")

      getter t_functor_t    = Type.new("Type(Functor)")
      getter t_functor      = Type.new("Functor")


      def initialize
        root = Type.new("main")
        create_root_scope(root.scope)
        init_primitives

        @return_stack = [nil] of Type?
        @break_stack = [nil] of Type?

        @scope_stack = [] of Scope
        @self_stack = [root] of Type
      end

      def init_primitives
        t_object_t.instance_type    = t_object
        t_object.static_type        = t_object_t
        t_nil_t.instance_type       = t_nil
        t_nil.static_type           = t_nil_t
        t_boolean_t.instance_type   = t_boolean
        t_boolean.static_type       = t_boolean_t
        t_integer_t.instance_type   = t_integer
        t_integer.static_type       = t_integer_t
        t_float_t.instance_type     = t_float
        t_float.static_type         = t_float_t
        t_string_t.instance_type    = t_string
        t_string.static_type        = t_string_t
        t_symbol_t.instance_type    = t_symbol
        t_symbol.static_type        = t_symbol_t
        t_list_t.instance_type      = t_list
        t_list.static_type          = t_list_t
        t_map_t.instance_type       = t_map
        t_map.static_type           = t_map_t
        t_type_t.instance_type      = t_type
        t_type.static_type          = t_type_t
        t_module_t.instance_type    = t_module
        t_module.static_type        = t_module_t
        t_functor_t.instance_type   = t_functor
        t_functor.static_type       = t_functor_t
      end

      def create_root_scope(root)
        root["Object"]  = @t_object_t
        root["Nil"]     = @t_nil_t
        root["Boolean"] = @t_boolean_t
        root["Integer"] = @t_integer_t
        root["Float"]   = @t_float_t
        root["String"]  = @t_string_t
        root["Symbol"]  = @t_symbol_t
        root["List"]    = @t_list_t
        root["Map"]     = @t_map_t
        root["Type"]    = @t_type_t
        root["Module"]  = @t_module_t
        root["Functor"] = @t_functor_t
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


      def current_return_type
        @return_stack.last?
      end

      def push_return_scope
        @return_stack.push(nil)
      end

      def pop_return_scope
        @return_stack.pop
      end

      def set_return_type(type : Type)
        @return_stack[-1] = type
      end

      def add_return_type(type : Type)
        @return_stack[-1] =
          if t = @return_stack.last?
            t.union_with(type)
          else
            type
          end
      end
    end
  end
end
