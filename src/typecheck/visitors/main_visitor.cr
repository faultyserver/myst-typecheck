require "./semantic_visitor.cr"

module Myst
  module TypeCheck
    class MainVisitor < SemanticVisitor
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
        env.current_scope[node.name]
      end

      # Until instance variables can have type restrictions applied to them,
      # we can't effectively/efficiently declare an exact type for them,
      # because their mutations are not directly trackable from the AST. So,
      # at least for now, they are always just typed as generic `Object`s.
      #
      # This is a bit of a cop-out, but is arguably nicer than trying to
      # determine some exact typing that isn't helpfully-accurate at the time
      # of use.
      def visit(node : IVar)
        # If the IVar does not yet exist as an entry, it immediately gets
        # created in the interpreter with the value `Nil`. However, we can't
        # guarantee-ably assume that the first time we see an IVar here will
        # be the first time it gets referenced when running the program, so the
        # best we can do is assign it as an `Any`.
        env.current_self.scope[node.name] ||= T_ANY
      end

      def visit(node : ValueInterpolation)
        visit(node.value)
      end

      def visit(node : Self)
        env.current_self
      end


      def visit(node : SimpleAssign)
        case left = node.target
        when IVar
          env.current_self.scope[left.name, always_create: true] = T_ANY
          T_ANY
        when StaticAssignable
          value_type = visit(node.value)
          env.current_scope[left.name, always_create: true] = value_type
          value_type
        else
          # This should be unreachable. The parser should guarantee that
          # `node.target` is a `StaticAssignable`.
          raise "Invalid target for SimpleAssign: #{left}"
        end
      end

      def visit(node : MatchAssign)
        value_type = visit(node.value)
        match_pattern(node.pattern, value_type)
        value_type
      end

      # Since OpAssigns are generally just a shorthand from `a op= b` to either
      # `a = a op b` or `a op a = b`, the typechecker can do a syntactic
      # replacement to get the same result.
      def visit(node : OpAssign)
        op_expansion =
          case op = node.op[0..-2]
          when "||"
            Or.new(node.target, SimpleAssign.new(node.target, node.value))
          when "&&"
            And.new(node.target, SimpleAssign.new(node.target, node.value))
          else
            Call.new(node.target, op, [node.value])
          end

        full_expansion = SimpleAssign.new(node.target, op_expansion)
        visit(full_expansion)
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
        env.push_scope
        result_type = visit(node.body)
        final_scope = env.pop_scope

        env.push_scope
        alternative = visit(node.alternative)
        final_scope = final_scope.merge!(env.pop_scope, unionize: true, nilify: true)
        result_type = result_type.union_with(alternative)

        env.current_scope.merge!(final_scope, unionize: false, nilify: false)

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

        env.push_scope(Scope.new(env.current_scope))

        condition_type = visit(node.condition)
        could_skip = __is_maybe_falsey?(condition_type)
        will_enter = !could_skip
        loop_will_occur = will_enter
        # If the loop can no longer be taken, iteration can stop.
        return T_NIL if condition_type == T_NIL

        old_change_scope = Scope.new(env.current_scope)
        loop do
          change_scope = Scope.new(env.current_scope)
          env.push_scope(change_scope)
          result_type = visit(node.body)
          # If the scope did not change during the iteration, it can stop.
          break if change_scope == old_change_scope

          condition_type = visit(node.condition)
          env.pop_scope
          env.current_scope.merge!(change_scope, unionize: !loop_will_occur, nilify: !loop_will_occur)
          could_skip = __is_maybe_falsey?(condition_type)
          # If the loop can no longer be taken, iteration can immediately stop.
          break if condition_type == T_NIL

          if loop_will_occur
            loop_will_occur = could_skip
          end
          first_iteration = false
          old_change_scope = change_scope
        end

        loop_scope = env.pop_scope
        env.current_scope.merge!(loop_scope, unionize: !will_enter, nilify: !will_enter)

        unless will_enter
          result_type = result_type.union_with(T_NIL)
        end
        result_type
      end

      def visit(node : Until)
        result_type = T_NIL
        first_iteration = true
        will_enter = false

        env.push_scope(Scope.new(env.current_scope))

        condition_type = visit(node.condition)
        will_enter = condition_type == T_NIL
        will_skip = !__is_maybe_falsey?(condition_type)
        loop_will_occur = will_enter
        # If the loop can no longer be taken, iteration can stop.
        return T_NIL if will_skip

        old_change_scope = Scope.new(env.current_scope)
        loop do
          change_scope = Scope.new(env.current_scope)
          env.push_scope(change_scope)
          result_type = visit(node.body)
          # If the scope did not change during the iteration, it can stop.
          break if change_scope == old_change_scope

          condition_type = visit(node.condition)
          env.pop_scope
          env.current_scope.merge!(change_scope, unionize: !loop_will_occur, nilify: !loop_will_occur)
          will_skip = !__is_maybe_falsey?(condition_type)
          # If the loop can no longer be taken, iteration can immediately stop.
          break if will_skip

          if loop_will_occur
            loop_will_occur = will_skip
          end
          first_iteration = false
          old_change_scope = change_scope
        end

        loop_scope = env.pop_scope
        env.current_scope.merge!(loop_scope, unionize: !will_enter, nilify: !will_enter)

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

        case
        # If the left can't be falsey, the right has no effect on the type
        # of the expression.
        when !__is_maybe_falsey?(left)
          left
        # Otherwise, if the right is not nilable, then the result definitely
        # cannot be nil, so it can be excluded from the union type
        when !right.includes?(T_NIL)
          union_type.exclude(T_NIL)
        # If none of the above are true, the result is just the union of both
        # sides.
        else
          union_type
        end
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


      def visit(node : Splat)
        visit(node.value)
        T_LIST
      end


      def visit(node : Call)
        functor = env.current_scope[node.name].as(Functor)
        arguments = node.args.map do |arg|
          visit(arg)
        end

        clauses = matching_clauses_for_functor(functor, arguments)

        if clauses.size == 0
          raise "No matching clause for Call to #{node.name}"
        end

        # The type result of a Call is the union type of all clauses that
        # could match the given arguments.
        clause_types = clauses.map do |c|
          env.push_scope
          assign_args(c, arguments)
          result = visit(c.body)
          env.pop_scope
          result
        end

        result_union = clause_types.reduce{ |r, t| r.union_with(t) }
        result_union
      end


      def visit(node : Def)
        if node.static?
          env.current_self.static_type.scope[node.name]
        else
          env.current_self.instance_type.scope[node.name]
        end
      end


      def visit(node : ModuleDef)
        module_type = env.current_scope[node.name]
        env.push_self(module_type)
        visit(node.body)
        env.pop_self
        module_type
      end

      def visit(node : TypeDef)
        static = env.current_scope[node.name]
        env.push_self(static)
        visit(node.body)
        env.pop_self
        static
      end

      def visit(node : TypeUnion)
        # Currently, the only valid use of a TypeUnion is as a parameter or
        # return type restriction. In these situations, a _static_ type is
        # named, but the _instance_ type is used for the actual restriction.
        types = node.types.map{ |t| visit(t).instance_type }

        types.reduce do |acc, t|
          acc.union_with(t)
        end
      end


      def visit(node : Instantiation)
        given_type = visit(node.type)

        if !given_type.instantiable?
          raise "Type given for instantiation is not an instantiable."
        end

        return given_type.instance_type
      end



      # Iterate the clauses of the given functor, attempting to match all of
      # the given arguments. Returns the clauses that successfully match.
      private def matching_clauses_for_functor(functor : Functor, arguments : Array(Type))
        functor.clauses.select do |clause|
          next unless clause.params.size == arguments.size

          typed_params = clause.params.map do |param|
            if param.restriction?
              visit(param.restriction).instance_type
            else
              T_ANY
            end
          end

          typed_params.zip(arguments).all? do |(param, arg)|
            types_overlap?(param, arg)
          end
        end
      end


      # Iterate the clause parameters and set their values to the corresponding
      # values in the arguments array.
      private def assign_args(clause : Functor::Clause, arguments : Array(Type))
        clause.params.size.times do |idx|
          param = clause.params[idx]
          arg = arguments[idx]

          if param.name?
            env.current_scope[param.name] = arg
          end
        end
      end

      private def types_overlap?(type1, type2)
        case {type1, type2}
        when {AnyType, _}
          true
        when {_, AnyType}
          true
        when {UnionType, UnionType}
          type1.includes?(type2) || type2.includes?(type1) || type1 == type2
        when {UnionType, Type}
          type1.includes?(type2)
        when {Type, UnionType}
          type2.includes?(type1)
        else
          type1 == type2
        end
      end


      # TODO: Type checking on matches is _very_ weak currently.
      #
      # To improve this:
      #   - Implement optional/inferred generics for List and Map
      #   - Allow type restrictions in match patterns
      #   ? Add Tuples and NamedTuples
      private def match_pattern(pattern : Node, value_type : Type) : Nil
        pattern_visitor = PatternMatcher.new(env)
        pattern_visitor.match(pattern, value_type)
        nil
      end
    end
  end
end
