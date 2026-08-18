local TreatyPage = class("UI.DailyCopy.Treaty.TreatyPage", LuaUIPage)

function TreatyPage:DoInit()
  self.copyInfo = nil
  self.chapterConfig = nil
  self.selectBuff = {}
  self.treatyCopyData = nil
  self.starNum = 0
  self.m_timer = nil
  self.showEffPart = {}
  self.showEffNum = {}
  self.selectStar = 0
end

function TreatyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._OpenHelpPage)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_battle, self._OpenLevelDetail, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_reward, self._OpenTreatyReward)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._UpdateRewardRedDot, self)
end

function TreatyPage:DoOnOpen()
  self:OpenTopPage("TreatyPage", 1, UIHelper.GetString(920000808), self, true)
  local param = self:GetParam()
  if param.selectBuff then
    self.selectBuff = clone(param.selectBuff)
  else
    self.selectBuff = Logic.dailyCopyLogic:GetRecordExSelectBuff(param.dailyGroupId)
  end
  self.dailyGroupInfo = configManager.GetDataById("config_daily_group", param.dailyGroupId)
  self.copyInfo = Logic.dailyCopyLogic:GetDailyChapterInfo(self.dailyGroupInfo)
  local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(self.copyInfo.id)
  self.chapterConfig = configManager.GetDataById("config_chapter", chapterId)
  self.treatyCopyData = Logic.dailyCopyLogic:GetTreatyData(self.chapterConfig)
  self.tab_Widgets.txt_maxStar.text = self.treatyCopyData.ExStar
  self:_UpdateRewardRedDot()
  self:_CreateTreatyBuff()
  self:_SelectedBuff()
end

function TreatyPage:_CreateTreatyBuff()
  local buffTab = Logic.dailyCopyLogic:GetExBuff(self.dailyGroupInfo)
  local selectBufMap = {}
  for _, v in ipairs(self.selectBuff) do
    selectBufMap[v.id] = v
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_item, self.tab_Widgets.trans_buff, #buffTab, function(nIndex, tabPart)
    local buffInfo = buffTab[nIndex]
    UIHelper.SetImage(tabPart.imgIcon, buffInfo.buff_icon)
    UIHelper.SetText(tabPart.textName, buffInfo.name)
    if buffInfo.flag_new == 1 then
      local isRecord = PlayerPrefs.GetBool("TreatyNewBuff" .. buffInfo.id, false)
      tabPart.obj_red:SetActive(not isRecord)
      if not isRecord then
        PlayerPrefs.SetBool("TreatyNewBuff" .. buffInfo.id, true)
      end
    end
    UIHelper.CreateSubPart(tabPart.obj_starItem, tabPart.trans_star, buffInfo.buff_star, function(i, part)
    end)
    tabPart.tog_select.isOn = selectBufMap[buffInfo.id] ~= nil
    UGUIEventListener.AddButtonToggleChanged(tabPart.tog_select, self._SelectedBuff, self, {
      buffInfo = buffInfo,
      tog = tabPart.tog_select
    })
  end)
end

