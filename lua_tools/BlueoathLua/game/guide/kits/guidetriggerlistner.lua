local GuideTriggerListner = class("Game.Guide.Kits.GuideTriggerListner")

function GuideTriggerListner:initialize(funcCB, objHolder)
  self.bRegister = false
  self.objHolder = objHolder
  self.funcCB = funcCB
  self.nTriggerType = nil
  self.objParam = nil
  
  function self._onTrigger(tbl, tblTriggerParam)
    self:_onTriggerBase(tblTriggerParam)
  end
end

function GuideTriggerListner:register(triggerParam)
  if self.bRegister then
    return
  end
  local nKey, objParam
  local strType = type(triggerParam)
  if strType == "number" then
    nKey = triggerParam
  elseif strType == "table" then
    nKey = triggerParam[1]
    objParam = triggerParam[2]
  end
  self.bRegister = true
  self.nTriggerType = nKey
  self.objParam = objParam
  eventManager:RegisterEvent(LuaEvent.GuideTriggerPoint, self._onTrigger, self)
  eventManager:RegisterEvent(LuaCSharpEvent.GuideTriggerPoint, function(self, param)
    self:_onTrigger(param)
  end, self)
  GR.guideHub:addTrigger(self.nTriggerType, self.objParam)
end

function GuideTriggerListner:_onTriggerBase(tblTriggerParam)
  local nTriggerType, objParam
  local strType = type(tblTriggerParam)
  if strType == "number" then
    nTriggerType = tblTriggerParam
  elseif strType == "table" then
    nTriggerType = tblTriggerParam[1]
    objParam = tblTriggerParam[2]
  end
  if nTriggerType == self.nTriggerType then
    if objParam ~= nil then
      if self.objParam == objParam then
        self.funcCB(self.objHolder, nTriggerType, objParam)
      end
    else
      self.funcCB(self.objHolder, nTriggerType, objParam)
    end
  end
end

function GuideTriggerListner:unRegister()
  if not self.bRegister then
    return
  end
  self.bRegister = false
  eventManager:UnregisterEvent(LuaEvent.GuideTriggerPoint, self._onTrigger)
  eventManager:UnregisterEventByHandler(self)
  GR.guideHub:removeTrigger(self.nTriggerType)
end

return GuideTriggerListner
