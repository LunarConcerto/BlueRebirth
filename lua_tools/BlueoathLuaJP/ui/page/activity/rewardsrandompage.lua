local RewardsRandomPage = class("ui.page.Activity.RewardsRandomPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TEN = 10

function RewardsRandomPage:DoInit()
  self.showTip = false
  self.showNextPool = false
  self.isRunOutAll = false
  self.haveJackpot = false
  self.curPoolId = 1
  self.showReward = false
  self.item_cost = {
    1,
    17543,
    10
  }
  self.canClick = true
end

function RewardsRandomPage:DoOnOpen()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  local params = self:GetParam() or {}
  self.mActivityId = params.activityId
  if Data.activityExtractData:GetDrawRewardsData() == nil then
    Service.activityExtractService:SendGetActExtractInfo()
    return
  end
  self:ShowPage()
end

function RewardsRandomPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rewarddetail, self._ClickShowDetail, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_change, self._ClickChange, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_total, self._ClickTotal, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_danchou, self._ClickDanchou, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self.CloseMySelf, self)
  self:RegisterEvent(LuaEvent.ActExtraUpdate, self.ShowPage, self)
  self:RegisterEvent(LuaEvent.UpdateBagItem, self.ShowPage, self)
  self:RegisterEvent(LuaEvent.ActExtraReward, self._ShowEffectAndReward, self)
end

function RewardsRandomPage:ShowPage()
  self.curPoolId = Data.activityExtractData:GetDrawID()
  local curPoolConf = configManager.GetDataById("config_activity_extract", self.curPoolId)
  local reward_key = curPoolConf.reward_key
  self.item_cost = curPoolConf.item_cost
  local drop_rewardList = curPoolConf.drop_reward_id
  local ExpendItemId = self.item_cost[2]
  local ownExpendItem = Data.bagData:GetItemNum(ExpendItemId)
  local ExpendItemInfo = Logic.bagLogic:GetItemByTempateId(GoodsType.ITEM, ExpendItemId)
  UIHelper.SetText(self.tab_Widgets.tool_name, ExpendItemInfo.name)
  UIHelper.SetText(self.tab_Widgets.tool_num, ownExpendItem)
  local dayLeft = Logic.activityExtractLogic:GetDayLeft(self.mActivityId)
  local rewardLeft = Logic.activityExtractLogic:GetRewardLeft(self.curPoolId)
  local poolNum = Data.activityExtractData:GetRealDrawID()
  UIHelper.SetText(self.tab_Widgets.tx_dayleft, dayLeft)
  UIHelper.SetText(self.tab_Widgets.tx_rewardleft, rewardLeft)
  UIHelper.SetText(self.tab_Widgets.tx_poolnum, poolNum)
  local totalCount = self:__GetTotalCount()
  UIHelper.SetText(self.tab_Widgets.tx_total, totalCount)
  UIHelper.SetText(self.tab_Widgets.tx_num_tt, totalCount * self.item_cost[3])
  UIHelper.SetText(self.tab_Widgets.tx_num_dc, self.item_cost[3])
  UIHelper.SetImage(self.tab_Widgets.img_item_tt, tostring(ExpendItemInfo.icon))
  UIHelper.SetImage(self.tab_Widgets.img_item_dc, tostring(ExpendItemInfo.icon))
  local drop_gotList = Data.activityExtractData:GetDrawRewardsMap()
  local ShowList = Logic.activityExtractLogic:SortRandomList(drop_rewardList, drop_gotList)
  UIHelper.SetInfiniteItemParam(self.tab_Widgets.obj_content, self.tab_Widgets.item, #ShowList, function(parts)
    for k, part in pairs(parts) do
      local index = tonumber(k)
      local rewardInfo = ShowList[index]
      local restNum = drop_gotList[rewardInfo[1]] or 0
      self:updateItemRewardPart(index, part, rewardInfo, restNum, reward_key)
    end
  end)
end

function RewardsRandomPage:updateItemRewardPart(index, tabPart, info, restNum, reward_key)
  local rewardId = info[1]
  local rewards = configManager.GetDataById("config_rewards", rewardId).rewards
  local reward = rewards[1]
  local restNum = restNum
  local isRunOut = restNum <= 0
  UIHelper.SetText(tabPart.tx_num, restNum .. "/" .. info[2])
  local rewardInfo = Logic.bagLogic:GetItemByTempateId(reward[1], reward[2])
  UIHelper.SetImage(tabPart.im_quality, QualityIcon[rewardInfo.quality])
  UIHelper.SetImage(tabPart.im_icon, tostring(rewardInfo.icon))
  UIHelper.SetText(tabPart.tx_name, rewardInfo.name)
  UIHelper.SetText(tabPart.tx_rewardNum, reward[3])
  local iskey = false
  for k, keyid in pairs(reward_key) do
    if rewardId == keyid then
      iskey = true
    end
  end
  tabPart.bg_key.gameObject:SetActive(iskey)
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

