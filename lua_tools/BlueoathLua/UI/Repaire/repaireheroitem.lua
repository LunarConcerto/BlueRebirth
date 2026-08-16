local RepaireHeroItem = class("UI.Repaire.RepaireHeroItem")

function RepaireHeroItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.heroInfo = {}
  self.index = nil
end

function RepaireHeroItem:Init(obj, tabPart, data, index)
  self.page = obj
  self.tabPart = tabPart
  self.heroInfo = data
  self.index = index
  self:_SetHeroInfo()
end

function RepaireHeroItem:_CloseSelect()
  self.tabPart.objGolden:SetActive(false)
  self.tabPart.objMask:SetActive(false)
end

function RepaireHeroItem:_SetHeroInfo()
  local heroAttr = Logic.attrLogic:GetHeroFianlAttrById(self.heroInfo.HeroId)
  local ship = Logic.shipLogic:GetShipInfoById(self.heroInfo.TemplateId)
  local curHp = Logic.shipLogic:GetHeroHp(self.heroInfo.HeroId)
  local hpStatus = Logic.shipLogic:GetHeroHpStatus(curHp, heroAttr[AttrType.HP])
  UIHelper.SetImage(self.tabPart.imgHp, NewHpStatusImg[hpStatus + 1])
  ShipCardItem:LoadVerticalCard(self.heroInfo.HeroId, self.tabPart.childpart, VerCardType.FleetBottom)
  self.tabPart.slider.value = curHp / heroAttr[AttrType.HP]
  self.tabPart.textLv.text = math.tointeger(self.heroInfo.Lvl)
  UGUIEventListener.AddOnDrag(self.tabPart.btnDrag, self._OnDragSelectCard, self)
  UGUIEventListener.AddOnEndDrag(self.tabPart.btnDrag, self._OnEndDrag, self)
end

function RepaireHeroItem:_OnDragSelectCard(go, eventData)
  self.page:OnDragHeroCard(self.tabPart, self.heroInfo, self.index, true, eventData)
end

function RepaireHeroItem:_OnEndDrag(go, eventData)
  if self.page.pop ~= nil then
    self:_CloseSelect()
    self.page:OnEndDrag(eventData, self.tabPart.fixDrag)
  end
end

return RepaireHeroItem
