require "./typecheck/*"

module Myst
  module TypeCheck
    T_OBJECT_T  = Type.new("Type(Object)")
    T_OBJECT    = Type.new("Object", static_type: T_OBJECT_T)
    T_OBJECT_T.instance_type = T_OBJECT

    T_NIL_T  = Type.new("Type(Nil)")
    T_NIL    = Type.new("Nil", static_type: T_NIL_T)
    T_NIL_T.instance_type = T_NIL

    T_BOOLEAN_T  = Type.new("Type(Boolean)")
    T_BOOLEAN    = Type.new("Boolean", static_type: T_BOOLEAN_T)
    T_BOOLEAN_T.instance_type = T_BOOLEAN

    T_INTEGER_T  = Type.new("Type(Integer)")
    T_INTEGER    = Type.new("Integer", static_type: T_INTEGER_T)
    T_INTEGER_T.instance_type = T_INTEGER

    T_FLOAT_T  = Type.new("Type(Float)")
    T_FLOAT    = Type.new("Float", static_type: T_FLOAT_T)
    T_FLOAT_T.instance_type = T_FLOAT

    T_STRING_T  = Type.new("Type(String)")
    T_STRING    = Type.new("String", static_type: T_STRING_T)
    T_STRING_T.instance_type = T_STRING

    T_SYMBOL_T  = Type.new("Type(Symbol)")
    T_SYMBOL    = Type.new("Symbol", static_type: T_SYMBOL_T)
    T_SYMBOL_T.instance_type = T_SYMBOL

    T_LIST_T  = Type.new("Type(List)")
    T_LIST    = Type.new("List", static_type: T_LIST_T)
    T_LIST_T.instance_type = T_LIST

    T_MAP_T  = Type.new("Type(Map)")
    T_MAP    = Type.new("Map", static_type: T_MAP_T)
    T_MAP_T.instance_type = T_MAP

    T_TYPE_T  = Type.new("Type(Type)")
    T_TYPE    = Type.new("Type", static_type: T_TYPE_T)
    T_TYPE_T.instance_type = T_TYPE

    T_MODULE_T  = Type.new("Type(Module)")
    T_MODULE    = Type.new("Module", static_type: T_MODULE_T)
    T_MODULE_T.instance_type = T_MODULE

    T_FUNCTOR_T  = Type.new("Type(Functor)")
    T_FUNCTOR    = Type.new("Functor", static_type: T_FUNCTOR_T)
    T_FUNCTOR_T.instance_type = T_FUNCTOR



    class Visitor
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


      def visit(node : Node)
        node.accept_children(self)
        return T_NIL
      end

      def visit(node : Nop)
        return T_NIL
      end

      def visit(node : Expressions)
        node.children.reduce(T_OBJECT) do |acc, child|
          acc = visit(child)
        end
      end


      def visit(node : NilLiteral);                 return T_NIL;     end
      def visit(node : BooleanLiteral);             return T_BOOLEAN; end
      def visit(node : IntegerLiteral);             return T_INTEGER; end
      def visit(node : FloatLiteral);               return T_FLOAT;   end
      def visit(node : StringLiteral);              return T_STRING;  end
      def visit(node : InterpolatedStringLiteral);  return T_STRING;  end
      def visit(node : SymbolLiteral);              return T_SYMBOL;  end
      def visit(node : ListLiteral);                return T_LIST;    end
      def visit(node : MapLiteral);                 return T_MAP;     end


      def visit(node : MagicConst)
        case node.type
        when :__LINE__
          T_INTEGER
        when :__FILE__
          T_STRING
        when :__DIR__
          T_STRING
        else
          raise "Magic Constant #{node.type} has not been given a definite type."
        end
      end


      # def visit(node : Const | Var | Underscore)
      def visit(node : StaticAssignable)
        current_scope[node.name]
      end

      def visit(node : ValueInterpolation)
        visit(node.value)
      end

      def visit(node : Self)
        current_self
      end


      def visit(node : SimpleAssign)
        left = node.target.as(StaticAssignable)
        value_type = visit(node.value)
        current_scope[left.name, always_create: true] = value_type

        return value_type
      end


      # Merging of conditional scopes is complex. For any given variable,
      # if every clause in the conditional has an assignment to it, then the
      # final type of that variable is simply the union of those types.
      #
      # However, if any clause does _not_ assign that variable, then the
      # resulting type must also be unionized with Nil. Also, if the variable
      # is newly created _within_ the conditional, and is not guaranteed an
      # assignment (e.g., by an `else` clause), then the final type is
      # inherently nilable and must be unioned.
      #
      # Thankfully, all of these cases are handled by the combination of the
      # `unionize` and `nilify` options of `Scope#merge!`.
      def visit(node : When | Unless)
        visit(node.condition)
        push_scope
        result_type = visit(node.body)
        final_scope = pop_scope

        push_scope
        alternative = visit(node.alternative)
        final_scope = final_scope.merge!(pop_scope, unionize: true, nilify: true)
        result_type = result_type.union_with(alternative)

        current_scope.merge!(final_scope, unionize: false, nilify: false)

        result_type
      end

      # Looping expressions can potentially change the typings resolved in
      # their bodies on each iteration. To deal with this, the inferrer itself
      # loops over the expression until the types generated by two consecutive
      # iterations are equal. At this point, all possible type values must have
      # been seen and the typing can be applied.
      #
      # The resulting type of the loop expression is the type of the last
      # expression in the body after the final iteration, unioned with Nil for
      # the case that the loop is never visited.
      def visit(node : While)
        result_type = T_NIL
        first_iteration = true
        will_enter = false

        push_scope(Scope.new(current_scope))

        condition_type = visit(node.condition)
        could_skip = __is_maybe_falsey?(condition_type)
        will_enter = !could_skip
        loop_will_occur = will_enter
        # If the loop can no longer be taken, iteration can stop.
        return T_NIL if condition_type == T_NIL

        old_change_scope = Scope.new(current_scope)
        loop do
          change_scope = Scope.new(current_scope)
          push_scope(change_scope)
          result_type = visit(node.body)
          # If the scope did not change during the iteration, it can stop.
          break if change_scope == old_change_scope

          condition_type = visit(node.condition)
          pop_scope
          current_scope.merge!(change_scope, unionize: !loop_will_occur, nilify: !loop_will_occur)
          could_skip = __is_maybe_falsey?(condition_type)
          # If the loop can no longer be taken, iteration can immediately stop.
          break if condition_type == T_NIL

          if loop_will_occur
            loop_will_occur = could_skip
          end
          first_iteration = false
          old_change_scope = change_scope
        end

        loop_scope = pop_scope
        current_scope.merge!(loop_scope, unionize: !will_enter, nilify: !will_enter)

        unless will_enter
          result_type = result_type.union_with(T_NIL)
        end
        result_type
      end

      def visit(node : Until)
        result_type = T_NIL
        first_iteration = true
        will_enter = false

        push_scope(Scope.new(current_scope))

        condition_type = visit(node.condition)
        will_enter = condition_type == T_NIL
        will_skip = !__is_maybe_falsey?(condition_type)
        loop_will_occur = will_enter
        # If the loop can no longer be taken, iteration can stop.
        return T_NIL if will_skip

        old_change_scope = Scope.new(current_scope)
        loop do
          change_scope = Scope.new(current_scope)
          push_scope(change_scope)
          result_type = visit(node.body)
          # If the scope did not change during the iteration, it can stop.
          break if change_scope == old_change_scope

          condition_type = visit(node.condition)
          pop_scope
          current_scope.merge!(change_scope, unionize: !loop_will_occur, nilify: !loop_will_occur)
          will_skip = !__is_maybe_falsey?(condition_type)
          # If the loop can no longer be taken, iteration can immediately stop.
          break if will_skip

          if loop_will_occur
            loop_will_occur = will_skip
          end
          first_iteration = false
          old_change_scope = change_scope
        end

        loop_scope = pop_scope
        current_scope.merge!(loop_scope, unionize: !will_enter, nilify: !will_enter)

        unless will_enter
          result_type = result_type.union_with(T_NIL)
        end
        result_type
      end


      # Boolean logic operations have some nuance to their typing. For example,
      # in an `Or`, if the first expression is nilable, but the second is not,
      # then the resulting type is guaranteed to not be Nil, so that can be
      # removed from the union.
      #
      # Since the only possible falsey values are `false` and `nil`, if the
      # type of the left hand side does _not_ include `Boolean` or `Nil`, the
      # type will be further restricted (to the left-hand-side only for `Or`,
      # and to the right-hand side for `And`).
      def visit(node : Or)
        left = visit(node.left)
        right = visit(node.right)
        union_type = left.union_with(right)

        # If the left can't be falsey, the right has no effect on the type
        # of the expression. Otherwise, if the right is not nilable, then
        # the result definitely cannot be nil.
        if !__is_maybe_falsey?(left) || !right.includes?(T_NIL)
          union_type = union_type.exclude(T_NIL)
        end

        union_type
      end

      def visit(node : And)
        left = visit(node.left)
        right = visit(node.right)
        union_type = left.union_with(right)

        case
        when left == T_NIL
          return T_NIL
        when left.includes?(T_BOOLEAN)
          union_type
        else
          right
        end
      end


      def visit(node : Def)
        container =
          if node.static?
            current_self.static_type.scope
          else
            current_self.instance_type.scope
          end

        functor = (container[node.name] ||= Functor.new(node.name)).as(Functor)
        functor.add_clause(node)

        return T_FUNCTOR
      end


      def visit(node : TypeDef)
        static = current_scope[node.name] ||= __make_type(node.name)

        push_self(static)
        visit(node.body)
        pop_self

        static
      end


      def visit(node : Instantiation)
        given_type = visit(node.type)

        if !given_type.instantiable?
          raise "Type given for instantiation is not an instantiable."
        end

        return given_type.instance_type
      end



      private def __is_maybe_falsey?(type)
        type.includes?(T_NIL) || type.includes?(T_BOOLEAN)
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
