require "./semantic_visitor.cr"
require "../exceptions.cr"

module Myst
  module TypeCheck
    class MainVisitor < SemanticVisitor
      def visit(node : Nop)
        return env.t_nil
      end

      def visit(node : Expressions)
        node.children.reduce(env.t_object) do |acc, child|
          acc = visit(child)
        end
      end


      def visit(node : NilLiteral);                 return env.t_nil;     end
      def visit(node : BooleanLiteral);             return env.t_boolean; end
      def visit(node : IntegerLiteral);             return env.t_integer; end
      def visit(node : FloatLiteral);               return env.t_float;   end
      def visit(node : StringLiteral);              return env.t_string;  end
      def visit(node : InterpolatedStringLiteral);  return env.t_string;  end
      def visit(node : SymbolLiteral);              return env.t_symbol;  end
      def visit(node : ListLiteral);                return env.t_list;    end
      def visit(node : MapLiteral);                 return env.t_map;     end


      def visit(node : MagicConst)
        case node.type
        when :__LINE__
          env.t_integer
        when :__FILE__
          env.t_string
        when :__DIR__
          env.t_string
        else
          raise "Magic Constant #{node.type} has not been given a definite type."
        end
      end

      def visit(node : FunctionCapture)
        captured =
          case target = node.value
          when Call
            receiver = env.current_self
            if target.receiver?
              receiver = visit(target.receiver)
            end

            env.push_self(receiver)
            functor = env.current_scope[target.name]?
            env.pop_self

            unless functor
              raise "No function with the name `#{target.name}` exists for type `#{receiver}`"
            end

            functor
          # Local variables can be used in captures as passthroughs for block
          # parameters.
          when StaticAssignable
            receiver = env.current_self
            functor = env.current_scope[target.name]?
            unless functor
              # This shouldn't be reachable. If the target is a
              # `StaticAssignable`, it must at least exist as a local variable.
              # The later `is_a?(Functor)` check should be enough.
              raise "No function with the name `#{target.name}` exists in current scope"
            end
            functor
          when AnonymousFunction
            visit(target)
          else
            env.t_nil
          end

        unless captured.is_a?(Functor)
          raise "Function capture target is not a Functor (got `#{captured}` instead)"
        end
        captured
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
        env.current_self.scope[node.name] ||= env.t_any
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
          env.current_self.scope[left.name, always_create: true] = env.t_any
          env.t_any
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
        final_scope = final_scope.merge!(env.pop_scope, unionize: true, nilify: env.t_nil)
        result_type = result_type.union_with(alternative)

        env.current_scope.merge!(final_scope, unionize: false, nilify: nil)

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
        result_type = env.t_nil
        first_iteration = true
        will_enter = false

        env.push_scope(Scope.new(env.current_scope))

        condition_type = visit(node.condition)
        could_skip = __is_maybe_falsey?(condition_type)
        will_enter = !could_skip
        loop_will_occur = will_enter
        # If the loop can no longer be taken, iteration can stop.
        return env.t_nil if condition_type == env.t_nil

        old_change_scope = Scope.new(env.current_scope)
        loop do
          change_scope = Scope.new(env.current_scope)
          env.push_scope(change_scope)
          result_type = visit(node.body)
          # If the scope did not change during the iteration, it can stop.
          break if change_scope == old_change_scope

          condition_type = visit(node.condition)
          env.merge_scope!(unionize: !loop_will_occur, nilify: !loop_will_occur)
          could_skip = __is_maybe_falsey?(condition_type)
          # If the loop can no longer be taken, iteration can immediately stop.
          break if condition_type == env.t_nil

          if loop_will_occur
            loop_will_occur = could_skip
          end
          first_iteration = false
          old_change_scope = change_scope
        end

        env.merge_scope!(unionize: !will_enter, nilify: !will_enter)

        unless will_enter
          result_type = result_type.union_with(env.t_nil)
        end
        result_type
      end

      def visit(node : Until)
        result_type = env.t_nil
        first_iteration = true
        will_enter = false

        env.push_scope(Scope.new(env.current_scope))

        condition_type = visit(node.condition)
        will_enter = condition_type == env.t_nil
        will_skip = !__is_maybe_falsey?(condition_type)
        loop_will_occur = will_enter
        # If the loop can no longer be taken, iteration can stop.
        return env.t_nil if will_skip

        old_change_scope = Scope.new(env.current_scope)
        loop do
          change_scope = Scope.new(env.current_scope)
          env.push_scope(change_scope)
          result_type = visit(node.body)
          # If the scope did not change during the iteration, it can stop.
          break if change_scope == old_change_scope

          condition_type = visit(node.condition)
          env.merge_scope!(unionize: !loop_will_occur, nilify: !loop_will_occur)
          will_skip = !__is_maybe_falsey?(condition_type)
          # If the loop can no longer be taken, iteration can immediately stop.
          break if will_skip

          if loop_will_occur
            loop_will_occur = will_skip
          end
          first_iteration = false
          old_change_scope = change_scope
        end

        env.merge_scope!(unionize: !will_enter, nilify: !will_enter)

        unless will_enter
          result_type = result_type.union_with(env.t_nil)
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
        when !right.includes?(env.t_nil)
          union_type.exclude(env.t_nil)
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
        when left == env.t_nil
          return env.t_nil
        when left.includes?(env.t_boolean)
          union_type
        else
          right
        end
      end

      # Not is currently an overrideable boolean operator, though in practice
      # it is not overridden, and even when it is it should return a boolean.
      # This could be expanded to work like a normal Call, or maybe the
      # language will change to disallow overriding the operator.
      #
      # NOTE: This is an intentional deviation from the current behavior of Myst
      # itself. Realistically, allowing the override of the Not operation
      # (`!expr`) is not useful and causes unnecessary confusion and inconsistency
      # when done in multiple places.
      def visit(node : Not)
        env.t_boolean
      end

      def visit(node : Negation)
        visit(Call.new(
          receiver: node.value,
          name: "negate"
        ))
      end


      def visit(node : Splat)
        visit(node.value)
        env.t_list
      end


      def visit(node : Call)
        receiver = env.current_self
        if node.receiver?
          receiver = visit(node.receiver)
        end

        possible_results =
          case receiver
          when UnionType
            receiver.types.reduce([] of Type) do |acc, t|
              acc.concat(visit_single_type_call(t, node))
              acc
            end
          else
            clause_types = visit_single_type_call(receiver, node)
            clause_types
          end

        result_union = possible_results.reduce{ |r, t| r.union_with(t) }
        result_union
      end

      # TODO:
      # Determine all available clauses for the Call by iterating through the
      # ancestors of `receiver`.
      #
      # ALSO NEEDS:
      # - FunctionCaptures must bind a value for `self` to use when looking up
      #   ancestral functions.
      # - Determine "permeability": whether a given ancestor's functor clauses
      #   capture all possible calls to the function to stop iteration.
      private def visit_single_type_call(receiver, node)
        arguments = node.args.map{ |arg| visit(arg) }
        block = node.block? ? visit(node.block) : nil

        clause_types =
          receiver.ancestors.reduce([] of Type) do |acc, recv|
            env.push_self(recv)
            functor =
              case name = node.name
              when Node
                f = visit(name)
              else
                f = env.current_scope[name]?
                unless f
                  raise "No function with the name `#{name}` exists for type `#{receiver}`"
                end

                f
              end

            unless functor.is_a?(Functor)
              raise "Expression for Call did not resolve to a Callable object (was #{f})"
            end

            clauses = matching_clauses_for_functor(functor, arguments, block)

            # The type result of a Call is the union type of all clauses that
            # could match the given arguments.
            types = clauses.map do |c|
              env.push_scope()
              assign_args(c, arguments, block)
              return_restriction = c.return_type? ? visit(c.return_type).instance_type : nil
              result = visit_clause(c.body, return_restriction)
              env.pop_scope()
              result
            end

            env.pop_self

            acc.concat(types)
          end


        if clause_types.empty?
          raise "No matching clause for Call to #{node.name}"
        end

        clause_types
      end

      # Iterate the clauses of the given functor, attempting to match all of
      # the given arguments. Returns the clauses that successfully match.
      private def matching_clauses_for_functor(functor : Functor, arguments : Array(Type), block : Type?)
        functor.clauses.select do |clause|
          next unless clause.params.size == arguments.size

          typed_params = clause.params.map do |param|
            if param.restriction?
              visit(param.restriction).instance_type
            else
              env.t_any
            end
          end

          all_params_match =
            typed_params.zip(arguments).all? do |(param, arg)|
              types_overlap?(param, arg)
            end

          block_matches =
            if clause.block_param?
              !!block
            else
              !block
            end

          all_params_match && block_matches
        end
      end


      def visit(node : Def)
        if node.static?
          env.current_self.static_type.scope[node.name]
        else
          env.current_self.instance_type.scope[node.name]
        end
      end

      def visit(node : Block)
        Functor.new(node.location.to_s).add_clause(node)
      end

      def visit(node : AnonymousFunction)
        functor = Functor.new(node.location.to_s)
        node.clauses.each{ |c| functor.add_clause(c) }
        functor
      end


      def visit(node : Match)
        visit(Call.new(nil,
          name: AnonymousFunction.new(node.clauses, internal_name: "match").at(node),
          args: node.arguments,
          block: nil,
          infix: false
        ).at(node))
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
        super_type =
          if node.supertype?
            visit(node.supertype)
          end
        __set_supertype(static, super_type)

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



      def visit(node : Require)
        # `required_tree` is set by the ProgramExpander that runs before
        # this visitor when the expression results in new code being loaded.
        # This ensures that subsequent visitors only see this code once in
        # the process of scanning the entire program tree.
        if node.required_tree?
          visit(node.required_tree)
        end

        # `require` always returns either `true` or `false` depending on
        # whether the expression resulted in new code being loaded. The
        # side effects of the `require` do not affect the resulting type.
        env.t_boolean
      end



      # Return expressions have no immediate resulting type as they cause the
      # flow of execution to break. Instead, the type gets added to the current
      # `return_type` of the Environment to be considered as part of the
      # enclosing clause's return type.
      def visit(node : Return)
        node_type = visit(node.value)
        env.add_return_type(node_type)
      end

      # Next is currently a semantic equivalent of Return.
      def visit(node : Next)
        node_type = visit(node.value)
        env.add_return_type(node_type)
      end


      # Iterate the clause parameters and set their values to the corresponding
      # values in the arguments array.
      private def assign_args(clause : Functor::Clause, arguments : Array(Type), block : Type?)
        clause.params.size.times do |idx|
          param = clause.params[idx]
          arg = arguments[idx]

          if param.name?
            env.current_scope[param.name] = arg
          end
        end

        if (block_param = clause.block_param?) && block
          env.current_scope[block_param.name] = block
        end
      end

      # This method assumes that all setup for visiting the clause has been
      # performed already, including assigning parameters and pushing the
      # receiver to the `self_stack`. This method takes care of managing the
      # `return` and `break` stacks.
      private def visit_clause(node : Node, return_restriction : Type? = nil)
        env.push_return_scope()
        implicit_return_type = visit(node)
        explicit_return_type = env.pop_return_scope()

        complete_return_type =
          if explicit_return_type
            explicit_return_type.union_with(implicit_return_type)
          else
            implicit_return_type
          end

        if return_restriction
          unless return_restriction == complete_return_type
            raise ReturnTypeMismatchError.new(return_restriction, complete_return_type)
          end
        end

        complete_return_type
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
          type1.includes?(type2)
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
