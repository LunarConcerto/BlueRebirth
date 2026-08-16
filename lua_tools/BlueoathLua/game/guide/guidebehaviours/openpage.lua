local OpenPage = class("game.Guide.guidebehaviours.OpenPage", GR.requires.BehaviourBase)

function OpenPage:doBehaviour()
  local strType = type(self.objParam)
  if strType == "string" then
    UIHelper.OpenPage(self.objParam)
  elseif strType == "table" then
    local tblParam = self.objParam
    local strPageName = tblParam[1]
    local objParam = tblParam[2]
    local nLayer = tblParam[3]
    local bToStack = tblParam[4]
    if bToStack == nil then
      bToStack = false
    end
    if nLayer == nil then
      nLayer = 0
    end
    UIHelper.OpenPage(strPageName, objParam, nLayer, bToStack)
  end
  self:onDone()
end

return OpenPage
