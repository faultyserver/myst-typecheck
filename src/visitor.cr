require "./typecheck/*"

module Myst
  module TypeCheck
    T_OBJECT  = Type.new("Object")
    T_NIL     = Type.new("Nil")
    T_BOOLEAN = Type.new("Boolean")
    T_INTEGER = Type.new("Integer")
    T_FLOAT   = Type.new("Float")
    T_STRING  = Type.new("String")
    T_SYMBOL  = Type.new("Symbol")
    T_LIST    = Type.new("List")
    T_MAP     = Type.new("Map")
    T_TYPE    = Type.new("Type")
    T_MODULE  = Type.new("Module")
    T_FUNCTOR = Type.new("Functor")

    class Visitor
      property scope_stack : Array(Scope)
      property self_stack : Array(Type)


      def initialize
        @scope_stack = [create_root_scope]
        @self_stack = [Type.new("main")] of Type
      end

      def create_root_scope
        Scope.new.tap do |scope|
          scope["Object"]  = T_OBJECT
          scope["Nil"]     = T_NIL
          scope["Boolean"] = T_BOOLEAN
          scope["Integer"] = T_INTEGER
          scope["Float"]   = T_FLOAT
          scope["String"]  = T_STRING
          scope["Symbol"]  = T_SYMBOL
          scope["List"]    = T_LIST
          scope["Map"]     = T_MAP
          scope["Type"]    = T_TYPE
          scope["Module"]  = T_MODULE
          scope["Functor"] = T_FUNCTOR
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


      def visit(node : Call)
        this =
          if node.receiver?
            visit(node.receiver)
          else
            current_self
          end

        method = this.instance_methods[node.name]
        arguments = node.args.map{ |a| visit(a) }

        clause = method.clause_for(arguments)

        push_scope
        return_type =
          if clause.has_explicit_return_type?
            clause.returns
          else
            visit(clause.body)
          end
        pop_scope

        return return_type
      end


      def visit(node : Param)
        if node.restriction?
          visit(node.restriction)
        else
          T_OBJECT
        end
      end

      def visit(node : Def)
        scope = node.static? ? current_self.static_methods : current_self.instance_methods
        method = scope[node.name] ||= Method.new(node.name)

        parameter_types = node.params.map{ |p| visit(p).as(Type) }
        returns = node.return_type? ? visit(node.return_type) : T_OBJECT

        method.add_clause(node, parameter_types, returns)
        return T_FUNCTOR
      end


      def visit(node : TypeDef)
        this_type = current_scope[node.name] ||= Type.new(node.name)

        @self_stack.push(this_type)
        node.accept_children(self)
        @self_stack.pop

        this_type
      end
    end
  end
end
