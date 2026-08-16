local WishSelectHeroItem = class("UI.Illustrate.WishSelectHeroItem")
local QualityType = {
  VerCardQualityImg,
  FleetCardQualityImg,
  FleetSmallCardQualityImg,
  FleetBottomCardQulity
}
local QualityDingMap = {
  [HeroRarityType.N] = "uipic_ui_vow_im_tuding_bai",
  [HeroRarityType.R] = "uipic_ui_vow_im_tuding_lan",
  [HeroRarityType.SR] = "uipic_ui_vow_im_tuding_zi",
  [HeroRarityType.SSR] = "uipic_ui_vow_im_tuding_jin",
  [HeroRarityType.UR] = "uipic_ui_vow_im_tuding_cai"
}
local QualityTexMap = {
  [HeroRarityType.N] = "uipic_ui_vow_bg_kabei_bai",
  [HeroRarityType.R] = "uipic_ui_vow_bg_kabei_lan",
  [HeroRarityType.SR] = "uipic_ui_vow_bg_kabei_zi",
  [HeroRarityType.SSR] = "uipic_ui_vow_bg_kabei_jin",
  [HeroRarityType.UR] = "uipic_ui_vow_bg_kabei_cai"
}
local scale = 0.5

function WishSelectHeroItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.heroInfo = {}
  self.interactable = true
  self.m_obj = nil
  self.index = 0
  self.pos = nil
  self.m_drag = false
end

function WishSelectHeroItem:Init(obj, data, tabPart, interactable, go, index)
  self.page = obj
  self.tabPart = tabPart
  self.heroInfo = data
  self.interactable = interactable
  self.m_obj = go
  self.index = index
  self.tweenScale = UIHelper.GetTween(tabPart.gameObject, ETweenType.ETT_SCALE)
  self.scaledDown = false
  self:_SetHeroInfo()
end

function WishSelectHeroItem:_PlayScaleUp()
  if self.scaledDown then
    self.tweenScale:ResetToInit()
    self.tweenScale.from = Vector3.New(scale, scale, scale)
    self.tweenScale.to = Vector3.one
    self.tweenScale.duration = 0.3
    self.tweenScale:Play(true)
    self.scaledDown = false
  end
end

function WishSelectHeroItem:_PlayScaleDown()
  if not self.scaledDown then
    self.tweenScale:ResetToInit()
    self.tweenScale.from = Vector3.one
    self.tweenScale.to = Vector3.New(scale, scale, scale)
    self.tweenScale.duration = 0.3
    self.tweenScale:Play(true)
    self.scaledDown = true
  end
end

function WishSelectHeroItem:_SetHeroInfo()
  local childPart = self.tabPart.cardPart:GetLuaTableParts()
  local shipShowConfig, shipInfo
  if self.heroInfo.HeroId > 0 then
    shipShowConfig = Logic.shipLogic:GetShipShowByHeroId(self.heroInfo.HeroId)
    shipInfo = Logic.shipLogic:GetShipInfoByHeroId(self.heroInfo.HeroId)
  else
    shipInfo = Logic.shipLogic:GetShipInfoById(self.heroInfo.TemplateId)
    ssId = Logic.illustrateLogic:GetIllustrateShowId(shipInfo.si_id)
    shipShowConfig = Logic.shipLogic:GetShipShowConfig(ssId)
  end
  UIHelper.SetText(childPart.tx_name, shipInfo.ship_name)
  UIHelper.SetImage(childPart.im_girl, shipShowConfig.ship_icon1)
  UIHelper.SetImage(childPart.im_type, NewCardShipTypeImg[self.heroInfo.type])
  UIHelper.SetImage(childPart.bg_quality, QualityTexMap[shipInfo.quality])
  UIHelper.SetImage(self.tabPart.im_ding, QualityDingMap[shipInfo.quality])
  self:_SetAdvance()
  UIHelper.SetText(self.tabPart.tx_lv, math.tointeger(self.heroInfo.Lvl))
  if self.interactable then
    self:_SetDrag()
  end
end

function WishSelectHeroItem:_SetAdvance()
  UIHelper.CreateSubPart(self.tabPart.obj_stars, self.tabPart.trans_stars, self.heroInfo.Advance, function(nIndex, part)
  end)
end

