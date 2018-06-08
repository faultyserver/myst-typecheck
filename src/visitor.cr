require "./typecheck/*"

module Myst
  module TypeCheck
    class Visitor
      property scope_stack : Array(Scope)
      property self_stack : Array(Type)

      def initialize
        @scope_stack = [Scope.new]
        @self_stack = [] of Type
        init_primitives
      end

      def init_primitives
        current_scope["Object"]  = Type.new("Object")
        current_scope["Nil"]     = Type.new("Nil")
        current_scope["Boolean"] = Type.new("Boolean")
        current_scope["Integer"] = Type.new("Integer")
        current_scope["Float"]   = Type.new("Float")
        current_scope["String"]  = Type.new("String")
        current_scope["Symbol"]  = Type.new("Symbol")
        current_scope["List"]    = Type.new("List")
        current_scope["Map"]     = Type.new("Map")
        current_scope["Type"]    = Type.new("Type")
        current_scope["Module"]  = Type.new("Module")
        current_scope["Functor"] = Type.new("Functor")
      end

      def current_scope; @scope_stack.last; end
      def root_scope; @scope_stack.first; end
      def current_self;  @self_stack.last;  end


      def visit(node : Node)
        node.accept_children(self)
        return root_scope["Object"]
      end

      def visit(node : TypeDef)
        this_type = current_scope[node.name] ||= Type.new(node.name)

        @self_stack.push(this_type)
        node.accept_children(self)
        @self_stack.pop

        this_type
      end

      def visit(node : Def)
        scope = node.static? ? current_self.static_methods : current_self.instance_methods
        method = scope[node.name] ||= Method.new(node.name)

        parameter_types = node.params.map{ |p| visit(p).as(Type) }
        returns = node.return_type? ? visit(node.return_type) : root_scope["Object"]

        method.add_clause(node, parameter_types, returns)
        return root_scope["Functor"]
      end

      def visit(node : Param)
        if node.restriction?
          visit(node.restriction)
        else
          root_scope["Object"]
        end
      end

      def visit(node : SimpleAssign)
        left = node.target.as(Var)
        value_type = visit(node.value)
        current_scope[left.name] = value_type
        return value_type
      end

      def visit(node : Const)
        current_scope[node.name]
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
        return clause.returns
      end


      def visit(node : NilLiteral);                 return root_scope["Nil"];     end
      def visit(node : BooleanLiteral);             return root_scope["Boolean"]; end
      def visit(node : IntegerLiteral);             return root_scope["Integer"]; end
      def visit(node : FloatLiteral);               return root_scope["Float"];   end
      def visit(node : StringLiteral);              return root_scope["String"];  end
      def visit(node : InterpolatedStringLiteral);  return root_scope["String"];  end
      def visit(node : SymbolLiteral);              return root_scope["Symbol"];  end
      def visit(node : ListLiteral);                return root_scope["List"];    end
      def visit(node : MapLiteral);                 return root_scope["Map"];     end
    end
  end
end
