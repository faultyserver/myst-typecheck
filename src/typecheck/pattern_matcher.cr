module Myst
  module TypeCheck
    class PatternMatcher
      property env : Environment

      def initialize(@env : Environment)
      end


      def match(node : Node, type : Type)
        raise "#{node.class.name} nodes are not supported by the typechecker as match patterns."
      end


      def match(node : NilLiteral, type : Type)
        unless type.includes?(T_NIL)
          raise "match pattern of `nil` will never match value type of #{type}"
        end
      end

      def match(node : BooleanLiteral, type : Type)
        unless type.includes?(T_BOOLEAN)
          raise "match pattern of `#{node.value}` will never match value type of #{type}"
        end
      end

      def match(node : IntegerLiteral, type : Type)
        unless type.includes?(T_INTEGER)
          raise "match pattern of `#{node.value}` will never match value type of #{type}"
        end
      end

      def match(node : FloatLiteral, type : Type)
        unless type.includes?(T_FLOAT)
          raise "match pattern of `#{node.value}` will never match value type of #{type}"
        end
      end

      def match(node : StringLiteral, type : Type)
        unless type.includes?(T_STRING)
          raise "match pattern of `#{node.value}` will never match value type of #{type}"
        end
      end

      def match(node : InterpolatedStringLiteral, type : Type)
        unless type.includes?(T_NIL)
          raise "interpolated string literal match pattern will never match value type of #{type}"
        end
      end

      def match(node : SymbolLiteral, type : Type)
        unless type.includes?(T_SYMBOL)
          raise "match pattern of `:#{node.value}` will never match value type of #{type}"
        end
      end

      def match(node : ListLiteral, type : Type)
        unless type.includes?(T_LIST)
          raise "list literal match pattern will never match value type of #{type}"
        end

        node.elements.each do |elem|
          match(elem, T_ANY)
        end
      end

      def match(node : MapLiteral, type : Type)
        unless type.includes?(T_MAP)
          raise "map literal match pattern will never match value type of #{type}"
        end

        node.entries.each do |entry|
          match(entry.value, T_ANY)
        end
      end


      def match(node : Splat, type : Type)
        match(node.value, T_LIST)
      end


      def match(node : StaticAssignable, type : Type)
        env.current_scope[node.name] = type
      end

      def match(node : Const, type : Type)
        pattern_type = env.current_scope[node.name].instance_type

        unless type.includes?(pattern_type)
          raise "match pattern `#{node.name}` will never match value type of #{type}"
        end
      end

      def match(node : IVar, type : Type)
        env.current_self.scope[node.name] ||= T_ANY
      end
    end
  end
end
