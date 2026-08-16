local LuaInteraction = class("game.LuaInteraction")

function LuaInteraction:initialize()
  self.CSharpInteraction = CS.CSharpInteraction
  self.CSharpInteraction.Init(self)
end

function LuaInteraction:doCSharpBehaviour(nType, objParam)
  self.CSharpInteraction.DoBehaviour(nType, objParam)
end

function LuaInteraction:addCSharpTrigger(nType, objParam)
  self.CSharpInteraction.AddTrigger(nType, objParam)
end

function LuaInteraction:removeCSharpTrigger(nType)
  self.CSharpInteraction.RemoveTrigger(nType)
end

function LuaInteraction:getSceneManager()
  return self.CSharpInteraction.GetSceneManager()
end

function LuaInteraction:getCameraManager()
  return self.CSharpInteraction.GetCameraManager()
end

function LuaInteraction:getObjectPoolManager()
  return self.CSharpInteraction.GetObjectPoolManager()
end

function LuaInteraction:getRenderBufferManager()
  return self.CSharpInteraction.GetRenderBufferManager()
end

function LuaInteraction:getBaseBuilding3DManager()
  return self.CSharpInteraction.GetBaseBuilding3DManager()
end

function LuaInteraction:clearTrigger()
  self.CSharpInteraction.ClearRunningTrigger()
end

function LuaInteraction:clearUnusedRes()
  self.CSharpInteraction.ClearUnusedRes()
end

function LuaInteraction:getFpsCounterAccord(strName, nLowCount, nAverage)
  return self.CSharpInteraction.GetFpsCounterAccord()
end

function LuaInteraction:setGuideInfluenceData(type, data)
  self.CSharpInteraction.SetGuideInfluenceData(type, data)
end

function LuaInteraction:clearGuideInfluenceData()
  self.CSharpInteraction.ClearInfluenceData()
end

function LuaInteraction:getBattleAuto()
  return self.CSharpInteraction.IsBattleAuto()
end

return LuaInteraction
