module Myst
  module TypeCheck
    class Type
      @@next_id = 1_u64
      property id : UInt64

      property name : String
      property instance_methods : Hash(String, Method)
      property static_methods : Hash(String, Method)


      def initialize(@name : String, @id : UInt64 = @@next_id)
        @instance_methods = {} of String => Method
        @static_methods = {} of String => Method
        @@next_id += 1
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
  end
end
