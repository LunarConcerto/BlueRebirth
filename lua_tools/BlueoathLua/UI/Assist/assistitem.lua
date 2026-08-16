local AssistItem = class("UI.Assist.AssistItem")
local CommonItem = require("ui.page.CommonItem")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local ShipSlotNum = 6

function AssistItem:initialize()
  self.m_index = 0
  self.m_page = nil
  self.m_widgets = {}
  self.m_data = {}
  self.m_timer = nil
  self.m_isOn = false
end

function AssistItem:Init(obj, widgets, data, index)
  self.m_index = index
  self.m_page = obj
  self:SetData(data)
  self:SetWidgets(widgets)
  self:ShowItem()
end

function AssistItem:SetIsOn(isOn)
  self.m_isOn = isOn
end

function AssistItem:SetData(data)
  self.m_data = data
end

function AssistItem:SetWidgets(widgets)
  self.m_widgets = widgets
  self:_SetTweenCB()
end

function AssistItem:_SetTweenCB()
  local widgets = self.m_widgets
  widgets.tweensd_detail:AddOnFinished(function()
    self.m_page:_ForceUpdateAssistLayout()
  end)
end

function AssistItem:ShowItem()
  self:_ShowBase()
  self:_ShowDetail(self.m_isOn)
end

function AssistItem:_ShowBase()
  self:_ShowCommandInfo()
  self:_ShowRewardInfo()
  self:_ShowFinishEffect()
end

function AssistItem:_TickAssist(tx_time, data)
  local duration = Logic.assistNewLogic:GetAssistRemainTime(data.SupportId, data.StartTime)
  UIHelper.SetText(tx_time, UIHelper.GetCountDownStr(duration))
  if duration <= 0 then
    self:ShowItem()
  end
end

function AssistItem:_OnClickAssistItem(go, param)
  Logic.assistNewLogic:SetCurIndex(self.m_index)
  local state = Logic.assistNewLogic:GetAssistState(param.SupportId, param.StartTime)
  if state == AssistFleetState.FINISH then
    local ok, msg = Logic.assistNewLogic:CheckNormalFinish(param)
    if not ok then
      logError(msg)
      return
    end
    Logic.assistNewLogic:SetLastFinish(param)
    Service.assistNewService:SendAssistFinish(param.Id, AssistCompleteType.NORMAL)
  elseif param.SupportId > 0 then
    self.m_page:_Refresh()
    self.m_page:ShowDetail()
  else
    self.m_page:TryCloseDetail()
    self:_ShowCommands(go, param)
  end
end

function AssistItem:_ShowDetail(isOn)
  local widgets = self.m_widgets
  local data = self.m_data
  self:SetIsOn(data.SupportId > 0 and isOn)
  widgets.tweensd_detail:Play(self.m_isOn)
  widgets.obj_detailwrap:SetActive(self.m_isOn)
  self:_ShowDetailEffect(self.m_isOn)
  if self.m_isOn then
    widgets.obj_detail:SetActive(self.m_isOn)
    self:_ShowAssistLimit()
    self:_ShowAssistRmd()
    self:_ShowHero()
    self:_ShowButton()
  end
  self:_ShowDetailSwitch()
end

function AssistItem:_ShowDetailSwitch()
  self:_ShowDetailBtn()
  self:_ShowNoDetailBtn(self.m_isOn)
end

function AssistItem:_ShowDetailBtn()
  local widgets = self.m_widgets
  local data = self.m_data
  local state = Logic.assistNewLogic:GetAssistState(data.SupportId, data.StartTime)
  local show = data.SupportId > 0 and state ~= AssistFleetState.FINISH and not self.m_isOn
  widgets.btn_zhankai.gameObject:SetActive(show)
end

function AssistItem:_ShowNoDetailBtn(isOn)
  local widgets = self.m_widgets
  widgets.btn_shouqi.gameObject:SetActive(isOn)
end

