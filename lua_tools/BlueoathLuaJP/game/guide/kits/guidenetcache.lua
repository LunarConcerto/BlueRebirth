local GuideNetCache = class("Game.Guide.Kits.GuideNetCache")
local tableInsert = table.insert

function GuideNetCache:initialize()
  self.bDirty = false
  self.tblData = {}
  LateUpdateBeat:Add(self.tick, self)
end

function GuideNetCache:sentNet(strKey, strValue)
  self.bDirty = true
  local bHaveSame = false
  for nIndex, tblContent in pairs(self.tblData) do
    if tblContent.Key == strKey then
      bHaveSame = true
      tblContent.Value = strValue
    end
  end
  if not bHaveSame then
    tableInsert(self.tblData, {Key = strKey, Value = strValue})
  end
end

function GuideNetCache:tick()
  if self.bDirty then
    self:_executeSend()
  end
end

function GuideNetCache:_executeSend()
  if Socket.curState == SocketConnState.Connected then
    Service.guideService:SendUserSetting(self.tblData)
    self.tblData = {}
    self.bDirty = false
  end
end

return GuideNetCache
