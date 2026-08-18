FSM = require("fsm")

function action1()
  print("Performing action 1")
end

function action2()
  print("Performing action 2")
end

function action3()
  print("Action 3: Exception raised")
end

function action4()
  print("Wildcard in action !!!")
end

local myStateTransitionTable = {
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
fsm = FSM.new(myStateTransitionTable)
print("Constant FSM.UNKNOWN = " .. FSM.UNKNOWN)
print("Current FSM state: " .. fsm:get())
fsm:set("state2")
print("Current FSM state: " .. fsm:get())
fsm:fire("event2")
print("Current FSM state: " .. fsm:get())
print("Force exception by firing unknown event")
fsm:fire("event3")
print("Current FSM state: " .. fsm:get())
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
    "?",
    "state1",
    action3
  }
}
fsm2 = FSM.new(myStateTransitionTable2)
fsm2:set("state2")
print([[

Current FSM-2 state: ]] .. fsm2:get())
fsm2:delete({
  {"state2", "event2"}
})
fsm2:fire("event2")
fsm2:delete({
  {"*", "?"}
})
print("Force third exception (silence = true)")
fsm2:silent()
fsm2:fire("event3")
print("Current FSM-2 state after firing  wildcard 'event3': " .. fsm2:get())
fsm2:add({
  {
    "*",
    "*",
    "state2",
    action3
  }
})
fsm2:fire("event2")
print("Current FSM-2 state: " .. fsm2:get())
print("Current FSM state: " .. fsm:get())
