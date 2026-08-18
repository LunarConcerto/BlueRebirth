local GetRewardsPage = class("UI.Common.GetRewardsPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local SettleRewardScheduler = require("ui.page.Common.RewardScheduler.SettleRewardScheduler")
local titleCommon_show = {
  [RewardType.COMMON] = true,
  [RewardType.MONTHCARD] = false,
  [RewardType.FIRSTPASS] = true,
  [RewardType.TOWER] = false,
  [RewardType.TEXT] = true,
  [RewardType.EXTRA_SHIP] = false,
  [RewardType.BIGMONTHCARD] = false,
  [RewardType.GUILD_CONST_REWARD] = false,
  [RewardType.GUILD_RAND_REWARD] = false,
  [RewardType.GUILDWAR] = true,
  [RewardType.RANDOM_REWARD] = false,
  [RewardType.RANDOM_UR_REWARD] = true
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
  self.taskRewards = self:GetParam().TaskRewards
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
  self.m_tabWidgets.tx_rewardchangetips.gameObject:SetActive(self.rewardType == RewardType.REDAUCKLAND_CHANGE_REWARD)
  
  local function display()
    if self.rewardType == RewardType.TEXT then
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
    elseif self.rewardType == RewardType.GUILDWAR then
      self:_ShowGuildWarRewards(rewards)
      self:_ShowGuildWarDesc()
    elseif self.rewardType == RewardType.RANDOM_REWARD then
      self.mergeRewards = self:_SameItemMerge(rewards)
      self:_ShowRandomRewards(self.mergeRewards)
      self:_ShowRandomDesc()
    elseif self.rewardType == RewardType.RANDOM_UR_REWARD then
      self:_ShowRandomRewards(rewards)
    else
      self.mergeRewards = self:_SameItemMerge(rewards)
      self:_ShowRewards(self.mergeRewards)
      self:_ShowDesc()
    end
  end
  
  if self:GetParam().Page == "SettlementLogic" then
    if 0 < #rewards then
      SettleRewardScheduler.Register(display)
    end
    if self.taskRewards then
      SettleRewardScheduler.Register(self._ShowTaskReward, self)
    end
    if self.extraRewards then
      SettleRewardScheduler.Register(self._ClickClosePageFun, self)
    end
    if SettleRewardScheduler.Can() then
      SettleRewardScheduler.Next()
    else
      self:CloseSelfPage()
    end
  else
    display()
  end
end

function GetRewardsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_skip, self._OnClickNext, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_allBg, self._OnClickNext, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_share, self._ClickShare, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btnOk, self._OnClickNext, self)
  self:RegisterEvent(LuaEvent.RewardsPageSkip, self._OnClickNext, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
  self:RegisterEvent(LuaEvent.REWARD_TaskRewardSkip, self._ShowTaskReward, self)
end

function GetRewardsPage:_ClickGo(go, shipExtraId)
  moduleManager:JumpToFunc(FunctionID.BuildShip, shipExtraId)
end

function GetRewardsPage:_ClickShare()
  self:ShareComponentShow(false)
  local shareContent
  if self.param.ShareContent then
    shareContent = self.param.ShareContent
  end
  shareManager:Share(self:GetName(), nil, nil, shareContent)
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
    self.m_tabWidgets.tx_rewardchangetips.gameObject:SetActive(self.rewardType == RewardType.REDAUCKLAND_CHANGE_REWARD)
    self:_ShowTaskTop(false)
    local timer = self:CreateTimer(function()
      self.m_tabWidgets.obj_extra_effect:SetActive(false)
      self.m_tabWidgets.obj_firstpass_effect:SetActive(false)
      self.m_tabWidgets.obj_texiao:SetActive(true)
      self.m_tabWidgets.objContriEffect:SetActive(false)
      self:SetActiveSelf(false)
      self:SetActiveSelf(true)
      self.m_tabWidgets.obj_bg:SetActive(true)
      local extraRewards = self:_SameItemMerge(self.extraRewards)
      self.showExtraRewards = true
      self:_ShowRewards(extraRewards)
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
    local itemType = rewards[nIndex].Type
    if rewards[nIndex].ConfigId == 80240 or rewards[nIndex].ConfigId == 80247 or rewards[nIndex].ConfigId == 80248 or rewards[nIndex].ConfigId == 80249 or rewards[nIndex].ConfigId == 80250 then
      itemType = 8
    end
    local configInfo = self:_GetRewardConf(itemType, rewards[nIndex].ConfigId)
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
    elseif rewards[nIndex].Type == GoodsType.PROFILE then
      name = configInfo.name
      quality = 4
      icon = configInfo.image
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
    tabPart.tx_up:SetActive(self:GetParam().Page == "SettlementLogic" and self:GetParam().upReward and not self.showExtraRewards)
  end)
end

function GetRewardsPage:_ShowGuildWarRewards(rewardsInfo)
  local scrollRect = self.m_tabWidgets.wupin:GetComponent(UIScrollRect.GetClassType())
  if next(rewardsInfo) ~= nil then
    table.sort(rewardsInfo, function(a, b)
      if a.BaseID ~= b.BaseID then
        return a.BaseID < b.BaseID
      else
        return a.Stage < b.Stage
      end
    end)
  end
  self.m_tabWidgets.trans_guildwartrans.gameObject:SetActive(true)
  scrollRect.content = self.m_tabWidgets.trans_guildwartrans
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_guildwaritem, self.m_tabWidgets.trans_guildwartrans, #rewardsInfo, function(index, uiPart)
    local info = rewardsInfo[index]
    local baseId = info.BaseID
    local conf = configManager.GetDataById("config_guildwar_base_info", baseId)
    local stage = info.Stage
    local fromSectionId = info.FromSectionID
    local toSectionId = info.ToSectionID
    local rewards = info.RewardList
    UIHelper.SetText(uiPart.tx_base, conf.desc)
    UIHelper.SetLocText(uiPart.tx_stage, 810001, StageName[stage])
    if fromSectionId == toSectionId then
      UIHelper.SetLocText(uiPart.tx_lap, 810002, fromSectionId)
    else
      UIHelper.SetLocText(uiPart.tx_lap, 810002, fromSectionId .. "-" .. toSectionId)
    end
    UIHelper.CreateSubPart(uiPart.obj_item, uiPart.trans_reward, #rewards, function(index2, uiPart2)
      local reward = rewards[index2]
      local type = reward.Type
      local id = reward.ConfigId
      local num = reward.Num
      local icon = Logic.goodsLogic:GetIcon(id, type)
      local quality = Logic.goodsLogic:GetQuality(id, type)
      UIHelper.SetImage(uiPart2.im_icon, icon)
      UIHelper.SetImageByQuality(uiPart2.im_frame, quality)
      UIHelper.SetText(uiPart2.tx_num, "x" .. num)
      
      local function func()
        Logic.rewardLogic:ShowReward(type, id)
      end
      
      UGUIEventListener.AddButtonOnClick(uiPart2.btn_icon, func)
    end)
  end)
end

function GetRewardsPage:_ShowGuildWarDesc()
  self.m_tabWidgets.tx_guildwartips.gameObject:SetActive(self.rewardType == RewardType.GUILDWAR)
  UIHelper.SetText(self.m_tabWidgets.tx_guildwartips, self.desc)
end

function GetRewardsPage:_ShowRandomRewards(rewards)
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
    local itemType = rewards[nIndex].Type
    if rewards[nIndex].ConfigId == 80240 or rewards[nIndex].ConfigId == 80247 or rewards[nIndex].ConfigId == 80248 or rewards[nIndex].ConfigId == 80249 or rewards[nIndex].ConfigId == 80250 then
      itemType = 8
    end
    local configInfo = self:_GetRewardConf(itemType, rewards[nIndex].ConfigId)
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
    elseif rewards[nIndex].Type == GoodsType.PROFILE then
      name = configInfo.name
      quality = 4
      icon = configInfo.image
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
    tabPart.eff_common:SetActive(self.rewardType == RewardType.RANDOM_REWARD and self:GetParam().JackPot == false)
    tabPart.eff_reward:SetActive(self.rewardType == RewardType.RANDOM_REWARD and self:GetParam().JackPot == true)
    local quality_UR = rewards[nIndex].Quality_UR
    local arrValue_URLevel = configManager.GetDataById("config_parameter", 509).arrValue
    local arrValue_URLevelBG = configManager.GetDataById("config_parameter", 510).arrValue
    if self.rewardType == RewardType.RANDOM_UR_REWARD and quality_UR ~= nil and quality_UR ~= 0 then
      UIHelper.SetText(tabPart.tx_level, arrValue_URLevel[quality_UR])
      UIHelper.SetImage(tabPart.im_level, arrValue_URLevelBG[quality_UR])
      tabPart.im_level.gameObject:SetActive(true)
    else
      tabPart.im_level.gameObject:SetActive(false)
    end
    UGUIEventListener.AddButtonOnClick(tabPart.btn_icon, self._ShowItemInfo, self, rewards[nIndex])
    tabPart.tx_up:SetActive(self:GetParam().Page == "SettlementLogic" and self:GetParam().upReward and not self.showExtraRewards)
  end)
