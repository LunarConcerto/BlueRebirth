local TreatyResultPage = class("UI.DailyCopy.Treaty.TreatyResultPage", LuaUIPage)

function TreatyResultPage:DoInit()
  self.copyId = 0
  self.fleetInfo = {}
end

function TreatyResultPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnSkip, function()
    UIHelper.ClosePage(self:GetName())
    local callback = self.param.callback
    callback()
  end)
end

function TreatyResultPage:DoOnOpen()
  local param = self.param
  self.copyId = param.copyId
  self.fleetInfo = Logic.settlementLogic:GetParam().myShipList
  local copyDisplay = Logic.copyLogic:GetCopyDConfigById(self.copyId)
  self.tab_Widgets.tx_copyName.text = copyDisplay.name
  self:_ShowStarChange()
  self:_ShowFleet()
  self:_ShowSelectBuff()
end

function TreatyResultPage:_ShowStarChange()
  local bBattleStar, bBattleTotalStar = Logic.dailyCopyLogic:GetBBattleExStar()
  local nowTotalStar = 0
  local nowStar = 0
  local dailyCopyData = Data.dailyCopyData:GetDailyCopyData()
  local chapter = Logic.copyLogic:GetCopyChapter(self.copyId)
  for k, v in pairs(dailyCopyData) do
    nowTotalStar = nowTotalStar + v.ExStar
    if k == chapter.id then
      nowStar = v.ExStar
    end
  end
  self.tab_Widgets.tx_beforStar.text = bBattleStar
  self.tab_Widgets.tx_nowStar.text = nowStar
  self.tab_Widgets.tx_totalBStar.text = bBattleTotalStar
  self.tab_Widgets.tx_totalNStar.text = nowTotalStar
end

function TreatyResultPage:_ShowFleet()
  self.tab_Widgets.tx_battlePower.text = Logic.copyLogic:GetBBattleAttack()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_fleet, #self.fleetInfo, function(index, tabParts)
    local heroInfo = Data.heroData:GetHeroById(self.fleetInfo[index].heroId)
    local shipInfo = Logic.shipLogic:GetShipShowByFashionId(heroInfo.Fashioning)
    if index == 1 then
      UIHelper.SetImage(tabParts.img_typeBg, "uipic_ui_newfleetpage_bg_qijiandiban")
    end
    UIHelper.SetImage(tabParts.img_type, NewCardShipTypeImg[heroInfo.ship_type])
    UIHelper.SetImage(tabParts.im_icon, tostring(shipInfo.ship_icon5))
    UIHelper.SetStar(tabParts.Star, tabParts.StarPrt, heroInfo.AdvLv)
    UIHelper.SetText(tabParts.tx_lv, "Lv." .. math.tointeger(heroInfo.Lvl))
    UIHelper.SetImage(tabParts.im_quality, QualityIcon[heroInfo.quality])
    tabParts.obj_mvp:SetActive(self.fleetInfo[index].mvp)
  end)
end

function TreatyResultPage:_ShowSelectBuff()
  local selectBuff = Logic.dailyCopyLogic:GetSelectBuff().selectBuff
  if #selectBuff == 0 then
    return
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_buff, self.tab_Widgets.trans_buff, #selectBuff, function(nIndex, tabPart)
    local buffInfo = selectBuff[nIndex]
    UIHelper.SetImage(tabPart.img_buff, buffInfo.buff_icon)
  end)
end

return TreatyResultPage
