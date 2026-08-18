local BuildShipURPage = class("UI.BuildShip.BuildShipURPage")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TEN = 10
local ONE = 1

function BuildShipURPage:Init(page, widgets)
  self.mActivityId = UR_Activity_ID
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
    return
  end
  self.page = page
  self.m_tabWidgets = page.m_tabWidgets
  self.showTip = false
  self.showPreview = false
  self.canClick = true
  self.fragmentInfo = nil
  self.curPoolId = 1
  self:RegisterAllEvent()
  self:ShowPage()
end

function BuildShipURPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_preview, self._ClickPreview, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_back, self._ClickBack, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_next, self._ClickNext, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_reset, self._ClickReset, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ur_help, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ur_one, function()
    self:_ClickDraw(true)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ur_ten, function()
    self:_ClickDraw(false)
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ur_chapter, self._ClickChapter, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ur_demo, self._ClickDemo, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_ur_compose, self._ClickCompose, self)
  eventManager:RegisterEvent(LuaEvent.ActExtractURUpdate, self.ShowPage, self)
  eventManager:RegisterEvent(LuaEvent.UpdateBagItem, self.ShowPage, self)
  eventManager:RegisterEvent(LuaEvent.ActExtractURReward, self._ShowEffectAndReward, self)
end

function BuildShipURPage:_UnRegisterAllEvent()
  eventManager:UnregisterEvent(LuaEvent.ActExtractURUpdate, self.ShowPage)
  eventManager:UnregisterEvent(LuaEvent.UpdateBagItem, self.ShowPage)
  eventManager:UnregisterEvent(LuaEvent.ActExtractURReward, self._ShowEffectAndReward)
end

function BuildShipURPage:ShowPage()
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) or self.m_tabWidgets == nil then
    logError(" BuildShipURPage ShowPage Error !", Logic.activityLogic:CheckActivityOpenById(self.mActivityId), self.m_tabWidgets)
    return
  end
  if Data.activityExtractURData:GetDrawRewardsData() == nil then
    Service.activityExtractURService:SendGetActExtractURInfo()
    return
  end
  self.curPoolId = Data.activityExtractURData:GetDrawID()
  self.canClick = true
  self:ShowURInfo()
  self:ShowURRewards()
end