end

function GetRewardsPage:_ShowRandomDesc()
  local pos = configManager.GetDataById("config_parameter", 469).arrValue
  self.tab_Widgets.trans_obj_reward.localPosition = Vector2.New(pos[1], pos[2])
  self.tab_Widgets.objHide1:SetActive(false)
  self.tab_Widgets.objHide2:SetActive(false)
  self.tab_Widgets.objHide3:SetActive(false)
  self.tab_Widgets.objHide4:SetActive(false)
  self.tab_Widgets.objHide5:SetActive(false)
  self.m_tabWidgets.btn_share.gameObject:SetActive(false)
end

function GetRewardsPage:_ShowItemInfo(go, award)
  SoundManager.Instance:PlayMusic("UI_Button_CrusadeSuccessPage_0001")
  local itemType = award.Type
  if award.ConfigId == 80240 or award.ConfigId == 80247 or award.ConfigId == 80248 or award.ConfigId == 80249 or award.ConfigId == 80250 then
    itemType = 8
  end
  if itemType == GoodsType.PROFILE then
    return
  end
  if itemType == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(itemType, award.ConfigId))
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

function GetRewardsPage:_ShowTaskReward()
  if self.taskRewards then
    self:_ShowTaskTween()
    self:_ShowTaskTop(true)
    self:_ShowCommonTop(false)
    local taskRewards = self:_SameItemMerge(self.taskRewards)
    self:_ShowRewards(taskRewards)
  elseif SettleRewardScheduler.Can() then
    SettleRewardScheduler.Next()
  else
    self:CloseSelfPage()
  end
