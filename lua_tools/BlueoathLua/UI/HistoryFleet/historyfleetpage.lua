local HistoryFleetPage = class("UI.HistoryFleet.HistoryFleetPage", LuaUIPage)

function HistoryFleetPage:DoInit()
end

function HistoryFleetPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
  self:RegisterEvent(LuaEvent.DeleteRecord, self.ShowContent, self)
  self:RegisterEvent(LuaEvent.GetRecord, self.ShowContent, self)
  self:RegisterEvent(LuaEvent.TacticOn, self._TacticOn, self)
end

function HistoryFleetPage:DoOnOpen()
  local params = self:GetParam()
  self.copyId = params.copyId
  self.chapterId = params.chapterId
  self.fleetType = params.fleetType or FleetType.Tower
  Service.copyService:GetRecord({
    CopyId = self.copyId
  })
end

function HistoryFleetPage:ShowContent(msg)
  local data = msg.CopyRecord
  local widgets = self:GetWidgets()
  widgets.NoHistory:SetActive(#data <= 0)
  widgets.Content.gameObject:SetActive(0 < #data)
  if #data <= 0 then
    return
  end
  UIHelper.CreateSubPart(widgets.kapian, widgets.Content, #data, function(index, tabPart)
    local subData = data[index]
    self:ShowHeroCards(index, tabPart, subData)
  end)
end

function HistoryFleetPage:_TacticOn(msg)
  if msg.IsSkip then
    noticeManager:ShowTipById(1700061)
  else
    noticeManager:ShowTipById(1700064)
  end
end

function HistoryFleetPage:ShowHeroCards(index, tabPart, subData)
  local strategyId = subData.StrategyId
  tabPart.obj_tactic:SetActive(0 < strategyId)
  tabPart.obj_no_tactic:SetActive(strategyId <= 0)
  if subData.StrategyId > 0 then
    local strategyName = Logic.strategyLogic:GetNameById(strategyId)
    UIHelper.SetText(tabPart.tx_tactic_name, strategyName)
  end
  local power = subData.Power or 0
  UIHelper.SetText(tabPart.tx_power, power)
  UIHelper.SetText(tabPart.tx_index, index)
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterId)
  local towerChapterId = chapterConfig.relation_chapter_id
  local fleetType = self.fleetType
  local totalCount = Logic.towerLogic:GetShipBattleTimes(fleetType)
  UIHelper.CreateSubPart(tabPart.item_HeroCard, tabPart.content_Fleet, 6, function(indexSub, tabPartSub)
    local heroData = subData.Tactic[indexSub]
    local templateId = heroData.Tid
    local shipInfoConfig = Logic.shipLogic:GetShipInfoById(templateId)
    local showInfoConfig = Logic.shipLogic:GetShipShowById(templateId)
    local point = heroData.Point
    local num = 0 < totalCount - point and totalCount - point or 0
    local countText = num .. "/" .. totalCount
    UIHelper.SetText(tabPartSub.tx_times1, countText)
    UIHelper.SetText(tabPartSub.tx_times2, countText)
    tabPartSub.towertimes1:SetActive(0 < num)
    tabPartSub.towertimes2:SetActive(num <= 0)
    UIHelper.SetImage(tabPartSub.im_hero, showInfoConfig.ship_icon2)
    UIHelper.SetImage(tabPartSub.im_type, NewCardShipTypeImg[shipInfoConfig.ship_type])
    UIHelper.SetImage(tabPartSub.im_quality, HorizontalCardQulity[shipInfoConfig.quality])
    UIHelper.SetText(tabPartSub.textLv, heroData.Level)
    UIHelper.SetText(tabPartSub.tx_name, shipInfoConfig.ship_name)
    UIHelper.SetStar(tabPartSub.obj_star, tabPartSub.trans_star, heroData.AdvLevel)
    UGUIEventListener.AddButtonOnClick(tabPartSub.btn_fleet, function()
      UIHelper.OpenPage("CopyRecordPage", {info = subData, fleetType = fleetType})
    end)
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_detail, function()
    UIHelper.OpenPage("CopyRecordPage", {info = subData, fleetType = fleetType})
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_delete, function()
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          Service.copyService:DeleteRecord({
            CopyId = self.copyId,
            Index = index - 1
          })
        end
      end
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(1700062), tabParams)
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_tactic_on, function()
    Service.copyService:TacticOn({
      CopyId = self.copyId,
      Index = index - 1
    })
  end)
end

function HistoryFleetPage:btn_close()
  UIHelper.ClosePage("HistoryFleetPage")
end

return HistoryFleetPage
