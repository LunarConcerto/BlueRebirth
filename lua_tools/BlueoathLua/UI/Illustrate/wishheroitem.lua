local WishHeroItem = class("UI.Illustrate.WishHeroItem")
local QualityType = {
  VerCardQualityImg,
  FleetCardQualityImg,
  FleetSmallCardQualityImg,
  FleetBottomCardQulity
}

function WishHeroItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.heroInfo = {}
  self.index = 0
  self.m_posTwn = nil
  self.m_scaleTwn = nil
  self.comwidgets = nil
end

function WishHeroItem:Init(obj, tabPart, data, index, common)
  self.page = obj
  self.tabPart = tabPart
  self.heroInfo = data
  self.index = index
  self.comwidgets = common
  self:_SetHeroInfo()
  self.pos = self.tabPart.objSelf.transform.localPosition
  if index == 1 and not eventManager:HaveListener(LuaEvent.WishCardUpMove) then
    eventManager:RegisterEvent(LuaEvent.WishCardUpMove, self.PlaySelectTwn, self)
  end
end

function WishHeroItem:_SetHeroInfo()
  local childPart = self.tabPart.childpart:GetLuaTableParts()
  local shipShowConfig, shipInfo
  if self.heroInfo.HeroId > 0 then
    shipShowConfig = Logic.shipLogic:GetShipShowByHeroId(self.heroInfo.HeroId)
    shipInfo = Logic.shipLogic:GetShipInfoByHeroId(self.heroInfo.HeroId)
  else
    shipShowConfig = Logic.shipLogic:GetShipShowById(self.heroInfo.TemplateId)
    shipInfo = Logic.shipLogic:GetShipInfoById(self.heroInfo.TemplateId)
  end
  UIHelper.SetText(childPart.tx_name, shipInfo.ship_name)
  UIHelper.SetImage(childPart.im_girl, shipShowConfig.ship_icon6)
  UIHelper.SetImage(childPart.im_type, NewCardShipTypeImg[self.heroInfo.type])
  UIHelper.SetImage(childPart.bg_quality, QualityType[VerCardType.FleetBottom][self.heroInfo.quality])
  self:_SetAdvance()
  UIHelper.SetText(self.tabPart.textLv, math.tointeger(self.heroInfo.Lvl))
  self:_SetDrag()
  self.tabPart.im_lock.gameObject:SetActive(false)
  if childPart.im_mood then
    childPart.im_mood.gameObject:SetActive(false)
  end
  if childPart.im_kuang then
    childPart.im_kuang.gameObject:SetActive(false)
  end
  local objEvent = self.tabPart.objSelf.transform:Find("obj_event")
  objEvent.gameObject:SetActive(false)
end

function WishHeroItem:_SetAdvance()
  self.tabPart.obj_star:SetActive(true)
  local starTab = {
    self.tabPart.obj_star1,
    self.tabPart.obj_star2,
    self.tabPart.obj_star3,
    self.tabPart.obj_star4,
    self.tabPart.obj_star5,
    self.tabPart.obj_star6
  }
  local startNum = self.heroInfo.Advance
  for i, v in ipairs(starTab) do
    if i <= startNum then
      starTab[i]:SetActive(true)
    else
      starTab[i]:SetActive(false)
    end
  end
end

function WishHeroItem:_SetDrag()
  UGUIEventListener.AddOnDrag(self.tabPart.btnDrag, self._OnDragSelectCard, self, self.tabPart.objSelf.transform)
  UGUIEventListener.AddOnEndDrag(self.tabPart.btnDrag, self._OnEndDrag, self, self.heroInfo)
end

function WishHeroItem:_GetBgTransform()
  return self.m_tabWidgets.bottom_bg
end

