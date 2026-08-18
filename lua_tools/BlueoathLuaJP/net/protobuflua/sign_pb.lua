local protobuf = require("net.protobuf.protobuf")
local commonreward_pb = require("net.protobuflua.commonreward_pb")
local sign_pb = {}
_ENV = sign_pb
TSIGNINFO = protobuf.Descriptor()
local TSIGNINFO_SIGNCOUNT_FIELD = protobuf.FieldDescriptor()
local TSIGNINFO_SIGNTIME_FIELD = protobuf.FieldDescriptor()
local TSIGNINFO_REWARD_FIELD = protobuf.FieldDescriptor()
TSIGNINFO_SIGNCOUNT_FIELD.name = "SignCount"
TSIGNINFO_SIGNCOUNT_FIELD.full_name = ".pb.TSignInfo.SignCount"
TSIGNINFO_SIGNCOUNT_FIELD.number = 1
TSIGNINFO_SIGNCOUNT_FIELD.index = 0
TSIGNINFO_SIGNCOUNT_FIELD.label = 1
TSIGNINFO_SIGNCOUNT_FIELD.has_default_value = false
TSIGNINFO_SIGNCOUNT_FIELD.default_value = nil
TSIGNINFO_SIGNCOUNT_FIELD.type = 5
TSIGNINFO_SIGNCOUNT_FIELD.cpp_type = 1
TSIGNINFO_SIGNTIME_FIELD.name = "SignTime"
TSIGNINFO_SIGNTIME_FIELD.full_name = ".pb.TSignInfo.SignTime"
TSIGNINFO_SIGNTIME_FIELD.number = 2
TSIGNINFO_SIGNTIME_FIELD.index = 1
TSIGNINFO_SIGNTIME_FIELD.label = 1
TSIGNINFO_SIGNTIME_FIELD.has_default_value = false
TSIGNINFO_SIGNTIME_FIELD.default_value = nil
TSIGNINFO_SIGNTIME_FIELD.type = 5
TSIGNINFO_SIGNTIME_FIELD.cpp_type = 1
TSIGNINFO_REWARD_FIELD.name = "Reward"
TSIGNINFO_REWARD_FIELD.full_name = ".pb.TSignInfo.Reward"
TSIGNINFO_REWARD_FIELD.number = 3
TSIGNINFO_REWARD_FIELD.index = 2
TSIGNINFO_REWARD_FIELD.label = 3
TSIGNINFO_REWARD_FIELD.has_default_value = false
TSIGNINFO_REWARD_FIELD.default_value = {}
TSIGNINFO_REWARD_FIELD.message_type = commonreward_pb.TCOMMONREWARD
TSIGNINFO_REWARD_FIELD.type = 11
TSIGNINFO_REWARD_FIELD.cpp_type = 10
TSIGNINFO.file_name = sign_pb
TSIGNINFO.name = "TSignInfo"
TSIGNINFO.full_name = ".pb.TSignInfo"
TSIGNINFO.nested_types = {}
TSIGNINFO.enum_types = {}
TSIGNINFO.fields = {
  TSIGNINFO_SIGNCOUNT_FIELD,
  TSIGNINFO_SIGNTIME_FIELD,
  TSIGNINFO_REWARD_FIELD
}
TSIGNINFO.is_extendable = false
TSIGNINFO.extensions = {}
TSignInfo = protobuf.Message(TSIGNINFO)
return _ENV
