require "./semantic_visitor.cr"

module Myst
  module TypeCheck
    class DefVisitor < SemanticVisitor
      def visit(node : Def)
        container =
          if node.static?
            env.current_self.static_type.scope
          else
            env.current_self.instance_type.scope
          end

        functor = (container[node.name] ||= Functor.new(node.name)).as(Functor)
        functor.add_clause(node)
        functor
      end


      def visit(node : ModuleDef)
        module_type = env.current_scope.find_or_assign(node.name, Type.new(node.name))
        unless module_type.scope.parent?
          module_type.scope.parent = env.current_scope
        end

        env.push_self(module_type)
        visit(node.body)
        env.pop_self

        module_type
      end

      def visit(node : TypeDef)
        static = env.current_scope.find_or_assign(node.name, __make_type(node.name))
        unless static.scope.parent?
          static.scope.parent = env.current_scope
          static.instance_type.scope.parent = env.current_scope
        end

        env.push_self(static)
        visit(node.body)
        env.pop_self

        static
      end
    end
  end
end