function BuildShipURPage:ShowURInfo()
  local showPoolId, _ = self:__GetShowPoolInfo()
  local curPoolConf = configManager.GetDataById("config_activity_extract_ur", showPoolId)
  UIHelper.SetText(self.m_tabWidgets.tx_ur_desc, curPoolConf.desc)
  local showAll = Logic.activityExtractURLogic:GetDrawAllNum(showPoolId)
  local curRemain = Data.activityExtractURData:GetRemainCount()
  local showRemain = self.showPreview and showAll or curRemain
  local allnum = showRemain .. "/" .. showAll
  UIHelper.SetText(self.m_tabWidgets.tx_all_num, allnum)
  local costdata = {}
  costdata.type = curPoolConf.item_cost[1]
  costdata.id = curPoolConf.item_cost[2]
  local _, value = Logic.itemLogic:GetItemOwnCount(costdata)
  UIHelper.SetText(self.m_tabWidgets.txt_ur_expendnum, value)
  UIHelper.SetText(self.m_tabWidgets.tx_ur_round, Data.activityExtractURData:GetRealDrawID())
  local perCost = curPoolConf.item_cost[3]
  local totalCount = self:__GetTotalCountByRest()
  local num = totalCount < TEN and totalCount or TEN
  UIHelper.SetText(self.m_tabWidgets.txt_ur_expend, ONE * perCost)
  UIHelper.SetText(self.m_tabWidgets.txt_ur_expendTen, num * perCost)
  UIHelper.SetText(self.m_tabWidgets.txt_ur_one, string.format(UIHelper.GetString(820013), ONE))
  UIHelper.SetText(self.m_tabWidgets.txt_ur_ten, string.format(UIHelper.GetString(820013), num))
  local expendInfo = ItemInfoPage.GenDisplayData(curPoolConf.item_cost[1], curPoolConf.item_cost[2])
  UIHelper.SetImage(self.m_tabWidgets.img_ur_expend, tostring(expendInfo.icon))
  UIHelper.SetImage(self.m_tabWidgets.img_ur_expendTen, tostring(expendInfo.icon))
  local isSingle = curPoolConf.id == curPoolConf.next_card_id
  self.m_tabWidgets.obj_normalBtn:SetActive(not self.showPreview)
  self.m_tabWidgets.obj_previewBtn:SetActive(self.showPreview)
  self.m_tabWidgets.btn_preview.gameObject:SetActive(not self.showPreview and not isSingle)
  self.m_tabWidgets.btn_back.gameObject:SetActive(self.showPreview)
  local haveGotKey = Logic.activityExtractURLogic:CheckHaveGotKey(self.curPoolId)
  local haveGotAllKey = Logic.activityExtractURLogic:CheckHaveGotAllKey(self.curPoolId)
  self.m_tabWidgets.btn_next.gameObject:SetActive(not self.showPreview and not isSingle and haveGotKey)
  self.m_tabWidgets.btn_reset.gameObject:SetActive(not self.showPreview and isSingle and haveGotKey)
  local actData = configManager.GetDataById("config_activity", self.mActivityId)
  local _, endTime = PeriodManager:GetPeriodTime(actData.period, actData.period_area)
  self:_TickCharge(endTime)
  if curPoolConf.fragment_id ~= nil and curPoolConf.fragment_id ~= 0 then
    local itemData = self:__GetItemData(curPoolConf.fragment_id)
    local itemConfig = Logic.bagLogic:GetItemByConfig(curPoolConf.fragment_id)
    self.fragmentInfo = {}
    for k, n in pairs(itemConfig) do
      self.fragmentInfo[k] = n
    end
    for k, n in pairs(itemData) do
      self.fragmentInfo[k] = n
    end
    UIHelper.SetText(self.m_tabWidgets.txt_ur_fragment, self.fragmentInfo.num .. "/" .. self.fragmentInfo.amount)
    UIHelper.SetImage(self.m_tabWidgets.img_ur_fragment, self.fragmentInfo.icon)
    self.m_tabWidgets.txt_ur_fragment.gameObject:SetActive(true)
    self.m_tabWidgets.img_ur_fragment.gameObject:SetActive(true)
    self.m_tabWidgets.btn_ur_compose.gameObject:SetActive(true)
  else
    self.m_tabWidgets.txt_ur_fragment.gameObject:SetActive(false)
    self.m_tabWidgets.img_ur_fragment.gameObject:SetActive(false)
    self.m_tabWidgets.btn_ur_compose.gameObject:SetActive(false)
  end
end

function BuildShipURPage:__GetItemData(fragment_id)
  local itemData = Data.bagData:GetItemById(fragment_id)
  if itemData == nil then
    return {num = 0}
  else
    return itemData
  end
end

function BuildShipURPage:_TickCharge(endTime)
  local function stopTimer()
    if self.m_timer ~= nil then
      self.m_timer:Stop()
      
      self.m_timer = nil
    end
  end
  
  local function doTimer()
    local svrTime = time.getSvrTime()
    local surplusTime = endTime - svrTime
    if surplusTime <= 0 then
      stopTimer()
      UIHelper.SetText(self.m_tabWidgets.tx_ur_time, UIHelper.GetString(820012))
    else
      UIHelper.SetText(self.m_tabWidgets.tx_ur_time, time.getTimeStringFontDynamic(surplusTime))
    end
  end
  
  stopTimer()
  self.m_timer = self.page:CreateTimer(function()
    doTimer()
  end, 1, -1)
  self.m_timer:Start()
  doTimer()
end

