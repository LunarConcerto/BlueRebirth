local protobuf = require("net.protobuf.protobuf")
local item_pb = {}
_ENV = item_pb
TITEM = protobuf.Descriptor()
local TITEM_TYPE_FIELD = protobuf.FieldDescriptor()
local TITEM_ID_FIELD = protobuf.FieldDescriptor()
local TITEM_NUM_FIELD = protobuf.FieldDescriptor()
TITEM_TYPE_FIELD.name = "Type"
TITEM_TYPE_FIELD.full_name = ".pb.TItem.Type"
TITEM_TYPE_FIELD.number = 1
TITEM_TYPE_FIELD.index = 0
TITEM_TYPE_FIELD.label = 1
TITEM_TYPE_FIELD.has_default_value = false
TITEM_TYPE_FIELD.default_value = nil
TITEM_TYPE_FIELD.type = 5
TITEM_TYPE_FIELD.cpp_type = 1
TITEM_ID_FIELD.name = "Id"
TITEM_ID_FIELD.full_name = ".pb.TItem.Id"
TITEM_ID_FIELD.number = 2
TITEM_ID_FIELD.index = 1
TITEM_ID_FIELD.label = 1
TITEM_ID_FIELD.has_default_value = false
TITEM_ID_FIELD.default_value = nil
TITEM_ID_FIELD.type = 5
TITEM_ID_FIELD.cpp_type = 1
TITEM_NUM_FIELD.name = "Num"
TITEM_NUM_FIELD.full_name = ".pb.TItem.Num"
TITEM_NUM_FIELD.number = 3
TITEM_NUM_FIELD.index = 2
TITEM_NUM_FIELD.label = 1
TITEM_NUM_FIELD.has_default_value = false
TITEM_NUM_FIELD.default_value = nil
TITEM_NUM_FIELD.type = 5
TITEM_NUM_FIELD.cpp_type = 1
TITEM.file_name = item_pb
TITEM.name = "TItem"
TITEM.full_name = ".pb.TItem"
TITEM.nested_types = {}
TITEM.enum_types = {}
TITEM.fields = {
  TITEM_TYPE_FIELD,
  TITEM_ID_FIELD,
  TITEM_NUM_FIELD
}
TITEM.is_extendable = false
TITEM.extensions = {}
TItem = protobuf.Message(TITEM)
return _ENV