function TreatyPage:_SelectedBuff(go, isOn, params)
  if isOn ~= nil then
    local buffInfo = params.buffInfo
    if isOn then
      table.insert(self.selectBuff, buffInfo)
    else
      for i, v in ipairs(self.selectBuff) do
        if v.id == buffInfo.id then
          table.remove(self.selectBuff, i)
          break
        end
      end
    end
  end
  self.tab_Widgets.obj_right:SetActive(#self.selectBuff ~= 0)
  if #self.selectBuff == 0 then
    self.selectStar = 0
    self:_ShowBaseInfo(0, 0, 0)
    return
  end
  local currStar = 0
  local addHp = 0
  local addAtk = 0
  UIHelper.CreateSubPart(self.tab_Widgets.obj_selectBuff, self.tab_Widgets.trans_selectBuff, #self.selectBuff, function(nIndex, tabPart)
    local buffInfo = self.selectBuff[nIndex]
    tabPart.txt_name.text = buffInfo.name
    tabPart.txt_effect.text = buffInfo.desc
    UIHelper.SetImage(tabPart.img_icon, buffInfo.buff_icon)
    currStar = currStar + buffInfo.buff_star
    addHp = addHp + buffInfo.treaty_hp
    addAtk = addAtk + buffInfo.treaty_atk
  end)
  local timer = self:CreateTimer(function()
    self.tab_Widgets.scroll_bar.value = 0
  end, 0.1, 1, false)
  if isOn then
    self:StartTimer(timer)
  end
  self.selectStar = currStar
  self:_ShowBaseInfo(currStar, addHp, addAtk)
end

function TreatyPage:_ShowBaseInfo(currStar, addHp, addAtk)
  self.tab_Widgets.txt_currSelectNum.text = #self.selectBuff
  local img
  if self.treatyCopyData.PassEx and #self.selectBuff == 0 then
    img = "uipic_ui_safearea_bu_anquan"
  else
    img = "uipic_ui_safearea_bu_juejing"
  end
  UIHelper.SetImage(self.tab_Widgets.img_status, img)
  self.starNum = currStar <= self.treatyCopyData.ExStar and self.treatyCopyData.ExStar or currStar
  self.tab_Widgets.txt_currStar.text = self.starNum
  self.tab_Widgets.txt_addAttr.text = string.format(UIHelper.GetString(920000801), math.tointeger(addHp), math.tointeger(addAtk))
  self:_TreatyRewardInfo()
end

function TreatyPage:_TreatyRewardInfo()
  self.showEffPart = {}
  self.showEffNum = {}
  local targetIdTab = self.dailyGroupInfo.treaty_item
  local beforStar = Logic.dailyCopyLogic:GetBBattleExStar()
  local beforeSpicalItemNum = self:GetBSpicalItemNum(targetIdTab, beforStar)
  local dropList, dropItemList, baseDropIndex = Logic.dailyCopyLogic:GetExDropInfo(self.dailyGroupInfo, self.starNum, false)
  local orderItemList = self:_DisposeDropOrder(dropItemList, targetIdTab, baseDropIndex)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_dropItem, self.tab_Widgets.trans_drop, #orderItemList, function(nIndex, tabPart)
    local displayInfo = orderItemList[nIndex]
    local itemInfo = displayInfo.itemInfo
    UIHelper.SetImage(tabPart.im_outItem, displayInfo.icon)
    tabPart.im_outItem:SetNativeSize()
    tabPart.obj_textDrop:SetActive(true)
    if displayInfo.showEff and 0 < #beforeSpicalItemNum then
      tabPart.tx_dropRate.text = "x" .. beforeSpicalItemNum[nIndex]
      table.insert(self.showEffPart, tabPart)
      table.insert(self.showEffNum, displayInfo.drop_num)
      tabPart.obj_eff:SetActive(true)
    else
      local str = displayInfo.drop_num and "x" .. displayInfo.drop_num or itemInfo.drop_rate
      tabPart.tx_dropRate.text = str
    end
    tabPart.obj_extra:SetActive(displayInfo.isExtraRewars and itemInfo.type ~= RewardType.FIRSTPASS)
    tabPart.obj_firstReward:SetActive(itemInfo.type == RewardType.FIRSTPASS)
    UIHelper.SetImage(tabPart.imgBg, QualityIcon[displayInfo.quality])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_outItem.gameObject, function()
      Logic.rewardLogic:OnClickDropItem(itemInfo, dropList)
    end)
  end)
  if #beforeSpicalItemNum ~= 0 then
    self.tab_Widgets.txt_maxStar.text = beforStar
    self.tab_Widgets.eff_leftStar:SetActive(true)
    self.tab_Widgets.txt_currStar.text = beforStar
    self.tab_Widgets.eff_rightStar:SetActive(true)
    if self.m_timer == nil then
      self.m_timer = self:CreateTimer(function()
        self:_ShowEffEnd()
      end, 1.2, -1, false)
    end
    self:StartTimer(self.m_timer)
  end