function BuildShipURPage:ShowURRewards()
  local showPoolId, drop_gotList = self:__GetShowPoolInfo()
  local tab_key, tab_common, tab_superise = Logic.activityExtractURLogic:SortDrawLists(showPoolId)
  UIHelper.CreateSubPart(self.m_tabWidgets.item_key, self.m_tabWidgets.content_key, #tab_key, function(index, tabPart)
    local rewardInfo = tab_key[index]
    local restNum = drop_gotList[rewardInfo[1]] or 0
    self:updateItemRewardPart(index, tabPart, rewardInfo, restNum)
  end)
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.content_common, self.m_tabWidgets.item_common, #tab_common, function(parts)
    for k, tabPart in pairs(parts) do
      local index = tonumber(k)
      local rewardInfo = tab_common[index]
      local restNum = drop_gotList[rewardInfo[1]] or 0
      self:updateItemRewardPart(index, tabPart, rewardInfo, restNum)
    end
  end)
  UIHelper.CreateSubPart(self.m_tabWidgets.item_s, self.m_tabWidgets.content_s, #tab_superise, function(index, tabPart)
    local rewardInfo = tab_superise[index]
    local restNum = -1
    self:updateItemRewardPart(index, tabPart, rewardInfo, restNum)
  end)
end

function BuildShipURPage:updateItemRewardPart(index, tabPart, info, restNum)
  local rewardId = info[1]
  local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
  local reward = rewards[1]
  local restNum = restNum
  local isRunOut = restNum == 0
  UIHelper.SetText(tabPart.tx_num, restNum .. "/" .. info[2])
  local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
  UIHelper.SetImage(tabPart.im_quality, QualityIcon[rewardInfo.quality])
  UIHelper.SetImage(tabPart.im_icon, tostring(rewardInfo.icon))
  UIHelper.SetText(tabPart.tx_name, rewardInfo.name)
  UIHelper.SetText(tabPart.tx_rewardNum, reward[3])
  local arrValue_URLevel = configManager.GetDataById("config_parameter", 509).arrValue
  local arrValue_URLevelBG = configManager.GetDataById("config_parameter", 510).arrValue
  UIHelper.SetText(tabPart.tx_level, arrValue_URLevel[info[#info]])
  UIHelper.SetImage(tabPart.im_level, arrValue_URLevelBG[info[#info]])
  tabPart.img_yilingqu:SetActive(isRunOut)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, function()
    if reward[1] == GoodsType.EQUIP then
      UIHelper.OpenPage("ShowEquipPage", {
        templateId = reward[2],
        showEquipType = ShowEquipType.Simple
      })
    else
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward[1], reward[2]))
    end
  end, self)
end

function BuildShipURPage:__GetShowPoolInfo()
  if self.showPreview == true then
    local curPoolConf = configManager.GetDataById("config_activity_extract_ur", self.curPoolId)
    local prepoolConf = configManager.GetDataById("config_activity_extract_ur", curPoolConf.next_card_id)
    local tmpmap = {}
    for i, v in pairs(prepoolConf.drop_reward_id) do
      tmpmap[v[1]] = v[2]
    end
    return curPoolConf.next_card_id, tmpmap
  else
    return self.curPoolId, Data.activityExtractURData:GetDrawRewardsMap()
  end
end

function BuildShipURPage:_ShowEffectAndReward(param)
  local rewardIds = param.RewardsId
  local rewards = Logic.activityExtractURLogic:FormatRewardsByURIds(self.curPoolId, rewardIds)
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = rewards,
    RewardType = RewardType.RANDOM_UR_REWARD
  })
end

function BuildShipURPage:_ClickPreview()
  if not self:__CheckActivityOpen() then
    return
  end
  self.showPreview = true
  self:ShowPage()
end

function BuildShipURPage:_ClickBack()
  if not self:__CheckActivityOpen() then
    return
  end
  self.showPreview = false
  self:ShowPage()
end

function BuildShipURPage:_ClickNext()
  if not self:__CheckActivityOpen() then
    return
  end
  local haveGotKey = Logic.activityExtractURLogic:CheckHaveGotKey(self.curPoolId)
  if not haveGotKey then
    logError(" \232\191\152\230\156\170\230\138\189\229\136\176\228\184\187\232\166\129\229\165\150\229\138\177\239\188\129\239\188\129")
  end
  
  local function func()
    Service.activityExtractURService:SendActExtractURSwitchDraw()
  end
  
  local function funcc()
  end
  
  self:__CheckChangeFunc(820002, 920000207, 920000208, func, funcc, func)
end

function BuildShipURPage:_ClickReset()
  if not self:__CheckActivityOpen() then
    return
  end
  local haveGotKey = Logic.activityExtractURLogic:CheckHaveGotKey(self.curPoolId)
  if not haveGotKey then
    logError(" \232\191\152\230\156\170\230\138\189\229\136\176\228\184\187\232\166\129\229\165\150\229\138\177\239\188\129\239\188\129")
  end
  
  local function func()
    Service.activityExtractURService:SendActExtractURSwitchDraw()
  end
  
  local function funcc()
  end
  
  self:__CheckChangeFunc(820004, 920000207, 920000208, func, funcc, func)
end

function BuildShipURPage:_ClickHelp()
  if not self:__CheckActivityOpen() then
    return
  end
  UIHelper.OpenPage("HelpPage", {content = 820001})
end

function BuildShipURPage:_ClickChapter()
  if not self:__CheckActivityOpen() then
    return
  end
  local curPoolConf = configManager.GetDataById("config_activity_extract_ur", self.curPoolId)
  local chapterInfo = configManager.GetDataById("config_chapter", curPoolConf.chapter_id)
  local tabParam = {ChapterConf = chapterInfo}
  UIHelper.OpenPage("PlotCopyDetailPage", tabParam)
end

function BuildShipURPage:_ClickDemo()
  if not self:__CheckActivityOpen() then
    return
  end
  local curPoolConf = configManager.GetDataById("config_activity_extract_ur", self.curPoolId)
  local copyId = curPoolConf.copy_display_id
  local copyData = Logic.copyLogic:MakeDefaultCopyInfo(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local areaConfig = {
    copyType = CopyType.COMMONCOPY,
    copyId = copyId,
    tabSerData = copyData,
    chapterId = chapterId,
    IsRunningFight = false
  }
  if Logic.copyLogic:IsAssistFleet(copyId) then
    UIHelper.OpenPage("FleetPage", {
      subType = 2,
      copyId = areaConfig.copyId,
      chapterId = areaConfig.chapterId
    })
  else
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if not isHasFleet then
      noticeManager:OpenTipPage(self, 110007)
      return
    end
    UIHelper.OpenPage("LevelDetailsPage", areaConfig)
  end
end

function BuildShipURPage:_ClickCompose()
  if not self:__CheckActivityOpen() then
    return
  end
  if self.fragmentInfo == nil then
    return
  end
  UIHelper.OpenPage("PaperPage", self.fragmentInfo)
end

function BuildShipURPage:_ClickDraw(isOne)
  if not self:__CheckActivityOpen() then
    return
  end
  if self.canClick == false or self.showPreview == true then
    return
  end
  local drawCount = ONE
  local emptyTips = 820018
  if not isOne then
    drawCount = self:__GetTotalCountByRest()
    emptyTips = 820019
  end
  if self:__GetTotalCountByRest() <= 0 then
    noticeManager:ShowTip(UIHelper.GetString(emptyTips))
    return
  end
  if drawCount > self:__GetCanBuyNum() then
    local item_cost = configManager.GetDataById("config_activity_extract_ur", self.curPoolId).item_cost
    if item_cost[1] ~= GoodsType.ITEM then
      noticeManager:ShowTip(UIHelper.GetString(6100069))
    else
      Logic.shopLogic:BuyExpendItem(item_cost[2], drawCount - self:__GetCanBuyNum(), ShopId.Diamond, UIHelper.GetString(1110010))
    end
    return
  end
  self:Start_Draw(drawCount)
end

function BuildShipURPage:Start_Draw(drawCount)
  if drawCount == nil then
    drawCount = self:__GetCanBuyNum()
  end
  local curPoolConf = configManager.GetDataById("config_activity_extract_ur", self.curPoolId)
  local isSingle = curPoolConf.id == curPoolConf.next_card_id
  
  local function func()
    Service.activityExtractURService:SendActExtractURSwitchDraw()
  end
  
  local function funcc()
    Service.activityExtractURService:SendActExtractURDraw(self.curPoolId, drawCount)
  end
  
  if isSingle then
    self:__CheckDrawFunc(820005, 820017, 820009, 820007, func, funcc)
  else
    self:__CheckDrawFunc(820003, 820016, 820009, 820007, func, funcc)
  end
end

function BuildShipURPage:__GetTotalCountByRest()
  local remainCount = Data.activityExtractURData:GetRemainCount()
  if remainCount <= TEN then
    return remainCount
  else
    return TEN
  end
end

function BuildShipURPage:__GetCanBuyNum()
  local curPoolConf = configManager.GetDataById("config_activity_extract_ur", self.curPoolId)
  local costdata = {}
  costdata.type = curPoolConf.item_cost[1]
  costdata.id = curPoolConf.item_cost[2]
  local _, value = Logic.itemLogic:GetItemOwnCount(costdata)
  local perCost = curPoolConf.item_cost[3]
  local canBuyNum = math.floor(value / perCost)
  return canBuyNum
end

function BuildShipURPage:__CheckActivityOpen()
  if not Logic.activityLogic:CheckActivityOpenById(self.mActivityId) then
    noticeManager:ShowTipById(820012)
    return false
  end
  return true
end

function BuildShipURPage:__CheckNotGetAll()
  local haveGotKey = Logic.activityExtractURLogic:CheckHaveGotKey(self.curPoolId)
  local haveGotAllKey = Logic.activityExtractURLogic:CheckHaveGotAllKey(self.curPoolId)
  if haveGotKey and not haveGotAllKey then
    return true
  end
  return false
end

function BuildShipURPage:__CheckChangeFunc(idtip, idok, idcancel, func, funccancel, funcdefault)
  local haveGotKey = Logic.activityExtractURLogic:CheckHaveGotKey(self.curPoolId)
  local haveGotAllKey = Logic.activityExtractURLogic:CheckHaveGotAllKey(self.curPoolId)
  if haveGotKey and not haveGotAllKey then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          local miniParams = {
            msgType = NoticeType.TwoButton,
            callback = function(bool)
              if bool then
                func()
              else
                funccancel()
              end
            end
          }
          noticeManager:ShowMsgBox(UIHelper.GetString(820020), miniParams)
        else
          funccancel()
        end
      end,
      nameOk = UIHelper.GetString(idok),
      nameCancel = UIHelper.GetString(idcancel)
    }
    noticeManager:ShowMsgBox(UIHelper.GetString(idtip), tabParams)
  else
    funcdefault()
  end
end

function BuildShipURPage:__CheckDrawFunc(idtip1, idtip2, idok, idcancel, func, funcdefault)
  local curActIndex = configManager.GetDataById("config_activity", self.mActivityId).p1[1]
  local haveGotKey = Logic.activityExtractURLogic:CheckHaveGotKey(self.curPoolId)
  local haveGotAllKey = Logic.activityExtractURLogic:CheckHaveGotAllKey(self.curPoolId)
  local uid = Data.userData:GetUserUid()
  if haveGotKey then
    if not haveGotAllKey then
      funcdefault()
    else
      local ShowTip = PlayerPrefs.GetBool(uid .. "ExtractURShowTip" .. "AllKey" .. curActIndex .. Data.activityExtractURData:GetRealDrawID(), true)
      if ShowTip then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              local miniParams = {
                msgType = NoticeType.TwoButton,
                callback = function(bool)
                  if bool then
                    func()
                  else
                    PlayerPrefs.SetBool(uid .. "ExtractURShowTip" .. "AllKey" .. curActIndex .. Data.activityExtractURData:GetRealDrawID(), false)
                  end
                end
              }
              noticeManager:ShowMsgBox(UIHelper.GetString(820021), miniParams)
            else
              PlayerPrefs.SetBool(uid .. "ExtractURShowTip" .. "AllKey" .. curActIndex .. Data.activityExtractURData:GetRealDrawID(), false)
            end
          end,
          nameOk = UIHelper.GetString(idok),
          nameCancel = UIHelper.GetString(idcancel)
        }
        noticeManager:ShowMsgBox(UIHelper.GetString(idtip2), tabParams)
      else
        funcdefault()
      end
    end
  else
    funcdefault()
  end
end

function BuildShipURPage:OnHide()
  self:_UnRegisterAllEvent()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
    self.m_timer = nil
  end
end

function BuildShipURPage:OnClose()
  self:_UnRegisterAllEvent()
  if self.m_timer ~= nil then
    self.m_timer:Stop()
    self.m_timer = nil
  end
end

return BuildShipURPage