function WishHeroItem:_OnEndDrag(go, eventData, heroInfo)
  SoundManager.Instance:PlayAudio("UI_Tween_FleetPage_0006")
  local inBan, localPos = self:_CheckIsInBan(eventData)
  if not inBan then
    local selectImp = function()
      local newIndex = Logic.wishLogic:WallPos2IndexLeft(localPos.x)
      local max = #Logic.wishLogic:GetWishShipConfig()
      newIndex = Mathf.Clamp(newIndex, 0, max + 1)
      if newIndex == 0 then
        local pageIndex = Logic.wishLogic:GetPageIndex()
        newIndex = newIndex + max * (pageIndex - 1)
        Data.wishData:AddSelectHero(heroInfo.IllustrateId, newIndex)
        self.page:_LeftMove()
      elseif max < newIndex then
        local pageIndex = Logic.wishLogic:GetPageIndex()
        newIndex = newIndex + max * (pageIndex - 1)
        Data.wishData:AddSelectHero(heroInfo.IllustrateId, newIndex)
        self.page:_RightMove()
      else
        local pageIndex = Logic.wishLogic:GetPageIndex()
        newIndex = newIndex + max * (pageIndex - 1)
        Data.wishData:AddSelectHero(heroInfo.IllustrateId, newIndex)
      end
      local name = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId).ship_name
      local coolTime = Logic.wishLogic:getChargeTime(heroInfo)
      coolTime = time.getTimeStringFontDynamic(coolTime)
      noticeManager:ShowTip(UIHelper.GetLocString(951012, name, coolTime))
      local dotinfo = {
        info = "ui_vow_pick",
        ship_name = name
      }
      RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
      self.page:OnReleaseCard(self.tabPart)
    end
    if Logic.wishLogic:CheckSelectTip(heroInfo) then
      local callBackConfirm = function(isOn)
        local playerPrefsKey = PlayerPrefsKey.WishMaxShip
        if playerPrefsKey then
          PlayerPrefs.SetBool(playerPrefsKey, isOn)
          PlayerPrefs.SetInt(playerPrefsKey .. "Time", os.time())
        end
        selectImp()
      end
      local callBackCancel = function()
        self.page:OnReleaseCard(self.tabPart)
      end
      local name = Logic.shipLogic:GetShipInfoById(heroInfo.TemplateId).ship_name
      local content = string.format(UIHelper.GetString(951060), name)
      local contentTg = UIHelper.GetString(931002)
      local playerPrefsKey = PlayerPrefsKey.WishMaxShip
      local tgIsShow = playerPrefsKey ~= nil
      local tgIsON = false
      if playerPrefsKey then
        tgIsON = PlayerPrefs.GetBool(playerPrefsKey, false)
      end
      self.page:_DestroyFloatCard()
      noticeManager:ShowSuperNotice(content, contentTg, tgIsShow, tgIsON, callBackConfirm, callBackCancel)
    else
      selectImp()
    end
  else
    self.page:OnReleaseCard(self.tabPart)
  end
end

function WishHeroItem:_OnUpSelectCard(go, param)
end

function WishHeroItem:_OnDragSelectCard(go, eventData, targetTran)
  local delta = eventData.delta
  self.page:OnDragCard(self.tabPart, self.heroInfo, eventData)
end

function WishHeroItem:_CheckIsInBan(eventData)
  local screenPos = eventData.position
  local camera = eventData.pressEventCamera
  local page = UIPageManager:GetPage("CommonHeroPage", 1, true)
  local areObj = page.transform:GetChild(0).gameObject
  local rectTrans = areObj:GetComponent(RectTransform.GetClassType())
  local worldPos = camera:ScreenToWorldPoint(Vector3.New(screenPos.x, screenPos.y, 0))
  local localPos = rectTrans:InverseTransformPoint(worldPos)
  local isInBanArea = rectTrans.rect:Contains(localPos)
  return isInBanArea, localPos
end

function WishHeroItem:PlaySelectTwn(upIndex)
  local parent = self.page:GetWidgets().float_card
  local obj = self.tabPart.gameObject
  local tempCard = UIHelper.CreateGameObject(obj, parent)
  tempCard.name = "tempCard"
  tempCard.transform.pivot = Vector2.New(0.5, 0.5)
  tempCard.transform.localPosition = Vector3.New(-400, -200, 0)
  self.m_posTwn = UIHelper.AddTween(tempCard, ETweenType.ETT_POSITION)
  self.m_scaleTwn = UIHelper.AddTween(tempCard, ETweenType.ETT_SCALE)
  local seq = UISequence.NewSequence(tempCard)
  local twnPos, twnScale = self:_getTweens(upIndex)
  seq:Append(twnPos)
  seq:Append(twnScale)
  seq:AppendCallback(function()
    self.page:OnReleaseCard(self.tabPart)
    GameObject.Destroy(tempCard)
  end)
  seq:Play(true)
end

function WishHeroItem:_getTweens(upIndex)
  local fromPos = Vector2.New(-400, -200)
  local toPos = Logic.wishLogic:GetShipPosByIndex(upIndex)
  local time = Logic.wishLogic:GetWishTweenTime()
  local twnPos = self:_setTwn(self.m_posTwn, fromPos, toPos, time)
  local twnScale = self:_setTwn(self.m_scaleTwn, Vector3.New(1, 1, 1), Vector3.New(1, 2, 1), time)
  return twnPos, twnScale
end

function WishHeroItem:_setTwn(twn, from, to, time)
  twn.from = from
  twn.to = to
  twn.duration = time
  return twn
end

return WishHeroItem
