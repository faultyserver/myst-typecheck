require "./visitor/*"
require "./typechecking/*"

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
            io << "    " << im.inspect(io)
          end
          io << "  static_methods:\n"
          static_methods.each do |sm|
            io << "    " << sm.inspect(io)
          end
        end
      end

      OBJECT = Type.new("Object")

      struct Method
        property name : String
        property inputs : Array(Type)
        property output : Type

        def initialize(@name : String, @inputs = [] of Type, @output : Type = OBJECT)
        end
      end


      property types : Hash(String, Type)


      def initialize
        @types = {} of String => Type
      end

      def visit(node : Node)
        node.accept_children(self)
      end

      def visit(node : TypeDef)
        return if types[node.name]?

        types[node.name] = Type.new(node.name)
      end
    end
  end
end
