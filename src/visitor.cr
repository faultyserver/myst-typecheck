require "./typecheck/*"

module Myst
  module TypeCheck
    class Visitor
      struct Type
        property name : String
        property instance_methods : Array(Method)
        property static_methods : Array(Method)

        def initialize(@name : String)
          @instance_methods = [] of Method
          @static_methods = [] of Method
        end

        def inspect(io : IO)
          io << name << ":\n"
          io << "  instance_methods:\n"
          instance_methods.each do |im|
            io << "    "
            im.inspect(io)
            io << "\n"
          end
          io << "\n"
          io << "  static_methods:\n"
          static_methods.each do |sm|
            io << "    "
            sm.inspect(io)
            io << "\n"
          end
          io << "\n"
        end
      end

      OBJECT = Type.new("Object")

      struct Method
        property name : String
        property inputs : Array(Type)
        property output : Type

        def initialize(@name : String, @inputs = [] of Type, @output : Type = OBJECT)
        end

        def inspect(io : IO)
          io << name << "("
          io << inputs.map(&.name).join(", ")
          io << ") : "
          io << output.name
        end
      end


      property types : Hash(String, Type)
      property self_stack : Array(Type)


      def initialize
        @types = {} of String => Type
        @self_stack = [] of Type
      end

      def current_self
        @self_stack.last
      end

      def visit(node : Node)
        node.accept_children(self)
      end

      def visit(node : TypeDef)
        typ = types[node.name]? || (types[node.name] = Type.new(node.name))
        @self_stack.push(typ)

        node.accept_children(self)
      end

      def visit(node : Def)
        container =
          node.static? ?
            current_self.static_methods :
            current_self.instance_methods


        inputs = [] of Type

        node.params.each do |p|
          param_type =
            if p.restriction?
              visit()
            else
              OBJECT
            end
          inputs.push(param_type)
        end

        container.push(Method.new(node.name))
      end
    end
  end
end
