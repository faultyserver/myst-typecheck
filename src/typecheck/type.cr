module Myst
  module TypeCheck
    class Type
      @@next_id = 1_u64
      property id : UInt64

      property name : String
      property scope : Scope

      property! static_type : Type?
      property! instance_type : Type?


      def initialize(@name : String, @id : UInt64 = @@next_id, *, @static_type=nil, @instance_type=nil)
        @scope = Scope.new
        @@next_id += 1
      end

      # To avoid having to check if a type is static in the visitor, assume
      # that static types won't have the `@static_type` relationship set, and
      # return `self` in that case.
      def static_type; @static_type || self; end
      # Likewise for instance types.
      def instance_type; @instance_type || self; end


      # A type is considered instantiable if it has an `instance_type`. This is
      # the type that would be returned by an instantiation of this type.
      def instantiable?
        !!@instance_type
      end

      def_equals_and_hash id

      def to_s(io : IO)
        io << name
      end

      def union_with(other : Type)
        UnionType.new([self, other])
      end

      def union_with(other : UnionType)
        UnionType.new([self] + other.types)
      end

      def includes?(other : Type)
        self == other
      end

      # Excluding a type from a singular type is non-sensical, and should never
      # happen. However, it needs to be supported on all Types for consistency.
      def exclude(other : Type)
        raise "Attempted to exclude #{other} from singular type #{self}."
      end
    end



    class UnionType < Type
      property types : Set(Type)

      # Union types are immutable. Adding a new type to a union creates an
      # entirely new Union.
      def initialize(types : Array(Type))
        @types = Set(Type).new(types.size)
        types.each do |t|
          case t
          when UnionType
            @types.concat(t.types)
          else
            @types.add(t)
          end
        end
        # Union type names are deterministically created as the alphabetic
        # ordering of the names of all the types in the union.
        name = @types.map(&.name).sort.join(" | ")
        super(name)
      end

      def union_with(other : Type)
        UnionType.new(types.to_a + [other])
      end

      def union_with(other : UnionType)
        UnionType.new(types.to_a + other.types.to_a)
      end

      def exclude(other : Type)
        case (remaining_types = types - [other]).size
        when 1
          remaining_types.first
        else
          UnionType.new(remaining_types.to_a)
        end
      end

      def exclude(other : UnionType)
        case (remaining_types = types - other.types).size
        when 1
          remaining_types.first
        else
          UnionType.new(remaining_types.to_a)
        end
      end

      def includes?(other : Type)
        types.includes?(other)
      end

      def includes?(other : UnionType)
        other.types.all?{ |t| types.includes?(t) }
      end

      def_equals_and_hash types
    end


    # `Any` is a special type that implies any type would be valid in its place
    # (including `Nil`), but the entity should not be considered as something
    # generic, like `Object`.
    #
    # For the most part, `Any` is used as placeholders for untyped method
    # parameters and instance variables.
    class AnyType < Type
      def initialize
        super("Any")
      end

      # Since Any represents the ability to be any type, a union with `Any` is
      # meaningless, and should be avoided so that `Any` can always be checked
      # directly.
      def union_with(other : Type)
        self
      end

      # Similarly, `Any` inherently includes any and all types.
      def includes?(other : Type)
        true
      end

      # It also cannot exclude Any types, because the set of remaining types
      # is non-determinable.
      def exclude(other : Type)
        self
      end
    end
  end
end
