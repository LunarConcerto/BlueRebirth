local GetRewardsPage = class("UI.Common.GetRewardsPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local titleCommon_show = {
  [RewardType.COMMON] = true,
  [RewardType.MONTHCARD] = false,
  [RewardType.FIRSTPASS] = true,
  [RewardType.TOWER] = false,
  [RewardType.TEXT] = true,
  [RewardType.EXTRA_SHIP] = false,
  [RewardType.BIGMONTHCARD] = false,
  [RewardType.GUILD_CONST_REWARD] = false,
  [RewardType.GUILD_RAND_REWARD] = false
}

function GetRewardsPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.mergeRewards = nil
  self.co = nil
  self.m_tabWidgets.btn_share.gameObject:SetActive(platformManager:ShowShare())
end

function GetRewardsPage:DoOnOpen()
  self.rewardType = self.param.RewardType and self.param.RewardType or RewardType.COMMON
  self:ShowContent()
end

function GetRewardsPage:ShowContent()
  local rewardsInfo = {}
  local rewards = self:GetParam().Rewards
  self.extraRewards = self:GetParam().ExtraRewards
  self.desc = self:GetParam().Desc
  self.mShowTweenFlag = self:GetParam().ShowTweenFlag or false
  self.showExtraRewards = false
  self.dontMerge = self.param.DontMerge
  self.m_tabWidgets.obj_titleCommon:SetActive(titleCommon_show[self.rewardType])
  self.m_tabWidgets.obj_titleMonth:SetActive(self.rewardType == RewardType.MONTHCARD)
  self.m_tabWidgets.obj_titleBigMonth:SetActive(self.rewardType == RewardType.BIGMONTHCARD)
  self.m_tabWidgets.im_dailydraw:SetActive(self.rewardType == RewardType.EXTRA_SHIP)
  self.m_tabWidgets.tx_dailydrawtips:SetActive(self.rewardType == RewardType.EXTRA_SHIP)
  self.m_tabWidgets.btnOk.gameObject:SetActive(self.rewardType == RewardType.EXTRA_SHIP)
  self.m_tabWidgets.btnGo.gameObject:SetActive(self.rewardType == RewardType.EXTRA_SHIP)
  self.m_tabWidgets.title_adding:SetActive(false)
  self.m_tabWidgets.title_upgrading:SetActive(false)
  self.m_tabWidgets.im_result:SetActive(self.rewardType == RewardType.TOWER)
  self.m_tabWidgets.tx_towertips.gameObject:SetActive(self.rewardType == RewardType.TOWER)
  self.m_tabWidgets.obj_texiao:SetActive(self:GetParam().effectIsOff ~= true)
  self.m_tabWidgets.texiao:SetActive(self:GetParam().effectIsOff ~= true)
  self.m_tabWidgets.objImgGuildConst:SetActive(self.rewardType == RewardType.GUILD_CONST_REWARD or self.rewardType == RewardType.GUILD_RAND_REWARD)
  self.m_tabWidgets.objImgGuildRand:SetActive(false)
  self.m_tabWidgets.tx_contrrewardtips.gameObject:SetActive(self.rewardType == RewardType.GUILD_CONST_REWARD or self.rewardType == RewardType.GUILD_RAND_REWARD)
  if self.extraRewards and #rewards == 0 then
    self:_ClickClosePageFun()
  elseif self.rewardType == RewardType.TEXT then
    self:_ShowTextRewards(self.rewardType, self.param)
  elseif self.rewardType == RewardType.TOWER then
    if 0 < #rewards then
      self.mergeRewards = self:_SameItemMerge(rewards)
      self:_ShowRewards(self.mergeRewards)
    end
    self.m_tabWidgets.wupin:SetActive(0 < #rewards)
    self:_ShowTowerDesc()
  elseif self.rewardType == RewardType.EXTRA_SHIP then
    local BuildShipId, BuildShipReward = Logic.dailyCopyLogic:GetBuildShipInfo()
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btnGo, self._ClickGo, self, BuildShipId)
    self.mergeRewards = self:_SameItemMerge(BuildShipReward)
    self:_ShowRewards(self.mergeRewards)
    Logic.dailyCopyLogic:ResetBuildShipInfo()
  else
    self.mergeRewards = self:_SameItemMerge(rewards)
    self:_ShowRewards(self.mergeRewards)
    self:_ShowDesc()
  end
end

function GetRewardsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_skip, self._ClickClosePageFun, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_allBg, self._ClickClosePageFun, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_share, self._ClickShare, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btnOk, self._ClickClosePageFun, self)
  self:RegisterEvent(LuaEvent.RewardsPageSkip, self._ClickClosePageFun, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
end

function GetRewardsPage:_ClickGo(go, shipExtraId)
  moduleManager:JumpToFunc(FunctionID.BuildShip, shipExtraId)
end

function GetRewardsPage:_ClickShare()
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName())
end

function GetRewardsPage:_ShareOver()
  self:ShareComponentShow(true)
end

function GetRewardsPage:_ClickClosePageFun()
  if self.extraRewards and self.showExtraRewards == false then
    self.m_tabWidgets.trans_reward.gameObject:SetActive(false)
    SoundManager.Instance:PlayAudio("Effect_eff_ui_first_reward")
    self.m_tabWidgets.trans_small_reward.gameObject:SetActive(false)
    self.m_tabWidgets.obj_extra_effect:SetActive(self.rewardType ~= RewardType.FIRSTPASS and self.rewardType ~= RewardType.GUILD_RAND_REWARD)
    self.m_tabWidgets.obj_firstpass_effect:SetActive(self.rewardType == RewardType.FIRSTPASS)
    self.m_tabWidgets.obj_firstPass:SetActive(self.rewardType == RewardType.FIRSTPASS)
    self.m_tabWidgets.obj_titleCommon:SetActive(self.rewardType == RewardType.COMMON)
    self.m_tabWidgets.obj_bg:SetActive(false)
    self.m_tabWidgets.obj_texiao:SetActive(false)
    self.m_tabWidgets.objImgGuildConst:SetActive(self.rewardType == RewardType.GUILD_CONST_REWARD)
    self.m_tabWidgets.objImgGuildRand:SetActive(self.rewardType == RewardType.GUILD_RAND_REWARD)
    self.m_tabWidgets.objContriEffect:SetActive(self.rewardType == RewardType.GUILD_RAND_REWARD)
    self.m_tabWidgets.tx_contrrewardtips.gameObject:SetActive(self.rewardType == RewardType.GUILD_CONST_REWARD)
    local timer = self:CreateTimer(function()
      self.m_tabWidgets.obj_extra_effect:SetActive(false)
      self.m_tabWidgets.obj_firstpass_effect:SetActive(false)
      self.m_tabWidgets.obj_texiao:SetActive(true)
      self.m_tabWidgets.objContriEffect:SetActive(false)
      self:SetActiveSelf(false)
      self:SetActiveSelf(true)
      self.m_tabWidgets.obj_bg:SetActive(true)
      local extraRewards = self:_SameItemMerge(self.extraRewards)
      self:_ShowRewards(extraRewards)
      self.mergeRewards = self:_SameItemMerge(extraRewards)
      self.showExtraRewards = true
    end, 1, 1, false)
    self:StartTimer(timer)
    return
  end
  if self.mShowTweenFlag and not self.mHasShowTween then
    self.tab_Widgets.tweenPosReward:Play()
    self.tab_Widgets.tweenScaReward:Play()
    self.tab_Widgets.objHide1:SetActive(false)
    self.tab_Widgets.objHide2:SetActive(false)
    self.tab_Widgets.objHide3:SetActive(false)
    self.tab_Widgets.objHide4:SetActive(false)
    self.tab_Widgets.objHide5:SetActive(false)
    self.tab_Widgets.objRewardTips:SetActive(false)
    self.m_tabWidgets.btn_share.gameObject:SetActive(false)
    self.mHasShowTween = true
    self:CreateTimer(function()
      self:CloseSelfPage()
    end, 0.5, 1):Start()
    return
  end
  local showReplace, showReward = Logic.rewardLogic:MedalReplaceReward(self.mergeRewards)
  if showReplace and next(showReward) ~= nil then
    self:_ShowMedalReplaceReward(showReward)
    return
  end
  self:CloseSelfPage()
end

function GetRewardsPage:CloseSelfPage()
  UIHelper.ClosePage("GetRewardsPage")
  if self:GetParam().Page == "HeroRetirePage" then
    eventManager:SendEvent(LuaEvent.OpenEquipDisPage)
  end
end

function GetRewardsPage:_ShowDesc()
  self.m_tabWidgets.tx_shiprewardTips.text = ""
  if self.desc == nil then
    return
  end
  self.m_tabWidgets.tx_shiprewardTips.gameObject:SetActive(true)
  self.m_tabWidgets.tx_shiprewardTips.text = self.desc
end

function GetRewardsPage:_ShowTowerDesc(rewards)
  local str = Logic.towerLogic:GetRewardText(self:GetParam().TowerInfo)
  self.m_tabWidgets.tx_towertips.text = str
