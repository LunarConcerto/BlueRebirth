local Break_Page = class("UI.GirlInfo.Break_Page", LuaUIPage)
local HeroBasicAttr = require("logic.AttrLogic.HeroBasicAttr")
MAXADVANCE = 6
MAXATTRNUM = 7
local breakAnimDelay = 0.06

function Break_Page:DoInit()
  self.m_tabWidgets = nil
  self.m_templateId = nil
  self.m_tabSelectedId = {}
  self.m_tabisSelect = {}
  self.m_tabTips = {}
  self.m_tabParts = {}
  self.m_effStars = {}
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function Break_Page:DoOnOpen()
  self:_ShowBreak()
  local dotinfo = {
    info = "ui_ship_break"
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function Break_Page:_ShowBreak()
  self.m_tabSelectedId = {}
  local params = self:GetParam()
  local heroId = params.heroId
  self.m_tabHeroInfo = Data.heroData:GetHeroById(heroId)
  self.m_templateId = self.m_tabHeroInfo.TemplateId
  self:_UpdateSubParts()
  self:_updateStarEffect()
end

function Break_Page:_updateStarEffect()
  local timer = self:CreateTimer(function()
    self:_SetStarEffect()
  end, 0.1, 1, false)
  self:StartTimer(timer)
end

function Break_Page:UpdateGirlTog(heroId)
  self.m_tabWidgets.tween_dongHua:ResetToBeginning()
  self.m_tabWidgets.tween_dongHua:Play(true)
  noticeManager:CloseTip()
  self.m_tabSelectedId = {}
  self.m_tabHeroInfo = Data.heroData:GetHeroById(heroId)
  self.m_templateId = self.m_tabHeroInfo.TemplateId
  self:_UpdateSubParts()
  self:_updateStarEffect()
end

function Break_Page:RegisterAllEvent()
  UGUIEventListener.AddOnEndDrag(self.m_tabWidgets.sv_break, self._SetAdvanceTips, self)
  UGUIEventListener.AddOnDrag(self.m_tabWidgets.sv_break, self._OnDrag, self)
  self:RegisterEvent(LuaEvent.HeroBreakSelect, self._UpdateSelect, self)
  self:RegisterEvent(LuaEvent.HeroBreakSuccess, self._OnBreakSuccess, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween)
  self:RegisterEvent(LuaEvent.UpdataBuyResource, self._OnBuyResource)
  self:RegisterEvent(LuaEvent.GirlInfoUIReset, self._ResetUI)
end

function Break_Page:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToEnd()
end

function Break_Page:_OnBuyResource()
  self:_UpdateSubParts()
  self:_updateStarEffect()
end

function Break_Page:_GirlInfoTween(delta)
  local position = configManager.GetDataById("config_parameter", 95).arrValue
  if delta then
    self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D = Vector2.New(delta, position[3])
  else
    self.m_tabWidgets.tween_dongHua.from = self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D
    self.m_tabWidgets.tween_dongHua:ResetToBeginning()
    self.m_tabWidgets.tween_dongHua:Play(true)
  end
end

function Break_Page:_OnBreakSuccess(args)
  self.m_tabSelectedId = {}
  local heroId = args.HeroId
  if heroId == self.m_tabHeroInfo.HeroId then
    self.m_tabHeroInfo = Data.heroData:GetHeroById(heroId)
    self.m_templateId = self.m_tabHeroInfo.TemplateId
    self:_PlayBreakAnim(heroId)
  end
  self:_BreakSuccessDot()
end

function Break_Page:_UpdateSubParts()
  self.m_advance = self.m_tabHeroInfo.Advance
  self.m_tabConfig = configManager.GetDataById("config_ship_break", self.m_templateId)
  self.m_lv = self.m_tabHeroInfo.Lvl
  self:UnregisterAllById(LuaEvent.ShowStarEffect)
  self:UnregisterAllById(LuaEvent.ShowStarEffect2)
  self:UnregisterAllById(LuaEvent.ShowBreakEffect)
  local widgets = self:GetWidgets()
  UIHelper.CreateSubPart(widgets.obj_break, widgets.trans_break, MAXADVANCE, function(index, tabPart)
    self.m_tabParts[index] = tabPart
    local tid = self:_GetTid(self.m_templateId, self.m_advance, index)
    self:_ShowBreakEffect(tabPart, index, tid)
    self:_ShowAdvance(tabPart, index)
    self:_ShowAttr(tabPart, tid, index)
    self:_ShowBreakCondition(tabPart, index, tid)
  end)
  local num = widgets.sv_controller.PageNum
  local tag = self:_getIndexByAdvance(self.m_advance)
  UIHelper.CreateSubPart(widgets.obj_tips, widgets.trans_tips, num, function(index, tabPart)
    tabPart.obj_tips:SetActive(tag == index)
    self.m_tabTips[index] = tabPart.obj_tips
  end)
  local timer = self:CreateTimer(function()
    widgets.sv_controller.CurPage = tag
  end, 0.1, 1, false)
  self:StartTimer(timer)
end

function Break_Page:_PlayBreakAnim(heroId)
  eventManager:SendEvent(LuaEvent.ShowBreakEffect, self.m_advance)
  if heroId == self.m_tabHeroInfo.HeroId then
    eventManager:SendEvent(LuaEvent.GirlInfoUpdateUI)
    eventManager:SendEvent(LuaEvent.GirlInfoShowBreakEffect, {
      hid = heroId,
      advance = self.m_tabHeroInfo.Advance
    })
  end
  self:PerformDelay(0.65 + breakAnimDelay * 5, function()
    if heroId == self.m_tabHeroInfo.HeroId then
      self.m_advance = self.m_tabHeroInfo.Advance
      self:_UpdateSubParts(self.m_advance)
      eventManager:SendEvent(LuaEvent.ShowStarEffect)
      self:PerformDelay(0.4, function()
        eventManager:SendEvent(LuaEvent.ShowStarEffect2)
        self:_updateStarEffect()
      end)
      self:PerformDelay(1.6, function()
        self:_BreakSuccessTip()
      end)
    end
  end)
end

function Break_Page:_getIndexByAdvance(advance)
  return Mathf.Clamp(advance, 1, MAXADVANCE)
end

function Break_Page:_ShowBreakEffect(tabPart, advance, tid)
  local strEffect = self:_GetBreakEffect(tid + 1) or "\233\187\152\232\174\164\231\170\129\231\160\180\230\143\143\232\191\176"
  UIHelper.SetText(tabPart.tx_effect, strEffect)
  advance = Mathf.Clamp(advance, 1, 5)
  UIHelper.SetText(tabPart.tx_star, "\231\170\129\231\160\180" .. advance + 1 .. "\230\152\159\229\144\142")
end

function Break_Page:_GetBreakEffect(tid)
  return configManager.GetDataById("config_ship_break", tid).desc
end

function Break_Page:_ShowAdvance(tabPart, advance)
  advance = Mathf.Clamp(advance, 1, 6)
  local lfstars = self:_ShowStar(tabPart.obj_lfstarbg, tabPart.trans_lfstarbg, tabPart.obj_lfstarnow, tabPart.trans_lfstarnow, advance, true)
  local ristars = self:_ShowStar(tabPart.obj_ristarbg, tabPart.trans_ristarbg, tabPart.obj_ristarnow, tabPart.trans_ristarnow, advance + 1, false)
  self.m_effStars[advance] = {left = lfstars, right = ristars}
  tabPart.obj_afterMax:SetActive(advance >= MAXADVANCE)
end

function Break_Page:_ShowStar(obj_starbg, trans_starbg, obj_star, trans_star, advance, beforeBreak)
  local temp = {}
  if advance > MAXADVANCE then
    return temp
  end
  UIHelper.CreateSubPart(obj_star, trans_star, advance, function(index, tabPart)
    table.insert(temp, tabPart.obj_stareff)
    if index >= self.m_advance and index == advance then
      if beforeBreak then
        if index == self.m_advance then
          self:RegisterEvent(LuaEvent.ShowStarEffect, function()
            if index == self.m_advance then
              tabPart.rect_star.gameObject:SetActive(false)
            end
          end)
          self:RegisterEvent(LuaEvent.ShowStarEffect2, function()
            if index == self.m_advance then
              tabPart.rect_star.gameObject:SetActive(true)
              tabPart.break_effect:SetActive(true)
              self:PerformDelay(0.2, function()
                SoundManager.Instance:PlayAudio("Effect_Eff_tupo_star")
              end)
            end
          end)
        end
        tabPart.obj_stareff:SetActive(advance == self.m_advance)
      else
        if index > self.m_advance and index == advance then
          self:RegisterEvent(LuaEvent.ShowStarEffect, function()
            if index == self.m_advance + 1 then
              tabPart.rect_star.gameObject:SetActive(false)
            end
          end)
          self:RegisterEvent(LuaEvent.ShowStarEffect2, function()
            if index == self.m_advance + 1 then
              self:PerformDelay(0.2, function()
                tabPart.rect_star.gameObject:SetActive(true)
                tabPart.break_effect:SetActive(true)
              end)
            end
          end)
        end
        tabPart.obj_stareff:SetActive(self.m_advance == advance - 1)
      end
    end
  end)
  return temp
end

function Break_Page:_ShowAttr(tabPart, tid, breakIndex)
  local tabAttr, tabShipMain, tabBreakShipMain = self:_BreakAttrFilter(tid, breakIndex)
  UIHelper.CreateSubPart(tabPart.obj_attritem, tabPart.trans_attr, #tabAttr, function(index, tabPart)
    local tabConfig = configManager.GetDataById("config_attribute", tabAttr[index])
    UIHelper.SetImage(tabPart.Im_lefticon, tabConfig.attr_icon)
    UIHelper.SetImage(tabPart.Im_righticon, tabConfig.attr_icon)
    local nowNum = Mathf.ToInt(tabShipMain[tabAttr[index]])
    local nextNum = Mathf.ToInt(tabBreakShipMain[tabAttr[index]])
    local addNum = Mathf.ToInt(tabBreakShipMain[tabAttr[index]] - tabShipMain[tabAttr[index]])
    UIHelper.SetText(tabPart.Te_leftname, tabConfig.attr_name)
    UIHelper.SetText(tabPart.Te_leftnum, nowNum)
    UIHelper.SetText(tabPart.Te_rightname, tabConfig.attr_name)
    UIHelper.SetText(tabPart.Te_rightnum, nextNum)
    tabPart.Te_rightadd.gameObject:SetActive(0 < addNum)
    UIHelper.SetText(tabPart.Te_rightadd, "(+" .. addNum .. ")")
    self:RegisterEvent(LuaEvent.ShowBreakEffect, function(target, bIdx)
      if bIdx == breakIndex then
        self:PerformDelay((index - 1) * breakAnimDelay, function()
          tabPart.break_effect.gameObject:SetActive(true)
        end)
      end
    end)
  end)
end

function Break_Page:_GetTid(nowTid, nowAdvance, advance)
  advance = Mathf.Clamp(advance, 1, 5)
  if nowAdvance == advance then
    return nowTid
  end
  if nowAdvance > advance then
    return nowTid - (nowAdvance - advance)
  else
    return nowTid + (advance - nowAdvance)
  end
end

function Break_Page:_BreakAttrFilter(templateId, advance)
  local tabShipMain = HeroBasicAttr:new(self.m_lv, templateId).attrDic
  local tabBreakShipMain = HeroBasicAttr:new(self.m_lv, templateId + 1).attrDic
  local tabTemp = {}
  for i = 1, #BreakAttr do
    if tabShipMain[BreakAttr[i]] and tabShipMain[BreakAttr[i]] ~= 0 and tabBreakShipMain[BreakAttr[i]] > tabShipMain[BreakAttr[i]] then
      table.insert(tabTemp, BreakAttr[i])
    end
  end
  if advance == MAXADVANCE then
    tabShipMain = tabBreakShipMain
  end
  return tabTemp, tabShipMain, tabBreakShipMain
end

function Break_Page:_ShowBreakCondition(tabPart, advance, tid)
  advance = advance or self.m_advance
  if advance > MAXADVANCE then
    return
  end
  tabPart = tabPart or self.m_tabParts[advance]
  tid = tid or self.m_templateId
  local nowAdvance = self.m_advance
  local max = advance >= MAXADVANCE
  tabPart.obj_need:SetActive(not max)
  tabPart.obj_maxNeed:SetActive(max)
  if nowAdvance >= MAXADVANCE then
    UIHelper.SetText(tabPart.tx_maxDes, UIHelper.GetString(180028))
  elseif max then
    UIHelper.SetText(tabPart.tx_maxDes, UIHelper.GetString(180027))
  end
  if max then
    return
  end
  local minLevel = Logic.shipLogic:GetBreakMinLevel(tid)
  local nowLevel = Mathf.ToInt(self.m_tabHeroInfo.Lvl)
  if minLevel <= nowLevel then
    UIHelper.SetTextColor(tabPart.tx_level, nowLevel .. "/" .. minLevel, "1ac13a")
  else
    UIHelper.SetTextColor(tabPart.tx_level, nowLevel .. "/" .. minLevel, "ff0000")
  end
  local tabBreakItem = Logic.shipLogic:GetBreakItem(tid)
  local tabSelectInfo = {}
  if #self.m_tabSelectedId ~= 0 then
    for k, v in pairs(self.m_tabSelectedId) do
      tabSelectInfo[k] = Data.heroData:GetHeroById(v)
    end
  end
  UGUIEventListener.AddButtonOnClick(tabPart.obj_breakBlue, self._Break, self)
  UIHelper.CreateSubPart(tabPart.obj_ship, tabPart.trans_ship, tabBreakItem[2], function(index, tabPart)
    local si_id = Logic.shipLogic:GetShipInfoId(tabBreakItem[1][1])
    local needShipName = Logic.shipLogic:GetName(si_id)
    local quality = Logic.shipLogic:GetQualityByInfoId(si_id)
    local icon = Logic.shipLogic:GetTexIcon(si_id)
    UIHelper.SetTextColor(tabPart.tx_ship, needShipName, ShipQualityColor[quality])
    tabPart.im_bg.gameObject:SetActive(index <= #self.m_tabSelectedId)
    if index <= #self.m_tabSelectedId then
      UIHelper.SetTextColor(tabPart.tx_num, "1/1", "1ac13a")
      UIHelper.SetImage(tabPart.Im_icon, tostring(icon))
      UIHelper.SetImage(tabPart.im_bg, QualityIcon[quality])
      local lv = Mathf.ToInt(tabSelectInfo[index].Lvl)
      UIHelper.SetText(tabPart.Te_lv, "Lv." .. lv)
      self.m_tabisSelect[index] = true
    else
      UIHelper.SetTextColor(tabPart.tx_num, "0/1", "ff0000")
      self.m_tabisSelect[index] = false
    end
    tabPart.Bu_bg.gameObject:SetActive(advance >= nowAdvance)
    if advance == nowAdvance then
      UGUIEventListener.AddButtonOnClick(tabPart.Bu_bg, self._SelectLogic, self, index)
    else
      UGUIEventListener.AddButtonOnClick(tabPart.Bu_bg, self._SelectTips, self, advance)
    end
  end)
  local needCost = Logic.shipLogic:GetBreakCost(tid)[3]
  local nowCost = Data.userData:GetUserData().Gold
  if needCost <= nowCost then
    UIHelper.SetTextColor(tabPart.tx_expend, needCost, "1ac13a")
  else
    UIHelper.SetTextColor(tabPart.tx_expend, needCost, "ff0000")
  end
  if advance == nowAdvance then
    local canBreak, errMsg = Logic.shipLogic:CheckBreakConditionFit(self.m_tabHeroInfo.HeroId, self.m_tabSelectedId)
    tabPart.obj_breakBlue:SetActive(canBreak)
    tabPart.obj_break:SetActive(not canBreak)
    tabPart.tx_unbreak.gameObject:SetActive(false)
    if not canBreak then
      UGUIEventListener.ClearButtonEventListener(tabPart.obj_break)
      UGUIEventListener.AddButtonOnClick(tabPart.obj_break, function(...)
        if errMsg == UIHelper.GetString(180004) then
          UIHelper.OpenPage("BuyResourcePage", BuyResource.Gold)
        else
          noticeManager:ShowTip(errMsg)
        end
      end)
    end
  elseif advance < nowAdvance then
    tabPart.obj_breakBlue:SetActive(false)
    tabPart.obj_break:SetActive(false)
    tabPart.tx_unbreak.gameObject:SetActive(true)
    UIHelper.SetTextColor(tabPart.tx_unbreak, "\229\183\178\231\170\129\231\160\180", "1ac13a")
  else
    tabPart.obj_breakBlue:SetActive(false)
    tabPart.obj_break:SetActive(false)
    tabPart.tx_unbreak.gameObject:SetActive(true)
    UIHelper.SetTextColor(tabPart.tx_unbreak, "\233\156\128\232\166\129\229\174\140\230\136\144\228\184\138\228\184\128\231\186\167\231\170\129\231\160\180", "ff0000")
  end
end

function Break_Page:_SelectTips(go, advance)
  noticeManager:OpenTipPage(self, "\233\156\128\232\166\129\229\174\140\230\136\144\228\184\138\228\184\128\231\186\167\231\170\129\231\160\180")
end

function Break_Page:_SetAdvanceTips()
  local intervalIndex = self.m_tabWidgets.sv_controller.CurPage
  for k, v in pairs(self.m_tabTips) do
    v:SetActive(k == intervalIndex)
  end
  for index, items in ipairs(self.m_effStars) do
    for _, item in pairs(items) do
      for _, obj in ipairs(item) do
        obj:SetActive(index == intervalIndex)
      end
    end
  end
end

function Break_Page:_OnDrag()
  self:_SetStarEffect()
end

function Break_Page:_SetStarEffect()
  local widgets = self:GetWidgets()
  local up = widgets.trans_bg.anchoredPosition.x + widgets.trans_bg.rect.width * 0.5
  local down = widgets.trans_bg.anchoredPosition.x - widgets.trans_bg.rect.width * 0.5
  for index, items in ipairs(self.m_effStars) do
    for key, item in pairs(items) do
      for i, obj in ipairs(item) do
        local pos = widgets.trans_bgbase:InverseTransformPoint(obj.transform.position)
        local show = down < pos.x and up > pos.x
        obj:SetActive(show)
      end
    end
  end
end

function Break_Page:_UpdateSelect(selectId)
  self.m_tabSelectedId = selectId
  self:_ShowBreakCondition()
end

function Break_Page:_BreakSuccessTip()
  noticeManager:OpenTipPage(self, UIHelper.GetString(180002))
end

function Break_Page:_BreakSuccessDot()
  local si_id = Logic.shipLogic:GetShipInfoId(self.m_templateId)
  local name = Logic.shipLogic:GetName(si_id)
  local dotinfo = {
    info = "ui_break_success",
    ship_name = name,
    star_level = Data.heroData:GetHeroById(self:GetParam().heroId).Advance
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function Break_Page:_SelectLogic(index)
  index = tonumber(index.name)
  if self.m_tabisSelect[index] == false then
    local tabParams = {}
    tabParams.m_selectedIdList = self.m_tabSelectedId
    local advance = self.m_tabHeroInfo.Advance
    if advance >= MAXADVANCE then
      return
    end
    local heroId = self.m_tabHeroInfo.HeroId
    local heroTId = self.m_tabHeroInfo.TemplateId
    local tabHaveHero = Data.heroData:GetHeroData()
    local tabRemainHero = {}
    local func = self.GetFilterSelectFunc(heroId, heroTId)
    for k, v in pairs(tabHaveHero) do
      if func(v) then
        table.insert(tabRemainHero, v)
      end
    end
    local breakConfig = configManager.GetDataById("config_ship_break", heroTId)
    local breakItem = breakConfig.break_item
    local consumeHeroNum = breakItem[2]
    if #tabRemainHero == 0 then
      noticeManager:OpenTipPage(self, UIHelper.GetString(180003))
      globalNoitceManager:ShowItemInfoPage(GoodsType.SHIP, heroTId)
      return
    elseif consumeHeroNum > #tabRemainHero and #self.m_tabSelectedId == #tabRemainHero then
      noticeManager:OpenTipPage(self, UIHelper.GetString(180026))
      globalNoitceManager:ShowItemInfoPage(GoodsType.SHIP, heroTId)
      return
    end
    table.sort(tabRemainHero, self.GetSortSelectFunc(heroTId))
    tabParams.m_selectItemList = tabRemainHero
    tabParams.m_selectMax = self.m_tabConfig.break_item[2]
    UIHelper.OpenPage("CommonSelectPage", {
      CommonHeroItem.Break,
      tabRemainHero,
      tabParams
    })
  else
    self.m_tabisSelect[index] = false
    if index <= #self.m_tabSelectedId then
      table.remove(self.m_tabSelectedId, index)
      self:_ShowBreakCondition()
    end
  end
end

function Break_Page.GetSortSelectFunc(sm_id)
  return function(a, b)
    local logic = Logic.shipLogic
    local qA = logic:GetQuality(logic:GetShipInfoId(a.TemplateId))
    local qB = logic:GetQuality(logic:GetShipInfoId(b.TemplateId))
    local isSameA = logic:CheckSameShipMain(sm_id, a.TemplateId)
    local isSameB = logic:CheckSameShipMain(sm_id, b.TemplateId)
    if isSameA ~= isSameB then
      return isSameA
    elseif qA ~= qB then
      return qA < qB
    elseif a.Advance ~= b.Advance then
      return a.Advance > b.Advance
    elseif a.Lvl ~= b.Lvl then
      return a.Lvl < b.Lvl
    end
  end
end

function Break_Page.GetFilterSelectFunc(heroId, heroTId)
  return function(heroInfo, k)
    local bNotSelf = heroInfo.HeroId ~= heroId
    local bConsumeFit = Logic.shipLogic:CheckAdvanceCosumeHeroFit(heroTId, heroInfo.TemplateId)
    return bNotSelf and bConsumeFit
  end
end

function Break_Page:_Break()
  local canBreak, errMsg = Logic.shipLogic:CheckBreakConditionFit(self.m_tabHeroInfo.HeroId, self.m_tabSelectedId)
  local isInOutpost = self:CheckHasOutPostHero(self.m_tabSelectedId)
  if canBreak then
    Service.heroService:SendHeroBreak(self.m_tabHeroInfo.HeroId, self.m_tabSelectedId)
  else
    noticeManager:OpenTipPage(self, errMsg)
  end
end

function Break_Page:CheckHasOutPostHero(m_tabSelectedId)
  for i = 1, #m_tabSelectedId do
    local isInOutpost, _ = Logic.mubarOutpostLogic:CheckHeroIsInOutpostId(m_tabSelectedId[i])
    if isInOutpost then
      return true
    end
  end
  return false
end

function Break_Page:DoOnHide()
  self:_HideStarEff()
end

function Break_Page:_HideStarEff()
  for index, items in ipairs(self.m_effStars) do
    for key, item in pairs(items) do
      for i, obj in ipairs(item) do
        obj:SetActive(false)
      end
    end
  end
end

function Break_Page:DoOnClose()
  self.m_tabWidgets = nil
end

return Break_Page
