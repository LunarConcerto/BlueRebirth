local fsm = class("FSM.fsm")
SEPARATOR = "."
ANY = "*"
ANYSTATE = ANY .. SEPARATOR
ANYEVENT = SEPARATOR .. ANY
UNKNOWN = ANYSTATE .. ANY

function fsm:set(s)
  self.state = s
end

function fsm:get()
  return self.state
end

function fsm:silent()
  self.silence = true
end

local exception = function()
  print("FSM: unknown combination")
  return false
end

function fsm:fire(event)
  local act = self.stt[self.state .. SEPARATOR .. event]
  if act == nil then
    act = self.stt[ANYSTATE .. event]
    if act == nil then
      act = self.stt[self.state .. ANYEVENT]
      if act == nil then
        act = self.stt[UNKNOWN]
        self.str = self.state .. SEPARATOR .. event
      end
    end
  end
  self.state = act.newState
  return act.action()
end

function fsm:add(t)
  for _, v in ipairs(t) do
    local oldState, event, newState, action = v[1], v[2], v[3], v[4]
    self.stt[oldState .. SEPARATOR .. event] = {newState = newState, action = action}
  end
  return #t
end

function fsm:delete(t)
  for _, v in ipairs(t) do
    local oldState, event = v[1], v[2]
    if oldState == ANY and event == ANY then
      if not self.silence then
        print("FSM: you should not delete the exception handler")
        print("FSM: but assign another exception action")
      end
      self.stt[exception] = {
        newState = self.state,
        action = exception
      }
    else
      self.stt[oldState .. SEPARATOR .. event] = nil
    end
  end
  return #t
end

function fsm:initialize(t)
  self.state = t[1][1]
  self.stt = {}
  self.str = ""
  self.silence = false
  self.stt[UNKNOWN] = {
    newState = self.state,
    action = exception
  }
  self:add(t)
end

return fsm
