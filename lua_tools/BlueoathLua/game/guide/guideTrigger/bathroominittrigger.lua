local BathRoomInitTrigger = class("game.guide.guideTrigger.BathRoomInitTrigger", GR.requires.GuideTriggerBase)

function BathRoomInitTrigger:initialize(nType)
  self.type = nType
  self.objPage = nil
  self.transPage = nil
  self.gameObjPage = nil
  self.transBottom = nil
end

function BathRoomInitTrigger:tick()
  if IsNil(self.objPage) then
    self.objPage = UIPageManager:GetPage("BathRoomPage", nil, 1)
  end
  if IsNil(self.objPage) then
    return
  else
    if IsNil(self.transPage) then
      self.transPage = self.objPage.transform
      self.gameObjPage = self.objPage.gameObject
      self.transBottom = self.transPage:Find("bottom")
    end
    if self.gameObjPage.activeSelf and self.transBottom.localPosition.y > -260 then
      self:sendTrigger()
    end
  end
end

return BathRoomInitTrigger