function AssistItem:_ShowFinishEffect()
  local widgets = self.m_widgets
  local data = self.m_data
  local state = Logic.assistNewLogic:GetAssistState(data.SupportId, data.StartTime)
  widgets.obj_eff2d_complete:SetActive(state == AssistFleetState.FINISH)
end

function AssistItem:_ShowDetailEffect(enable)
  local widgets = self.m_widgets
  widgets.obj_eff2d_select2:SetActive(enable)
end

function AssistItem:CheckShowDetail()
  local data = self.m_data
  if data.SupportId > 0 then
    self:SetIsOn(not self.m_isOn)
    return self.m_isOn
  end
  return false
end

function AssistItem:_CancelAssist(go, param)
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      self:_ClickCancelAssist(bool)
    end
  }
  noticeManager:ShowMsgBox(UIHelper.GetString(971005), tabParams)
  self.m_paramCache = param
end

function AssistItem:_ClickCancelAssist(bool)
  if bool then
    local ok, msg = Logic.assistNewLogic:CheckCancelSupport(self.m_paramCache)
    if not ok then
      logError(msg)
      return
    end
    Service.assistNewService:SendAssistCancel(self.m_paramCache.Id, AssistCompleteType.CANCEL)
    local dotinfo = {
      info = "ui_supfleet_end",
      type = AssistCompleteType.CANCEL
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  end
end

function AssistItem:_FastFinish(go, param)
  Logic.assistNewLogic:SetCurIndex(self.m_index)
  local ok, msg = Logic.assistNewLogic:CheckFastFinishRPC(param)
  if not ok then
    logError(msg)
    return
  end
  UIHelper.OpenPage("AssistFastTip", param)
end

function AssistItem:_ClearHero(go, param)
  Logic.assistNewLogic:SetAssistHeros(self.m_index, {})
  self:ShowItem()
end

function AssistItem:_RmdHero(go, param)
  local data = self.m_data
  if data.SupportId == 0 or 0 < data.StartTime then
    logError("\230\156\170\232\174\190\231\189\174\230\148\175\230\143\180\228\187\164\230\136\150\232\128\133\230\152\175\229\183\178\231\187\143\229\188\128\229\167\139\231\154\132\230\148\175\230\143\180,\230\151\160\230\179\149\230\142\168\232\141\144")
    return
  end
  local _, heros = Logic.assistNewLogic:GetRecommandHero(data.SupportId, data.HeroList)
  if #heros <= 0 then
    noticeManager:ShowTip(UIHelper.GetString(971039))
  end
  self.m_data.HeroList = self:_mergeRmdHero(heros)
  self:ShowItem()
end

function AssistItem:_mergeRmdHero(heros)
  local data = self.m_data
  local up = Logic.assistNewLogic:SupportShipUp(data.SupportId)
  local herolist = clone(data.HeroList)
  local temp = self:_getShipFleetIds(herolist)
  for _, id in ipairs(heros) do
    local sf_id = self:_getShipFleetId(id)
    if not table.containV(temp, sf_id) and up > #herolist then
      table.insert(herolist, id)
    end
  end
  return herolist
end

function AssistItem:_getShipFleetIds(heros)
  local res = {}
  for i, v in pairs(heros) do
    local sf_id = self:_getShipFleetId(v)
    table.insert(res, sf_id)
  end
  return res
end

function AssistItem:_getShipFleetId(heroId)
  local tid = Data.heroData:GetHeroById(heroId).TemplateId
  local si_id = Logic.shipLogic:GetShipInfoIdByTid(tid)
  local sf_id = Logic.shipLogic:GetShipFleetId(si_id)
  return sf_id
end

function AssistItem:_StartAssist(go, param)
  local ok, msg = Logic.assistNewLogic:CheckStartSupport(param)
  if not ok then
    noticeManager:ShowTip(msg)
    return
  end
  Service.assistNewService:SendAssistStart(param.SupportId, param.HeroList)
end

function AssistItem:CheckTimer()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
  end
  self.m_timer = nil
end

function AssistItem:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function AssistItem:_ShowCommandInfo()
  local widgets = self.m_widgets
  local data = self.m_data
  local have = data.SupportId > 0
  widgets.obj_nohave:SetActive(not have)
  widgets.obj_have:SetActive(have)
  self:CheckTimer()
  if have then
    local command = Logic.assistNewLogic:FormatSupportById(data.SupportId)
    local item = CommonItem:new()
    item:Init(index, command, widgets)
    local duration = Logic.assistNewLogic:GetAssistRemainTime(data.SupportId, data.StartTime)
    UIHelper.SetText(widgets.tx_time, UIHelper.GetCountDownStr(duration))
    UGUIEventListener.ClearButtonEventListener(widgets.img_frame.gameObject)
    local state = Logic.assistNewLogic:GetAssistState(data.SupportId, data.StartTime)
    widgets.obj_stateDoing:SetActive(state == AssistFleetState.DOING)
    if state == AssistFleetState.DOING then
      self.m_timer = Timer.New(function()
        self:_TickAssist(widgets.tx_time, data)
      end, 1, -1, false)
      self.m_timer:Start()
    elseif state == AssistFleetState.TODO then
      UGUIEventListener.AddButtonOnClick(widgets.img_frame, self._ShowCommands, self, data)
    else
      self:_ShowDetail(false)
      UIHelper.SetText(widgets.tx_time, "\229\183\178\229\174\140\230\136\144")
    end
    if state ~= AssistFleetState.FINISH then
      UGUIEventListener.AddButtonOnClick(widgets.btn_shouqi, function()
        self.m_page:ShowDetail(nil, false)
      end)
    end
  else
    UGUIEventListener.AddButtonOnClick(widgets.im_add, self._ShowCommands, self, data)
  end
  UGUIEventListener.AddButtonOnClick(widgets.obj_assist, self._OnClickAssistItem, self, data)
end

function AssistItem:_ShowCommands(go, param)
  Logic.assistNewLogic:SetCurIndex(self.m_index)
  self.m_page:ShowCommands(go, param)
end

function AssistItem:_ShowRewardInfo()
  local data = self.m_data
  local have = data.SupportId > 0
  if have then
    self:_ShowBaseReward(data.SupportId, data.HeroList)
    self:_ShowExtraReward(data.SupportId, data.HeroList)
  end
end

function AssistItem:_ShowBaseReward(supportId, heroList)
  local widgets = self.m_widgets
  local base = Logic.assistNewLogic:GetBaseReward(supportId)
  local add = Logic.assistNewLogic:GetBaseHeroAdd(supportId, heroList)
  self:_ShowReward(base, widgets.obj_basereward, widgets.trans_basereward, add)
end

function AssistItem:_ShowExtraReward(supportId, heroList)
  local widgets = self.m_widgets
  local extra = Logic.assistNewLogic:GetExtraReward(supportId)
  local add = Logic.assistNewLogic:GetExtraRewardAdd(supportId, heroList)
  self:_ShowReward(extra, widgets.obj_extrareward, widgets.trans_extrareward, add)
end

function AssistItem:_ShowReward(info, go, trans, add)
  UIHelper.CreateSubPart(go, trans, #info, function(index, tabParts)
    local item = CommonItem:new()
    item:Init(index, info[index], tabParts)
    local check = tabParts.tx_add and add and 0 < add
    tabParts.tx_add.gameObject:SetActive(check)
    if check then
      UIHelper.SetText(tabParts.tx_add, "+" .. add * 100 .. "%")
    end
    UGUIEventListener.AddButtonOnClick(tabParts.item, self._ShowItemInfo, self, info[index])
  end)
end

function AssistItem:_ShowAssistLimit()
  local widgets = self.m_widgets
  local data = self.m_data
  self.m_check = 0
  local info = Logic.assistNewLogic:CheckAssistTeamLimit(data.HeroList, data.SupportId)
  widgets.trans_teamlimit.gameObject:SetActive(0 < #info)
  UIHelper.CreateSubPart(widgets.obj_teamlimit, widgets.trans_teamlimit, #info, function(index, tabPart)
    local v = info[index]
    UIHelper.SetText(tabPart.tx_item, v.des)
    if not v.check then
      self.m_check = index
    end
  end)
end

function AssistItem:_ShowAssistRmd()
  local widgets = self.m_widgets
  local data = self.m_data
  local info = Logic.assistNewLogic:CheckAssistTeamRmd(data.HeroList, data.SupportId)
  widgets.obj_rmdbase:SetActive(0 < #info)
  UIHelper.CreateSubPart(widgets.obj_rmd, widgets.trans_rmd, #info, function(index, tabPart)
    local v = info[index]
    UIHelper.SetText(tabPart.tx_item, v.des)
  end)
end

function AssistItem:_ShowHero()
  local widgets = self.m_widgets
  local data = self.m_data
  local up = Logic.assistNewLogic:SupportShipUp(data.SupportId)
  local heroList = data.HeroList
  UIHelper.CreateSubPart(widgets.obj_ship, widgets.trans_ship, ShipSlotNum, function(index, tabPart)
    tabPart.im_quality.gameObject:SetActive(heroList[index] ~= nil)
    tabPart.obj_mask:SetActive(index > up)
    if heroList[index] ~= nil then
      local ship = Data.heroData:GetHeroById(heroList[index])
      local shipInfo = Logic.shipLogic:GetShipShowByHeroId(heroList[index])
      UIHelper.SetImage(tabPart.im_icon, tostring(shipInfo.ship_icon5))
      UIHelper.SetStar(tabPart.Star, tabPart.StarPrt, ship.Advance)
      UIHelper.SetText(tabPart.tx_lv, "Lv." .. Mathf.ToInt(ship.Lvl))
      UIHelper.SetImage(tabPart.im_quality, QualityIcon[ship.quality])
      UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[ship.type])
    end
    UGUIEventListener.AddButtonOnClick(tabPart.item, self.m_page._OnClickHero, self.m_page, data)
  end)
end

function AssistItem:TryShowMask(enable)
  local widgets = self.m_widgets
  local data = self.m_data
  local state = Logic.assistNewLogic:GetAssistState(data.SupportId, data.StartTime)
  local show = enable and state ~= AssistFleetState.FINISH and not self.m_isOn
  widgets.obj_clickmask:SetActive(show)
end

function AssistItem:_ShowConsume()
  local widgets = self.m_widgets
  local data = self.m_data
  local consume = Logic.assistNewLogic:GetSupportConsume(data.SupportId)
  widgets.im_cost.gameObject:SetActive(#consume ~= 0)
  if #consume ~= 0 then
    UIHelper.SetText(widgets.tx_cost, consume[3])
    local icon = Logic.goodsLogic:GetIcon(consume[2], consume[1])
    UIHelper.SetImage(widgets.im_cost, icon)
  end
end

function AssistItem:_ShowButton()
  local widgets = self.m_widgets
  local data = self.m_data
  local state = Logic.assistNewLogic:GetAssistState(data.SupportId, data.StartTime)
  widgets.obj_todobtn:SetActive(state == AssistFleetState.TODO)
  widgets.obj_doingbtn:SetActive(state == AssistFleetState.DOING)
  widgets.obj_finishbtn:SetActive(state == AssistFleetState.FINISH)
  if data.SupportId > 0 then
    self:_ShowConsume()
  end
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._CancelAssist, self, data)
  UGUIEventListener.AddButtonOnClick(widgets.btn_fast, self._FastFinish, self, data)
  UGUIEventListener.AddButtonOnClick(widgets.btn_clear, self._ClearHero, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_commend, self._RmdHero, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_assist, self._StartAssist, self, data)
end

function AssistItem:Dispose()
  self:CheckTimer()
end

return AssistItem
