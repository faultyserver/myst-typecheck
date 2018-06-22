require "./type.cr"

module Myst
  module TypeCheck
    module PrimitiveTypes
      getter t_any          = AnyType.new

      getter t_object_t     = Type.new("Type(Object)")
      getter t_object       = Type.new("Object", static_type: @t_object_t)

      getter t_nil_t        = Type.new("Type(Nil)")
      getter t_nil          = Type.new("Nil", static_type: @t_nil_t)

      getter t_boolean_t    = Type.new("Type(Boolean)")
      getter t_boolean      = Type.new("Boolean", static_type: @t_boolean_t)

      getter t_integer_t    = Type.new("Type(Integer)")
      getter t_integer      = Type.new("Integer", static_type: @t_integer_t)

      getter t_float_t      = Type.new("Type(Float)")
      getter t_float        = Type.new("Float", static_type: @t_float_t)

      getter t_string_t     = Type.new("Type(String)")
      getter t_string       = Type.new("String", static_type: @t_string_t)

      getter t_symbol_t     = Type.new("Type(Symbol)")
      getter t_symbol       = Type.new("Symbol", static_type: @t_symbol_t)

      getter t_list_t       = Type.new("Type(List)")
      getter t_list         = Type.new("List", static_type: @t_list_t)

      getter t_map_t        = Type.new("Type(Map)")
      getter t_map          = Type.new("Map", static_type: @t_map_t)

      getter t_type_t       = Type.new("Type(Type)")
      getter t_type         = Type.new("Type", static_type: @t_type_t)

      getter t_module_t  = Type.new("Type(Module)")
      getter t_module    = Type.new("Module", static_type: @t_module_t)

      getter t_functor_t  = Type.new("Type(Functor)")
      getter t_functor    = Type.new("Functor", static_type: @t_functor_t)

      def init_primitives
        t_object_t.instance_type    = t_object
        t_nil_t.instance_type       = t_nil
        t_boolean_t.instance_type   = t_boolean
        t_integer_t.instance_type   = t_integer
        t_float_t.instance_type     = t_float
        t_string_t.instance_type    = t_string
        t_symbol_t.instance_type    = t_symbol
        t_list_t.instance_type      = t_list
        t_map_t.instance_type       = t_map
        t_type_t.instance_type      = t_type
        t_module_t.instance_type    = t_module
        t_functor_t.instance_type   = t_functor
      end
    end
  end
end
