local MultiPveEntrancePage = class("ui.page.Activity.MultiPve.MultiPveEntrancePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local Expend_Item = configManager.GetDataById("config_parameter", 434).arrValue

function MultiPveEntrancePage:DoInit()
  self.actConfig = {}
  self.expendItemNum = 1
  self.ownItemNum = 0
  self.m_timer = nil
  self.m_objModel = nil
  self.m_timerCallBack = nil
  self.copyRewardCount = 0
  self.copyId = 0
  self.chapterId = 0
end

function MultiPveEntrancePage:DoOnOpen()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MULTIPVEACT
  })
  self:OpenTopPage("MultiPveEntrancePage", 1, UIHelper.GetString(4800002), self, true)
  local params = self:GetParam()
  self.actConfig = Logic.multiPveActLogic:GetActConfig()
  self.copyId = self.actConfig.p2[1]
  self.chapterId = Logic.copyLogic:GetChapterIdByCopyId(self.copyId)
  self:_ShowRankReward()
  self:_ShowBattleTimes()
  self:_SetAddSpeed()
  self:_LoadShipModel()
end

function MultiPveEntrancePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_addtimes, self._ClickAddtimes, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_shop, self._ClickShop, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_start, self._CheckStartLimit, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_maskclose, self._ClickCloseSpeed, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.leftButton, self._ClickLeftButton, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.rightButton, self._ClickRightButton, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.maxButton, self._ClickMaxButton, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.minButton, self._ClickMinButton, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickSpeedOk, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_cancel, self._ClickCloseSpeed, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickHelp, self)
  self:RegisterEvent(LuaEvent.UpdateCopyRewardCount, self._UpdatePveCount, self)
end

function MultiPveEntrancePage:DoOnHide()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN
  })
  self:_StopTimer()
  self:_UnloadModel()
end

function MultiPveEntrancePage:DoOnClose()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN
  })
  self:_StopTimer()
  self:_UnloadModel()
end

function MultiPveEntrancePage:_ShowRankReward()
  local dropTab = self.actConfig.p3
  UIHelper.CreateSubPart(self.tab_Widgets.obj_rank, self.tab_Widgets.trans_rank, #dropTab, function(nIndex, luaPart)
    UIHelper.SetText(luaPart.tx_rank, nIndex)
    UIHelper.SetImage(luaPart.im_rank, self.actConfig.p8[nIndex])
    local dropInfoTab = {}
    local dropList = DropRewardsHelper.GetDropDisplay(dropTab[nIndex])
    for _, drop in ipairs(dropList) do
      table.insert(dropInfoTab, drop)
    end
    UIHelper.CreateSubPart(luaPart.obj_reward, luaPart.trans_reward, #dropInfoTab, function(index, part)
      local itemInfo = dropInfoTab[index]
      local tabReward = Logic.activityLogic:GetRewardInfo(itemInfo.tabIndex, itemInfo.id)
      UIHelper.SetImage(part.im_reward, tabReward.icon)
      local dropNum = index == 3 and "\230\166\130\231\142\135" or itemInfo.drop_num
      UIHelper.SetText(part.tx_num, dropNum)
    end)
  end)
end

function MultiPveEntrancePage:_ShowBattleTimes()
  self.copyRewardCount = Data.copyData:GetCopyRewardCount(self.chapterId)
  self.tab_Widgets.tx_times.text = self.copyRewardCount
end

function MultiPveEntrancePage:_UpdatePveCount()
  noticeManager:OpenTipPage(self, UIHelper.GetString(4800001))
  self:_ShowBattleTimes()
  self:_ClickCloseSpeed()
end

function MultiPveEntrancePage:_SetAddSpeed()
  local itemInfo = Logic.bagLogic:GetItemByTempateId(Expend_Item[1], Expend_Item[2])
  UIHelper.SetImage(self.tab_Widgets.img_quality, QualityIcon[itemInfo.quality])
  UIHelper.SetImage(self.tab_Widgets.img_icon, itemInfo.icon)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_item, function()
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(Expend_Item[1], Expend_Item[2], true))
  end)
end

function MultiPveEntrancePage:_ClickAddtimes()
  self.expendItemNum = 1
  self.tab_Widgets.txt_addNum.text = self.expendItemNum
  self.ownItemNum = Data.bagData:GetItemNum(Expend_Item[2])
  UIHelper.SetText(self.tab_Widgets.tx_num, self.ownItemNum)
  self.tab_Widgets.obj_speedup:SetActive(true)
end

function MultiPveEntrancePage:_ClickCloseSpeed()
  self.tab_Widgets.obj_speedup:SetActive(false)
end

function MultiPveEntrancePage:_ClickShop()
  local shopId = self.actConfig.shop_id
  UIHelper.OpenPage("ShopPage", {shopId = shopId})
end

