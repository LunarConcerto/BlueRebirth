local AutoTestManager = class("game.AutoTest.AutoTestManager")
local requireObj = require("game.AutoTest.AutoTestObject")

function AutoTestManager:initialize()
  self.config = require("game.AutoTest.AutoTestConfig.AutoTestConfig")
  self.tblAllObj = {}
  self.objCur = nil
  self.transRootUI = UIManager.rootUI
  LateUpdateBeat:Add(self.tick, self)
  self:init()
  self.bAuto = false
end

function AutoTestManager:init()
  for k, v in pairs(self.config) do
    self.tblAllObj[k] = requireObj:new(v, self)
  end
end

function AutoTestManager:stopCurAndPlay(nType)
  local targetObj = self.tblAllObj[nType]
  if targetObj == nil then
    logError("cant find AutoTest Type " .. tostring(nType))
    return
  end
  self:stopCurObj()
  targetObj:play()
  self.objCur = targetObj
  bAuto = true
end

function AutoTestManager:stopCurObj()
  if self.objCur ~= nil then
    self.objCur:stop()
    bAuto = false
  end
end

function AutoTestManager:onAutoTestDone(obj)
  if bAuto then
    obj:reset()
    obj:play()
  end
end

function AutoTestManager:tick()
  for k, v in pairs(self.tblAllObj) do
    v:tick()
  end
end

function AutoTestManager:clickBtn(strPath)
  local transTarget = self.transRootUI:Find(strPath)
  if transTarget == nil then
    return false
  end
  local objTarget = transTarget.gameObject
  if objTarget.activeSelf then
    local eventListner = objTarget:GetComponent(BabelTime_GD_UI_UGUIEventListener.GetClassType())
    eventListner.onClick()
    return true
  else
    return false
  end
end

function AutoTestManager:clickToggle(strPath)
  local transTarget = self.transRootUI:Find(strPath)
  if transTarget == nil then
    return false
  end
  local objTarget = transTarget.gameObject
  if objTarget.activeSelf then
    local eventListner = objTarget:GetComponent(UIToggle.GetClassType())
    eventListner.isOn = true
    return true
  else
    return false
  end
end

return AutoTestManager
