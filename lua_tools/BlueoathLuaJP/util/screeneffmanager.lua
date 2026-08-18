local ScreenEffManager = class("util.ScreenEffManager")
local effectPath = "effects/prefabs/ui/eff_hand_click"

function ScreenEffManager:initialize()
  self:__registerInput()
end

function ScreenEffManager:__registerInput()
  local tabParam = {
    freeClickDown = function(param)
      self:__onClickScreen(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function ScreenEffManager:__onClickScreen(pos)
  pos = UIManager.uiCamera:ScreenToWorldPoint(pos)
  local effectObj = GR.objectPoolManager:LuaGetGameObject(effectPath, UIManager.rootEffect, 5)
  effectObj.transform.position = pos
  effectObj.transform.localScale = Vector3.one
  GR.objectPoolManager:LuaUnspawnDelay(effectObj, 0.9)
end

return ScreenEffManager
