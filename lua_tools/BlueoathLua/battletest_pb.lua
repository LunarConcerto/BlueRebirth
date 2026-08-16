local protobuf = require("net.protobuf.protobuf")
BattleTest_pb = {}
local m = BattleTest_pb
local g = _G
local rawget = rawget
local rawset = rawset
_ENV = setmetatable({}, {
  __index = function(t, k)
    return rawget(m, k) or rawget(g, k)
  end,
  __newindex = m
})
BATTLETEST = protobuf.Descriptor()
local BATTLETEST_TEST_VALUE_FIELD = protobuf.FieldDescriptor()
BATTLETEST_TEST_VALUE_FIELD.name = "test_value"
BATTLETEST_TEST_VALUE_FIELD.full_name = ".pb.BattleTest.test_value"
BATTLETEST_TEST_VALUE_FIELD.number = 1
BATTLETEST_TEST_VALUE_FIELD.index = 0
BATTLETEST_TEST_VALUE_FIELD.label = 1
BATTLETEST_TEST_VALUE_FIELD.has_default_value = false
BATTLETEST_TEST_VALUE_FIELD.default_value = nil
BATTLETEST_TEST_VALUE_FIELD.type = 2
BATTLETEST_TEST_VALUE_FIELD.cpp_type = 6
BATTLETEST.name = "BattleTest"
BATTLETEST.full_name = ".pb.BattleTest"
BATTLETEST.nested_types = {}
BATTLETEST.enum_types = {}
BATTLETEST.fields = {BATTLETEST_TEST_VALUE_FIELD}
BATTLETEST.is_extendable = false
BATTLETEST.extensions = {}
BattleTest = protobuf.Message(BATTLETEST)
