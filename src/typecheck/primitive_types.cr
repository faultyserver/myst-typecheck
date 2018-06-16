require "./type.cr"

module Myst
  module TypeCheck
    T_ANY = AnyType.new

    T_OBJECT_T  = Type.new("Type(Object)")
    T_OBJECT    = Type.new("Object", static_type: T_OBJECT_T)
    T_OBJECT_T.instance_type = T_OBJECT

    T_NIL_T  = Type.new("Type(Nil)")
    T_NIL    = Type.new("Nil", static_type: T_NIL_T)
    T_NIL_T.instance_type = T_NIL

    T_BOOLEAN_T  = Type.new("Type(Boolean)")
    T_BOOLEAN    = Type.new("Boolean", static_type: T_BOOLEAN_T)
    T_BOOLEAN_T.instance_type = T_BOOLEAN

    T_INTEGER_T  = Type.new("Type(Integer)")
    T_INTEGER    = Type.new("Integer", static_type: T_INTEGER_T)
    T_INTEGER_T.instance_type = T_INTEGER

    T_FLOAT_T  = Type.new("Type(Float)")
    T_FLOAT    = Type.new("Float", static_type: T_FLOAT_T)
    T_FLOAT_T.instance_type = T_FLOAT

    T_STRING_T  = Type.new("Type(String)")
    T_STRING    = Type.new("String", static_type: T_STRING_T)
    T_STRING_T.instance_type = T_STRING

    T_SYMBOL_T  = Type.new("Type(Symbol)")
    T_SYMBOL    = Type.new("Symbol", static_type: T_SYMBOL_T)
    T_SYMBOL_T.instance_type = T_SYMBOL

    T_LIST_T  = Type.new("Type(List)")
    T_LIST    = Type.new("List", static_type: T_LIST_T)
    T_LIST_T.instance_type = T_LIST

    T_MAP_T  = Type.new("Type(Map)")
    T_MAP    = Type.new("Map", static_type: T_MAP_T)
    T_MAP_T.instance_type = T_MAP

    T_TYPE_T  = Type.new("Type(Type)")
    T_TYPE    = Type.new("Type", static_type: T_TYPE_T)
    T_TYPE_T.instance_type = T_TYPE

    T_MODULE_T  = Type.new("Type(Module)")
    T_MODULE    = Type.new("Module", static_type: T_MODULE_T)
    T_MODULE_T.instance_type = T_MODULE

    T_FUNCTOR_T  = Type.new("Type(Functor)")
    T_FUNCTOR    = Type.new("Functor", static_type: T_FUNCTOR_T)
    T_FUNCTOR_T.instance_type = T_FUNCTOR
  end
end
