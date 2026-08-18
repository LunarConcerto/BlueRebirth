local IsPageOpen = class("game.guide.guideTrigger.IsPageOpen", GR.requires.GuideTriggerBase)

function IsPageOpen:initialize(nType)
  self.type = nType
end

function IsPageOpen:onStart(strPageName)
  self.bSubPage = false
  local strType = type(strPageName)
  if strType == "string" then
    self.strPageName = strPageName
  elseif strType == "table" then
    self.bSubPage = true
    self.strMainPage = strPageName[1]
    self.strSubPage = strPageName[2]
  end
end

function IsPageOpen:tick()
  if self.bSubPage then
    if UIHelper.IsSubPageOpen(self.strMainPage, self.strSubPage) then
      self:sendTrigger()
    end
  elseif UIHelper.IsPageOpen(self.strPageName) then
    self:sendTrigger()
  end
end

return IsPageOpen
