require "./type.cr"

module Myst
  module TypeCheck
    class Scope < Hash(String, Type)
      property! parent : Scope?

      def initialize(@parent : Scope? = nil, initial_capacity=nil)
        super(initial_capacity: initial_capacity)
      end

      def []?(key)
        fetch(key) { parent?.try(&.fetch(key, nil)) }
      end

      def [](key)
        if parent?
          fetch(key, nil) || parent[key]
        else
          fetch(key)
        end
      end

      def []=(key, value, always_create=false)
        if always_create
          return assign(key, value)
        end

        scope = self
        while scope
          if scope.has_key?(key)
            return scope.assign(key, value)
          end
          scope = scope.parent?
        end

        assign(key, value)
      end


      # Merge the entries of the given Scope into this one. If `unionize` is
      # set to true, duplicate entries will be replaced in this scope with the
      # union of both. If it is false, `other` will take precedence.
      #
      # If `nilify` is set to true, and a given key is not present in both
      # scopes, then the resulting type will be unioned with Nil in the merge.
      #
      # `nilify_left` is similar to `nilify`, but only unions with Nil if the
      # key does not exist in the left hand side.
      def merge!(other : Scope, *, unionize=true, nilify=false)
        (keys | other.keys).each do |key|
          left = self[key]?
          that = other[key]?
          new_type =
            case
            when left && that
              unionize ? left.union_with(that) : that
            when left
              nilify ? left.union_with(T_NIL) : left
            when that
              nilify ? that.union_with(T_NIL) : that
            else
              raise "Unreachable error reached while merging scopes."
            end

          self[key] = new_type
        end
        self
      end


      def find_or_assign(key, new_value)
        if has_key?(key)
          self[key]
        else
          assign(key, new_value)
        end
      end


      # TODO: this is an alias for Hash's `[]=`. Since we override it to
      # work with parent scopes, this alternative handles assigning only
      # within this scope. Finding a nice way to make this alias implicitly
      # would be great.
      #
      # Ideally, this would've been done with `alias_method :[]=, :assign`,
      # but that was removed from the language.
      protected def assign(key, value)
        rehash if @size > 5 * @buckets_size

        index = bucket_index key
        entry = insert_in_bucket index, key, value
        return value unless entry

        @size += 1

        if last = @last
          last.fore = entry
          entry.back = last
        end

        @last = entry
        @first = entry unless @first
        value
      end
    end
  end
end