function RewardsRandomPage:_ShowEffectAndReward(param)
  local rewards = param.Ret.Reward
  local Jackpot = Logic.activityExtractLogic:GetDrawJackPot(self.curPoolId, rewards)
  local effobj
  if Jackpot then
    effobj = self.tab_Widgets.obj_effect_reward
  else
    effobj = self.tab_Widgets.obj_effect_common
  end
  self.canClick = false
  effobj:SetActive(true)
  if self.mEffectTimer ~= nil then
    self.mEffectTimer:Stop()
    self.mEffectTimer = nil
  end
  
  local function callback()
    self.tab_Widgets.obj_effect_reward:SetActive(false)
    self.tab_Widgets.obj_effect_common:SetActive(false)
    self.canClick = true
  end
  
  local offsetTime = configManager.GetDataById("config_parameter", 468).arrValue[1]
  self.mEffectTimer = self:CreateTimer(function()
    UIHelper.OpenPage("GetRewardsPage", {
      Rewards = rewards,
      RewardType = RewardType.RANDOM_REWARD,
      JackPot = Jackpot,
      callBack = callback
    })
  end, offsetTime, 1, false)
  self.mEffectTimer:Start()
end

function RewardsRandomPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 6100068})
end

function RewardsRandomPage:_ClickShowDetail()
  UIHelper.OpenPage("RewardRandomDetailsPage")
end

function RewardsRandomPage:_ClickChange()
  self.isRunOutAll = Logic.activityExtractLogic:GetActivityRunOut(self.curPoolId)
  self.haveJackpot = Logic.activityExtractLogic:GetActivityDrawJackpot(self.curPoolId)
  local curPoolConf = configManager.GetDataById("config_activity_extract", self.curPoolId)
  local reward_key = curPoolConf.reward_key
  if self.isRunOutAll then
    Service.activityExtractService:SendActExtractSwitchDraw()
  elseif #reward_key == 0 then
    noticeManager:ShowTip(UIHelper.GetString(6100071))
    return
  elseif #reward_key ~= 0 then
    if not self.haveJackpot then
      noticeManager:ShowTip(UIHelper.GetString(6100070))
      return
    else
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            Service.activityExtractService:SendActExtractSwitchDraw()
          end
        end
      }
      noticeManager:ShowMsgBox(UIHelper.GetString(6100073), tabParams)
    end
  else
    Service.activityExtractService:SendActExtractSwitchDraw()
  end
end

function RewardsRandomPage:_ClickTotal()
  if self.canClick == false then
    return
  end
  local totalCount = self:__GetTotalCount()
  if totalCount < 1 then
    noticeManager:ShowTip(UIHelper.GetString(6100069))
    return false
  end
  if not self:__CheckCanDraw(totalCount) then
    return
  end
  Service.activityExtractService:SendActExtractDraw(self.curPoolId, totalCount)
end

function RewardsRandomPage:_ClickDanchou()
  if self.canClick == false then
    return
  end
  local totalCount = self:__GetTotalCount()
  if totalCount < 1 then
    noticeManager:ShowTip(UIHelper.GetString(6100069))
    return false
  end
  if not self:__CheckCanDraw(1) then
    return
  end
  Service.activityExtractService:SendActExtractDraw(self.curPoolId, 1)
end

function RewardsRandomPage:__GetTotalCount()
  local curPoolConf = configManager.GetDataById("config_activity_extract", self.curPoolId)
  local remainCount = Data.activityExtractData:GetRemainCount()
  if #curPoolConf.reward_key == 0 then
    local ownExpendItem = Data.bagData:GetItemNum(self.item_cost[2])
    if remainCount > ownExpendItem / self.item_cost[3] then
      return math.floor(ownExpendItem / self.item_cost[3])
    else
      return remainCount
    end
  elseif remainCount <= TEN then
    return remainCount
  else
    return TEN
  end
end

function RewardsRandomPage:__CheckCanDraw(num)
  local ownExpendItem = Data.bagData:GetItemNum(self.item_cost[2])
  if ownExpendItem < num * self.item_cost[3] then
    noticeManager:ShowTip(UIHelper.GetString(6100069))
    return false
  end
  return true
end

function RewardsRandomPage:CloseMySelf()
  UIHelper.ClosePage("RewardsRandomPage")
end

function RewardsRandomPage:DoOnHide()
end

function RewardsRandomPage:DoOnClose()
end

return RewardsRandomPage