end

function GetRewardsPage:_ShowRewards(rewards)
  local obj, trans
  if 5 < #rewards then
    obj = self.m_tabWidgets.obj_small_reward
    trans = self.m_tabWidgets.trans_small_reward
  else
    obj = self.m_tabWidgets.obj_reward
    trans = self.m_tabWidgets.trans_reward
  end
  trans.gameObject:SetActive(true)
  UIHelper.CreateSubPart(obj, trans, #rewards, function(nIndex, tabPart)
    local configInfo = self:_GetRewardConf(rewards[nIndex].Type, rewards[nIndex].ConfigId)
    local name, quality, icon
    if rewards[nIndex].Type == GoodsType.SHIP then
      local shipShow = Logic.shipLogic:GetShipShowById(rewards[nIndex].ConfigId)
      local shipInfo = Logic.shipLogic:GetShipInfoById(rewards[nIndex].ConfigId)
      name = shipInfo.ship_name
      quality = shipInfo.quality
      icon = shipShow.ship_icon5
    elseif rewards[nIndex].Type == GoodsType.EQUIP then
      name = configInfo.name
      quality = configInfo.quality
      icon = configInfo.icon
    elseif rewards[nIndex].Type == GoodsType.FASHION then
      name = configInfo.name
      quality = configInfo.quality
      icon = configInfo.icon_small
    else
      name = configInfo.name
      quality = configInfo.quality
      icon = configInfo.icon
    end
    if rewards[nIndex].Type == GoodsType.PLAYER_HEAD_FRAME then
      local allHeadFrameList = Data.playerHeadFrameData:GetAllHeadFrameData()
      local frameConfig = allHeadFrameList[rewards[nIndex].ConfigId]
      icon = frameConfig.icon
      quality = frameConfig.quality
      name = frameConfig.name
    end
    UIHelper.SetImage(tabPart.im_icon, icon)
    UIHelper.SetImage(tabPart.im_frame, QualityIcon[quality])
    UIHelper.SetText(tabPart.tx_name, name)
    UIHelper.SetText(tabPart.tx_num, "x" .. math.tointeger(rewards[nIndex].Num))
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, self._ShowItemInfo, self, rewards[nIndex])
  end)
end

function GetRewardsPage:_ShowItemInfo(go, award)
  SoundManager.Instance:PlayMusic("UI_Button_CrusadeSuccessPage_0001")
  if award.Type == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
  end
end

function GetRewardsPage:_SameItemMerge(rewards)
  local mergeItemInfo = {}
  for k, v in pairs(rewards) do
    local isHave = self:_IsHaveItem(mergeItemInfo, v.Type, v.ConfigId, v.Num)
    if isHave == false then
      table.insert(mergeItemInfo, v)
    end
  end
  return mergeItemInfo
end

function GetRewardsPage:_IsHaveItem(mergeItemInfo, type, tid, num)
  for k, v in pairs(mergeItemInfo) do
    if v.ConfigId == tid and v.Type == type and not self.dontMerge then
      v.Num = v.Num + num
      return true
    end
  end
  return false
end

function GetRewardsPage:_GetRewardConf(typeId, confId)
  local table_idnex_Info = configManager.GetDataById("config_table_index", typeId)
  local configInfo = configManager.GetDataById(table_idnex_Info.file_name, confId)
  return configInfo
end

function GetRewardsPage:_ShowTextRewards(type, params)
  local widgets = self:GetWidgets()
  local show = type == RewardType.TEXT
  widgets.obj_typeTextReward:SetActive(show)
  widgets.obj_titleCommon:SetActive(false)
  widgets.obj_titleMonth:SetActive(false)
  if params.isAdding then
    widgets.title_adding:SetActive(true)
  else
    widgets.title_upgrading:SetActive(true)
  end
  if show then
    UIHelper.SetText(widgets.tx_textReward, params.content)
  end
end

function GetRewardsPage:DoOnClose()
  local callBack = self:GetParam().callBack
  if callBack then
    callBack()
  end
  if self.co ~= nil then
    coroutine.stop(self.co)
  end
  eventManager:SendEvent(LuaEvent.ShowRewardEnd)
end

function GetRewardsPage:DoOnHide()
end

function GetRewardsPage:_ShowMedalReplaceReward(showReward)
  self.desc = UIHelper.GetString(7200074)
  self.mergeRewards = self:_SameItemMerge(showReward)
  self:_ShowRewards(self.mergeRewards)
  self:_ShowDesc()
end

return GetRewardsPage