end

function GetRewardsPage:_ShowTaskTop(enable)
  local widgets = self:GetWidgets()
  widgets.obj_taskreward:SetActive(enable)
  self:_SetUser(enable)
end

function GetRewardsPage:_ShowCommonTop(enable)
  local widgets = self:GetWidgets()
  widgets.obj_titleCommon:SetActive(enable)
end

function GetRewardsPage:_ShowTaskTween()
  local widgets = self:GetWidgets()
  self:SetActiveSelf(false)
  local ftimer = FrameTimer.New(function()
    self:SetActiveSelf(true)
  end, 1, 1)
  ftimer:Start()
end

function GetRewardsPage:_SetUser(enable)
  local widgets = self:GetWidgets()
  widgets.obj_usrexp:SetActive(enable)
  if enable then
    local userAddExp = self:GetParam().UsrAddExp or 0
    local usrName = Data.userData:GetUserName()
    local usrLv = Data.userData:GetUserLevel()
    local usrExp = Data.userData:GetUserExp()
    local preLvExp = Logic.userLogic:GetMaxExp(usrLv - 1)
    local needExp = Logic.userLogic:GetLvExp(usrLv)
    UIHelper.SetText(widgets.tx_name, usrName)
    UIHelper.SetText(widgets.tx_lv, math.tointeger(usrLv))
    UIHelper.SetText(widgets.tx_addExp, "EXP+" .. userAddExp)
    widgets.sld_add.value = (usrExp - preLvExp) / needExp
  end
end

function GetRewardsPage:_OnClickNext()
  if self:GetParam().Page == "SettlementLogic" then
    if SettleRewardScheduler.Can() then
      SettleRewardScheduler.Next()
    else
      self:CloseSelfPage()
    end
  else
    self:_ClickClosePageFun()
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
  SettleRewardScheduler.Dispose()
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
