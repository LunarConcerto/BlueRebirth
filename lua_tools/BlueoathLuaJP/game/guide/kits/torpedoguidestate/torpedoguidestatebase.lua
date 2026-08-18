local torpedoguidestatebase = class("game.guide.kits.torpedoguidestate.torpedoguidestatebase")
local requiredNormalState = require("game.guide.Normalstate.NormalStateBase")

function torpedoguidestatebase:initialize(tblConfig)
end

function torpedoguidestatebase:buildStates(tblStatesConfig)
  for k, v in pairs(tblStatesConfig) do
    self.tblStates[k] = requiredNormalState:new(k, self, v)
  end
end

function torpedoguidestatebase:getStateByKey(nType)
  return self.tblStates[nType]
end

function torpedoguidestatebase:startState(nType)
  local objState = self:getStateByKey(nType)
  objState:start()
end

function torpedoguidestatebase:getMaxType()
  return #self.tblConfig.States
end

function torpedoguidestatebase:enter()
  self:__onEnter()
end

function torpedoguidestatebase:__onEnter()
end

function torpedoguidestatebase:leave()
  self:__onLeave()
end

function torpedoguidestatebase:__onLeave()
end

function torpedoguidestatebase:clear()
end

return torpedoguidestatebase