function WishSelectHeroItem:_SetDrag()
  UGUIEventListener.AddOnDrag(self.tabPart.card, self._OnDragSelectCard, self, self.tabPart.card.transform)
  UGUIEventListener.AddButtonOnPointDown(self.tabPart.card, self._OnDownSelectCard, self, self.heroInfo)
  UGUIEventListener.AddButtonOnPointUp(self.tabPart.card, self._OnUpSelectCard, self, self.heroInfo)
end

function WishSelectHeroItem:_OnDownSelectCard(go, param)
  local expend = Logic.wishLogic:GetExpend()
  if expend then
    local banPage = Logic.wishLogic:GetBanPage()
    go.transform:SetParent(banPage.gameObject.transform)
  else
    go.transform:SetParent(self.page:GetWidgets().trans_root)
  end
  self.pos = go.transform.localPosition
  self.tabPart.im_ding.gameObject:SetActive(false)
  SoundManager.Instance:PlayAudio("UI_Button_FleetPage_0002")
end

function WishSelectHeroItem:_OnUpSelectCard(go, param)
  if self:_CheckIsInBan(go) then
    Data.wishData:AddBanHero(param.IllustrateId)
    local name = Logic.shipLogic:GetShipInfoById(param.TemplateId).ship_name
    local coolTime = Logic.wishLogic:getChargeTime(self.heroInfo)
    coolTime = time.getTimeStringFontDynamic(coolTime)
    noticeManager:ShowTip(UIHelper.GetLocString(951011, name, coolTime))
    GameObject.Destroy(go)
    local dotinfo = {info = "ui_vow_ban", ship_name = name}
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  else
    go.transform:SetParent(self.page:GetWidgets().trans_hero)
    if self.m_drag then
      local posConfig = Logic.wishLogic:GetWishShipConfig()
      local max = #posConfig
      local newIndex = Logic.wishLogic:WallPos2Index(go.transform.localPosition.x, posConfig[self.index].vow_pos_x)
      newIndex = Mathf.Clamp(newIndex, 0, max + 1)
      if newIndex == 0 then
        local pageIndex = Logic.wishLogic:GetPageIndex()
        newIndex = newIndex + max * (pageIndex - 1)
        Data.wishData:InsertSelectHero(param.IllustrateId, newIndex)
        self.page:_LeftMove()
      elseif max < newIndex then
        local pageIndex = Logic.wishLogic:GetPageIndex()
        newIndex = newIndex + max * (pageIndex - 1)
        Data.wishData:InsertSelectHero(param.IllustrateId, newIndex)
        self.page:_RightMove()
      else
        local pageIndex = Logic.wishLogic:GetPageIndex()
        newIndex = newIndex + max * (pageIndex - 1)
        Data.wishData:InsertSelectHero(param.IllustrateId, newIndex)
      end
    end
  end
  self.m_drag = false
  self.tabPart.im_ding.gameObject:SetActive(true)
  self.page:PlayScaleDown()
  self.page:_UpdataWish()
  SoundManager.Instance:PlayAudio("UI_Tween_FleetPage_0006")
end

function WishSelectHeroItem:_OnDragSelectCard(go, eventData, targetTran)
  self.m_drag = true
  local delta = eventData.delta
  if not IsNil(targetTran) then
    local dragPos = eventData.position
    local camera = eventData.pressEventCamera
    local finalPos = camera:ScreenToWorldPoint(Vector3.New(dragPos.x, dragPos.y, 0))
    targetTran.transform.position = finalPos
    self.pos = targetTran.localPosition
    if self:_CheckIsInBan(go) then
      self.page:PlayScaleUp()
      self:_PlayScaleDown()
    else
      self.page:PlayScaleDown()
      self:_PlayScaleUp()
    end
  end
end

function WishSelectHeroItem:_CheckIsInBan(go)
  local expend = Logic.wishLogic:GetExpend()
  if self.pos == nil then
    return false
  end
  if expend then
    local page = UIPageManager:GetPage("CommonHeroPage", 1, true)
    local areObj = page.transform:GetChild(0).gameObject
    local size = areObj:GetComponent(RectTransform.GetClassType()).rect.size
    local position = areObj.transform.localPosition
    return self.pos.y < position.y + size.y / 2
  else
    local size = self.m_obj:GetComponent(RectTransform.GetClassType()).rect.size
    local position = self.m_obj.transform.localPosition
    return self.pos.x > position.x - size.x / 2 and self.pos.y < position.y + size.y / 2
  end
end

return WishSelectHeroItem