function MultiPveEntrancePage:_CheckStartLimit()
  if not Data.activityData:IsActivityOpen(self.actConfig.id) then
    noticeManager:ShowTipById(270022)
    return
  end
  local showTips = Logic.multiPveActLogic:CheckShowTips()
  if self.copyRewardCount <= 0 and showTips then
    local callBackConfirm = function(isOn)
      if PlayerPrefsKey.MultiPveAct then
        PlayerPrefs.SetBool(PlayerPrefsKey.MultiPveAct, isOn)
        PlayerPrefs.SetInt(PlayerPrefsKey.MultiPveAct .. "Time", time.getSvrTime())
      end
      self:_ClickStart()
    end
    local tgIsShow = PlayerPrefsKey.MultiPveAct ~= nil
    local tgIsON = false
    if tgIsShow then
      tgIsON = PlayerPrefs.GetBool(PlayerPrefsKey.MultiPveAct, false)
    end
    noticeManager:ShowSuperNotice(UIHelper.GetString(4800005), UIHelper.GetString(4800006), true, tgIsON, callBackConfirm, nil, UIHelper.GetString(4800007), function()
      self:_ClickAddtimes()
    end)
    return
  end
  self:_ClickStart()
end

function MultiPveEntrancePage:_ClickStart()
  local copyData = Data.copyData:GetCopyInfoById(self.copyId)
  if copyData == nil then
    logError("\229\144\142\231\171\175\230\178\161\230\156\137\232\191\153\228\184\170\229\137\175\230\156\172\231\154\132\230\149\176\230\141\174 copyId" .. self.copyId)
    return
  end
  local param = {
    copyType = CopyType.COMMONCOPY,
    tabSerData = copyData,
    chapterId = self.chapterId,
    IsRunningFight = copyData.IsRunningFight == true,
    copyId = self.copyId
  }
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  UIHelper.OpenPage("LevelDetailsPage", param)
end

function MultiPveEntrancePage:_ClickLeftButton()
  self.expendItemNum = self.expendItemNum - 1
  if self.expendItemNum < 1 then
    self.expendItemNum = 1
    noticeManager:ShowTip(UIHelper.GetString(4800003))
  end
  self.tab_Widgets.txt_addNum.text = self.expendItemNum
end

function MultiPveEntrancePage:_ClickRightButton()
  self.expendItemNum = self.expendItemNum + 1
  if self.expendItemNum > self.ownItemNum then
    self.expendItemNum = self.ownItemNum == 0 and 1 or self.ownItemNum
    noticeManager:ShowTip(UIHelper.GetString(4800004))
  end
  self.tab_Widgets.txt_addNum.text = self.expendItemNum
end

function MultiPveEntrancePage:_ClickMaxButton()
  self.expendItemNum = self.ownItemNum
  if self.expendItemNum <= 1 then
    self.expendItemNum = 1
  end
  self.tab_Widgets.txt_addNum.text = self.expendItemNum
end

function MultiPveEntrancePage:_ClickMinButton()
  self.expendItemNum = 1
  self.tab_Widgets.txt_addNum.text = self.expendItemNum
end

function MultiPveEntrancePage:_ClickSpeedOk()
  if self.expendItemNum > self.ownItemNum then
    noticeManager:ShowTip(UIHelper.GetString(4800008))
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(Expend_Item[1], Expend_Item[2], true))
    return
  end
  Service.copyService:SendAddCopyRewardCount(self.chapterId, self.expendItemNum)
end

function MultiPveEntrancePage:_LoadShipModel()
  local param = {
    showID = self.actConfig.p4[1]
  }
  if self.m_objModel == nil then
    self.m_objModel = GR.shipGirlManager:createShipGirl(param, LayerMask.NameToLayer("MainSceneShip"))
    self.m_objModel:playBehaviour(self.actConfig.p5[1], true)
  end
  self:_StartTimer()
end

function MultiPveEntrancePage:_PlayBehaviour(behaviourName)
  self:_StopTimer()
  if self.m_objModel then
    self.m_objModel:playBehaviour(behaviourName, false, function()
      self:_StartTimer()
      self.m_objModel:playBehaviour(self.actConfig.p5[1], true)
    end)
  end
end

function MultiPveEntrancePage:_StartTimer()
  if self.m_timerCallBack == nil then
    function self.m_timerCallBack()
      self:_PlayBehaviour(self.actConfig.p5[2])
    end
  end
  local intervalTime = self.actConfig.p6[1]
  if self.m_timer == nil then
    self.m_timer = self:CreateTimer(self.m_timerCallBack, intervalTime, 1, false)
  else
    self:ResetTimer(self.m_timer, self.m_timerCallBack, intervalTime, 1, false)
  end
  self:StartTimer(self.m_timer)
end

function MultiPveEntrancePage:_StopTimer()
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
end

function MultiPveEntrancePage:_UnloadModel()
  if self.m_objModel then
    GR.shipGirlManager:destroyShipGirl(self.m_objModel)
    self.m_objModel = nil
  end
end

function MultiPveEntrancePage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 4800011})
end

return MultiPveEntrancePage