end

function TreatyPage:_ShowEffEnd()
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
  for i, tabPart in ipairs(self.showEffPart) do
    tabPart.tx_dropRate.text = "x" .. self.showEffNum[i]
  end
  self.tab_Widgets.txt_maxStar.text = self.treatyCopyData.ExStar
  self.tab_Widgets.txt_currStar.text = self.treatyCopyData.ExStar
end

function TreatyPage:_DisposeDropOrder(dropItemList, targetIdTab, baseDropIndex)
  local pass = Logic.dailyCopyLogic:CheckExCopyPass(self.chapterConfig.id)
  local orderItemList = {}
  for i, v in ipairs(dropItemList) do
    v.isExtraRewars = pass and i <= baseDropIndex
    v.showEff = false
    if pass then
      for _, k in ipairs(targetIdTab) do
        if v.id == k then
          v.showEff = true
          table.insert(orderItemList, 1, v)
          break
        end
      end
    end
    if not v.showEff then
      table.insert(orderItemList, v)
    end
  end
  return orderItemList
end

function TreatyPage:GetBSpicalItemNum(targetIdTab, beforStar)
  local beforeSpicalItemNum = {}
  if beforStar ~= -1 and beforStar < self.treatyCopyData.ExStar then
    local _, beforeDropItemList, beforeBaseDrop = Logic.dailyCopyLogic:GetExDropInfo(self.dailyGroupInfo, beforStar, false)
    local beforeOrderDrop = self:_DisposeDropOrder(beforeDropItemList, targetIdTab, beforeBaseDrop)
    for i, v in ipairs(beforeOrderDrop) do
      if v.showEff then
        table.insert(beforeSpicalItemNum, v.drop_num)
      end
    end
  end
  Logic.dailyCopyLogic:SetBeforeBattleExStar(-1)
  return beforeSpicalItemNum
end

function TreatyPage:_OpenTreatyReward()
  UIHelper.OpenPage("TreatyRewardPage")
end

function TreatyPage:_OpenHelpPage()
  UIHelper.OpenPage("HelpPage", {content = 920000736})
end

function TreatyPage:_OpenLevelDetail()
  Logic.dailyCopyLogic:SetSelectBuff({
    selectBuff = self.selectBuff,
    starNum = self.selectStar
  })
  Logic.dailyCopyLogic:SetBeforeBattleExStar(self.treatyCopyData.ExStar)
  local serData = Data.copyData:GetDailyCopyByCopyId(self.chapterConfig.treaty_copy[1])
  local chapterId = Logic.copyLogic:DailyChapterId2ChapterId(self.copyInfo.id)
  local areaConfig = {
    copyType = CopyType.DAILYCOPY,
    dailyChapterId = self.copyInfo.id,
    chapterId = chapterId,
    copyId = self.chapterConfig.treaty_copy[1],
    copyInfo = self.copyInfo,
    dailyGroupId = self.dailyGroupInfo.id,
    tabSerData = serData
  }
  if Logic.copyLogic:IsAssistFleet(areaConfig.copyId) then
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

function TreatyPage:DoOnHide()
  Logic.dailyCopyLogic:SetRecordExSelectBuff({
    dailyGroupId = self.dailyGroupInfo.id,
    selectBuff = self.selectBuff
  })
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
end

function TreatyPage:DoOnClose()
  Logic.dailyCopyLogic:SetRecordExSelectBuff({
    dailyGroupId = self.dailyGroupInfo.id,
    selectBuff = self.selectBuff
  })
  if self.m_timer ~= nil then
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
end

function TreatyPage:_UpdateRewardRedDot()
  self.tab_Widgets.obj_reddot:SetActive(Logic.dailyCopyLogic:CheckTreatyReward())
end

return TreatyPage
