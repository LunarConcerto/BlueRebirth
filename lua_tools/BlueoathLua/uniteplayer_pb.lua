local protobuf = require("net.protobuf.protobuf")
uniteplayer_pb = {}
local m = uniteplayer_pb
local g = _G
local rawget = rawget
local rawset = rawset
_ENV = setmetatable({}, {
  __index = function(t, k)
    return rawget(m, k) or rawget(g, k)
  end,
  __newindex = m
})
TARGUNITELOGIN = protobuf.Descriptor()
local TARGUNITELOGIN_UNAME_FIELD = protobuf.FieldDescriptor()
TARGUNITELOGIN_UNAME_FIELD.name = "Uname"
TARGUNITELOGIN_UNAME_FIELD.full_name = ".pb.TArgUniteLogin.Uname"
TARGUNITELOGIN_UNAME_FIELD.number = 1
TARGUNITELOGIN_UNAME_FIELD.index = 0
TARGUNITELOGIN_UNAME_FIELD.label = 1
TARGUNITELOGIN_UNAME_FIELD.has_default_value = false
TARGUNITELOGIN_UNAME_FIELD.default_value = nil
TARGUNITELOGIN_UNAME_FIELD.type = 9
TARGUNITELOGIN_UNAME_FIELD.cpp_type = 9
TARGUNITELOGIN.name = "TArgUniteLogin"
TARGUNITELOGIN.full_name = ".pb.TArgUniteLogin"
TARGUNITELOGIN.nested_types = {}
TARGUNITELOGIN.enum_types = {}
TARGUNITELOGIN.fields = {TARGUNITELOGIN_UNAME_FIELD}
TARGUNITELOGIN.is_extendable = false
TARGUNITELOGIN.extensions = {}
TArgUniteLogin = protobuf.Message(TARGUNITELOGIN)
