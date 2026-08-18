require("luaunit")
FSM = require("fsm")

function action1()
  return 1
end

function action2()
  return 2
end

function action3()
  return 3
end

function action4()
  return 4
end

TestFSM = {}

function TestFSM:setUp()
  local myStateTransitionTable1 = {
    {
      "state1",
      "event1",
      "state2",
      action1
    },
    {
      "state2",
      "event2",
      "state3",
      action2
    }
  }
  local myStateTransitionTable2 = {
    {
      "state1",
      "event1",
      "state2",
      action1
    },
    {
      "state2",
      "event2",
      "state3",
      action2
    },
    {
      "*",
      "event3",
      "state1",
      action4
    },
    {
      "*",
      "*",
      "state1",
      action3
    }
  }
  fsm1 = FSM.new(myStateTransitionTable1)
  fsm2 = FSM.new(myStateTransitionTable2)
  fsm1:silent()
  fsm2:silent()
end

function TestFSM:test1()
  assertEquals(FSM.UNKNOWN, "*.*")
  assertEquals(fsm1:get(), "state1")
  fsm1:set("state2")
  assertEquals(fsm1:get(), "state2")
  assertEquals(fsm1:fire("event2"), 2)
  assertEquals(fsm1:get(), "state3")
  assertEquals(fsm1:fire("event3"), false)
  assertEquals(fsm1:get(), "state1")
end

function TestFSM:test2()
  assertEquals(fsm2:get(), "state1")
  fsm2:set("state2")
  assertEquals(fsm2:get(), "state2")
  assertEquals(fsm2:fire("event2"), 2)
  assertEquals(fsm2:get(), "state3")
  assertEquals(fsm2:fire("event3"), 4)
  assertEquals(fsm2:get(), "state1")
end

function TestFSM:test3()
  fsm2:set("state2")
  assertEquals(fsm2:get(), "state2")
  assertEquals(fsm2:delete({
    {"state2", "event2"}
  }), 1)
  assertEquals(fsm2:fire("event2"), 3)
  assertEquals(fsm2:get(), "state1")
  assertEquals(fsm2:delete({
    {"*", "*"}
  }), 1)
  assertEquals(fsm2:add({
    {
      "*",
      "*",
      "state2",
      action3
    }
  }), 1)
  assertEquals(fsm2:fire("event2"), 3)
end

LuaUnit:run()
