local LevelRecordPartPage = class("UI.Copy.LevelRecordPartPage")
local MiddleTogType = {
  Recommend = "Recommend",
  Fast = "Fast",
  First = "First",
  Evaluate = "Evaluate",
  AtkGrad = "AtkGrad",
  Explain = "Explain",
  Attribute = "Attribute",
  MineBuff = "MineBuff",
  MaxExStarFirst = "MaxExStarFirst",
  MaxExStarFast = "MaxExStarFast",
  BossBattle = "BossBattle",
  CopyProcess = "CopyProcess",
  NvN = "NvN",
  MiniPlan = "MiniPlan"
}
local MiddleTogList = {
  [1] = {
    {
      131004,
      MiddleTogType.Recommend
    },
    {
      131007,
      MiddleTogType.Fast
    },
    {
      131006,
      MiddleTogType.First
    },
    {
      131008,
      MiddleTogType.Evaluate
    }
  },
  [2] = {
    {
      131003,
      MiddleTogType.Explain
    },
    {
      131004,
      MiddleTogType.Recommend
    },
    {
      131007,
      MiddleTogType.Fast
    },
    {
      131006,
      MiddleTogType.First
    },
    {
      131008,
      MiddleTogType.Evaluate
    }
  },
  [3] = {
    {
      131006,
      MiddleTogType.First
    },
    {
      131009,
      MiddleTogType.AtkGrad
    }
  },
  [4] = {
    {
      131004,
      MiddleTogType.Recommend
    }
  },
  [5] = {},
  [6] = {
    {
      131003,
      MiddleTogType.Explain
    }
  },
  [7] = {
    {
      131010,
      MiddleTogType.Attribute
    },
    {
      131007,
      MiddleTogType.Fast
    },
    {
      131006,
      MiddleTogType.First
    },
    {
      131008,
      MiddleTogType.Evaluate
    }
  },
  [8] = {
    {
      131010,
      MiddleTogType.Attribute
    },
    {
      131007,
      MiddleTogType.Fast
    },
    {
      131006,
      MiddleTogType.First
    },
    {
      131008,
      MiddleTogType.Evaluate
    },
    {
      131003,
      MiddleTogType.Explain
    }
  },
  [9] = {
    {
      920000803,
      MiddleTogType.MineBuff
    },
    {
      920000804,
      MiddleTogType.First
    },
    {
      920000805,
      MiddleTogType.Fast
    },
    {
      920000806,
      MiddleTogType.MaxExStarFirst
    },
    {
      920000807,
      MiddleTogType.MaxExStarFast
    }
  },
  [10] = {
    {
      4300015,
      MiddleTogType.BossBattle
    }
  },
  [11] = {
    {
      6100074,
      MiddleTogType.CopyProcess
    },
    {
      131004,
      MiddleTogType.Recommend
    },
    {
      131007,
      MiddleTogType.Fast
    },
    {
      131006,
      MiddleTogType.First
    },
    {
      131008,
      MiddleTogType.Evaluate
    }
  },
  [12] = {
    {
      910000694,
      MiddleTogType.NvN
    },
    {
      131008,
      MiddleTogType.Evaluate
    },
    {
      530015,
      MiddleTogType.MiniPlan
    }
  }
}

function LevelRecordPartPage:Init(page, tabWidgets, param)
  self.page = page
  self.m_tabWidgets = tabWidgets
  self.treatyMaxStar = 0
  self.param = param
  self.isBossPlot = param and param.isBossPlot or false
end

function LevelRecordPartPage:RegisterRecordToggle()
  self.m_tabWidgets.tog_group:ClearToggles()
  local tabTogs = {}
  if self.page.m_fleetType == FleetType.Normal then
    if self.page.m_isGoodsCopy then
      tabTogs = MiddleTogList[4]
    elseif self.page.m_chapterConfig.class_type == ChapterType.Teach and self.page.m_desConfInfo.checkpoint_instructions ~= 0 then
      tabTogs = MiddleTogList[6]
    elseif self.page.m_chapterConfig.new_ocean_tag == 1 and self.page.m_desConfInfo.checkpoint_instructions ~= 0 then
      tabTogs = MiddleTogList[8]
    elseif self.page.m_desConfInfo.checkpoint_instructions ~= 0 then
      tabTogs = MiddleTogList[2]
    elseif self.page.m_chapterConfig.new_ocean_tag == 1 then
      tabTogs = MiddleTogList[7]
    elseif self.page.isTreatyBattle then
      tabTogs = MiddleTogList[9]
      tabTogs = MiddleTogList[9]
    elseif self.page.m_chapterConfig.class_type == ChapterType.BossCopy then
      local bossData = Data.copyData:GetBossInfo()
      if Logic.bossCopyLogic:GetBossCopyStage(self.isBossPlot) == BossStage.ActBattleBoss then
        tabTogs = MiddleTogList[10]
      else
        tabTogs = MiddleTogList[4]
      end
    elseif (self.page.m_chapterConfig.class_type == ChapterType.CopyProcess or self.page.m_chapterConfig.class_type == ChapterType.CopyProcessPlot) and #self.page.m_desConfInfo.copy_progress ~= 0 then
      tabTogs = MiddleTogList[11]
    elseif 0 < self.page.m_desConfInfo.max_fleet then
      local Pos = configManager.GetDataById("config_parameter", 512).arrValue
      self.m_tabWidgets.Right_middle.transform.anchoredPosition = Vector3.New(Pos[1], Pos[2], 0)
      self.m_tabWidgets.haiyutu.gameObject:SetActive(false)
      tabTogs = MiddleTogList[12]
    else
      tabTogs = MiddleTogList[1]
    end
  elseif self.page.m_fleetType == FleetType.LimitTower then
    tabTogs = MiddleTogList[5]
  elseif self.page.m_fleetType == FleetType.GuildWar then
    tabTogs = MiddleTogList[4]
  else
    tabTogs = MiddleTogList[3]
  end
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_togItem, self.m_tabWidgets.trans_display, #tabTogs, function(nIndex, tabPart)
    tabPart.txt_name.text = UIHelper.GetString(tabTogs[nIndex][1])
    self.m_tabWidgets.tog_group:RegisterToggle(tabPart.tog_all)
    local blue = nIndex == 1 and "uipic_ui_clearrecord_bu_01" or "uipic_ui_clearrecord_bu_02"
    local yellow = nIndex == 1 and "uipic_ui_clearrecord_bu_01_xuanzhong" or "uipic_ui_clearrecord_bu_02_xuanzhong"
    UIHelper.SetImage(tabPart.img_blue, blue)
    UIHelper.SetImage(tabPart.img_yellow, yellow)
    if tabTogs[nIndex][2] == MiddleTogType.Evaluate and self.page.m_desConfInfo.evaluation_instructions == "" then
      tabPart.tog_all.gameObject:SetActive(false)
    else
      tabPart.tog_all.gameObject:SetActive(true)
    end
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_group, self, tabTogs, self._RecordTogs)
end

function LevelRecordPartPage:GetCopyInfoCallback(ret)
  self.page.mRecordInfo = ret
  self.treatyMaxStar = ret.MaxExStar
  self.page.mRecordInfo.Recommend = Logic.copyLogic:GetCopyRecommend(self.page.nCopyId)
  self.m_tabWidgets.tog_group:SetActiveToggleIndex(0)
end

function LevelRecordPartPage:_RecordTogs(index, param)
  self.m_tabWidgets.obj_normal:SetActive(not self.page.isTreatyBattle)
  local togType = param[index + 1][2]
  if not self.page.isTreatyBattle then
    self:_ShowNormalRecord(togType)
  else
    self:_ShowTreatyRecord(togType)
  end
end

function LevelRecordPartPage:_ShowNormalRecord(togType)
  self:_ResetDisplay()
  local record = {}
  if togType == MiddleTogType.Evaluate or togType == MiddleTogType.Explain then
    local evaluateStr = togType == MiddleTogType.Evaluate and self.page.m_desConfInfo.evaluation_instructions or ""
    local bossStr = togType == MiddleTogType.Explain and UIHelper.GetString(self.page.m_desConfInfo.checkpoint_instructions) or ""
    UIHelper.SetText(self.m_tabWidgets.txt_score, evaluateStr)
    UIHelper.SetText(self.m_tabWidgets.txt_bossInfo, bossStr)
    self.m_tabWidgets.obj_score:SetActive(true)
    self.m_tabWidgets.obj_bossInfo:SetActive(togType ~= MiddleTogType.Evaluate)
    self.m_tabWidgets.txt_score.gameObject:SetActive(togType == MiddleTogType.Evaluate)
    return
  elseif togType == MiddleTogType.Attribute then
    self:SetRecommendAttr()
    self.m_tabWidgets.obj_attr:SetActive(true)
    return
  elseif togType == MiddleTogType.BossBattle then
    self:_SetBossBattle()
    self.m_tabWidgets.obj_bossCopy:SetActive(true)
    return
  elseif togType == MiddleTogType.CopyProcess then
    self:_SetCopyProcess()
    self.m_tabWidgets.obj_copy_process:SetActive(true)
    return
  elseif togType == MiddleTogType.NvN then
    self:_SetCopyNvN()
    self.m_tabWidgets.obj_enemy_info:SetActive(true)
    return
  elseif togType == MiddleTogType.MiniPlan then
    self:_SetCopyMiniPlan()
    self.m_tabWidgets.obj_mini_plan:SetActive(true)
    return
  else
    record.info = self.page.mRecordInfo[togType]
  end
  self.m_tabWidgets.obj_noRecord:SetActive(record.info == nil or next(record.info.Tactic) == nil)
  self.m_tabWidgets.obj_record:SetActive(record.info ~= nil and next(record.info.Tactic) ~= nil)
  if record.info ~= nil and next(record.info.Tactic) then
    self:_DisplayRecord(record)
  end
end

function LevelRecordPartPage:_ResetDisplay()
  self.m_tabWidgets.obj_noRecord:SetActive(false)
  self.m_tabWidgets.obj_record:SetActive(false)
  self.m_tabWidgets.obj_score:SetActive(false)
  self.m_tabWidgets.obj_attr:SetActive(false)
  self.m_tabWidgets.obj_bossCopy:SetActive(false)
  self.m_tabWidgets.obj_copy_process:SetActive(false)
  self.m_tabWidgets.obj_enemy_info:SetActive(false)
  self.m_tabWidgets.obj_mini_plan:SetActive(false)
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
  end
end

function LevelRecordPartPage:_ShowTreatyRecord(togType)
  self:_ResetDisplay()
  self.m_tabWidgets.obj_treatyBuff:SetActive(togType == MiddleTogType.MineBuff)
  self.m_tabWidgets.obj_record:SetActive(togType ~= MiddleTogType.MineBuff)
  local record = {}
  if togType == MiddleTogType.MineBuff then
    self:_ShowSelectBuff()
  else
    self.m_tabWidgets.txt_name.gameObject.transform.localPosition = Vector3.New(-248, -35, 0)
    self.m_tabWidgets.trans_passTime.localPosition = Vector3.New(175.6, -35, 0)
    self.m_tabWidgets.obj_oTStar.gameObject:SetActive(true)
    record.info = self.page.mRecordInfo[togType]
    if togType == MiddleTogType.Fast or togType == MiddleTogType.First then
      self.m_tabWidgets.txt_oTStar.text = Logic.dailyCopyLogic:GetSelectBuff().starNum
    else
      self.m_tabWidgets.txt_oTStar.text = self.treatyMaxStar
    end
    self.m_tabWidgets.btn_oTBuff.gameObject:SetActive(#record.info.ExBuff ~= 0)
    if record.info ~= nil and next(record.info.Tactic) then
      self:_DisplayRecord(record)
    end
    self.m_tabWidgets.obj_noRecord:SetActive(record.info == nil or next(record.info.Tactic) == nil)
    self.m_tabWidgets.obj_record:SetActive(record.info ~= nil and record.info.Uid ~= 0)
    UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_oTBuff, self._CheckBuff, self, {
      record.info.ExBuff,
      0
    })
  end
end

function LevelRecordPartPage:_DisplayRecord(record)
  self.m_tabWidgets.obj_base:SetActive(record.info.Uid)
  self.m_tabWidgets.txt_name.text = record.info.Uname == "" and math.tointeger(record.info.Uid) or record.info.Uname
  self.m_tabWidgets.txt_lv.text = record.info.Level and "lv." .. math.tointeger(record.info.Level) or 0
  local mTime = record.info.PassTime and time.getTimeStringFontMinute(record.info.PassTime) or 0
  self.m_tabWidgets.txt_time.text = mTime
  self.m_tabWidgets.txt_strategy.text = record.info.StrategyId ~= 0 and Logic.strategyLogic:GetNameById(record.info.StrategyId) or UIHelper.GetString(980022)
  local fleetInfo = record.info.Tactic
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_fleetItem, self.m_tabWidgets.trans_fleet, #fleetInfo, function(index, tabParts)
    local heroInfo = fleetInfo[index]
    local shipShow = Logic.shipLogic:GetShipShowById(heroInfo.Tid)
    local shipInfo = Logic.shipLogic:GetShipInfoById(heroInfo.Tid)
    if index == 1 then
      UIHelper.SetImage(tabParts.img_typeBg, "uipic_ui_newfleetpage_bg_qijiandiban")
    end
    UIHelper.SetImage(tabParts.img_type, NewCardShipTypeImg[shipInfo.ship_type])
    UIHelper.SetImage(tabParts.im_icon, tostring(shipShow.ship_icon5))
    UIHelper.SetStar(tabParts.Star, tabParts.StarPrt, heroInfo.AdvLevel)
    UIHelper.SetText(tabParts.tx_lv, "Lv." .. math.tointeger(heroInfo.Level))
    UIHelper.SetImage(tabParts.im_quality, QualityIcon[shipInfo.quality])
    UGUIEventListener.AddButtonOnClick(tabParts.btn_detail, function()
      self:_OnClickRecordFleet(record)
    end)
  end)
end

function LevelRecordPartPage:_OnClickRecordFleet(record)
  UIHelper.OpenPage("CopyRecordPage", record)
end

function LevelRecordPartPage:SetRecommendAttr()
  if self.page.m_chapterConfig.new_ocean_tag ~= 1 then
    return
  end
  local totalAttack, totalFire, maxSpeed = Logic.fleetLogic:GetFleetAttr(self.page.m_tabFleetData[self.page.nBattleFleedId].heroInfo)
  local attrTab = {
    [1] = {
      icon = "uipic_ui_attribute_im_zhandouli",
      name = 131011,
      limit = self.page.m_displayConfig.recommended_battle_power,
      now = totalAttack,
      hintStr = 131015
    },
    [2] = {
      icon = "uipic_ui_attribute_im_huoli",
      name = 131012,
      limit = self.page.m_displayConfig.recommended_attack,
      now = totalFire,
      hintStr = 131016
    },
    [3] = {
      icon = "uipic_ui_attribute_im_hangsu",
      name = 131013,
      limit = self.page.m_displayConfig.recommended_speed,
      now = maxSpeed,
      hintStr = 131017
    }
  }
  self.page.attrHint = nil
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_attrItem, self.m_tabWidgets.trans_attr, #attrTab, function(index, tabParts)
    info = attrTab[index]
    UIHelper.SetImage(tabParts.img_icon, info.icon)
    tabParts.txt_name.text = UIHelper.GetString(info.name)
    tabParts.txt_limit.text = info.limit
    if self.page.attrHint == nil and info.limit > info.now then
      self.page.attrHint = string.format(UIHelper.GetString(info.hintStr), info.limit)
    end
    local textColor = info.limit <= info.now and "02A611" or "F14949"
    local value = "<color=#" .. textColor .. ">" .. info.now .. "</color>"
    tabParts.txt_now.text = string.format(UIHelper.GetString(131014), value)
  end)
end

function LevelRecordPartPage:_ShowSelectBuff()
  local selectBuff = Logic.dailyCopyLogic:GetSelectBuff().selectBuff
  local chapterConfig = configManager.GetDataById("config_chapter", self.page.nChapterId)
  local exCopyData = Logic.dailyCopyLogic:GetTreatyData(chapterConfig)
  self.m_tabWidgets.txt_maxStar.text = exCopyData.ExStar
  self.m_tabWidgets.obj_noRecord:SetActive(#selectBuff == 0)
  if #selectBuff == 0 then
    self.m_tabWidgets.obj_treatyBuff:SetActive(false)
    self.m_tabWidgets.txt_treatyStar.text = exCopyData.ExStar
    return
  end
  local currStar = 0
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_buffItem, self.m_tabWidgets.trans_buff, #selectBuff, function(nIndex, tabPart)
    local buffInfo = selectBuff[nIndex]
    tabPart.txt_name.text = buffInfo.name
    UIHelper.SetImage(tabPart.img_icon, buffInfo.buff_icon)
    currStar = currStar + buffInfo.buff_star
    UIHelper.CreateSubPart(tabPart.obj_starItem, tabPart.trans_star, buffInfo.buff_star, function(i, part)
    end)
  end)
  self.m_tabWidgets.txt_treatyStar.text = currStar
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_buff, self._CheckBuff, self, {
    selectBuff,
    self.page.param.dailyGroupId
  })
end

function LevelRecordPartPage:_CheckBuff(go, param)
  UIHelper.OpenPage("TreatyBuffShowPage", {
    buffInfo = param[1],
    dailyGroupId = param[2]
  })
end

function LevelRecordPartPage:_SetBossBattle()
  local bossCopyInfo, bossConf = Logic.bossCopyLogic:GetActBossInfoByCopyId(self.page.nCopyId)
  local bossData = Data.copyData:GetBossInfo()
  local battleMaxNum = configManager.GetDataById("config_parameter", 408).value
  local currBattleNum = bossData.AtkCount ~= nil and bossData.AtkCount or 0
  local leftNum = battleMaxNum - currBattleNum
  UIHelper.SetLocText(self.m_tabWidgets.txt_bossLeft, bossConf.leveldetails_id)
  self.m_tabWidgets.txt_bossSum.gameObject:SetActive(false)
end

function LevelRecordPartPage:_SetCopyProcess()
  local widgets = self.m_tabWidgets
  local passCopyCount = Data.copyData:GetPassCopyCountById(self.page.nCopyId)
  local processdata = passCopyCount
  local copyDisplay = configManager.GetDataById("config_copy_display", self.page.nCopyId)
  local processList = copyDisplay.copy_progress
  local valueList = copyDisplay.copy_activity_value
  local onceNum = processList[1]
  local totalNum = processList[2]
  if processdata > totalNum then
    processdata = totalNum
  end
  widgets.copy_process_slider.size = processdata / totalNum
  local strprocess = processdata .. "/" .. totalNum
  UIHelper.SetText(widgets.txt_process, strprocess)
  UGUIEventListener.AddButtonOnClick(widgets.btn_buff_total, function()
    Logic.activityExtractLogic:_ClickShowDetail()
  end)
  local sssDamage = valueList[#valueList][1]
  local startPos = widgets.obj_pstart.position.x
  local endPos = widgets.obj_pend.position.x
  local oldPos = widgets.obj_pstart.position
  UIHelper.CreateSubPart(widgets.obj_process, widgets.tran_process, #valueList, function(index, tabPart)
    local valueinfo = valueList[index]
    local arrowX = valueinfo[1] / sssDamage * (endPos - startPos) + startPos
    tabPart.rect_process.position = Vector3.New(arrowX, oldPos.y, oldPos.z)
    local valueEffect = configManager.GetDataById("config_value_effect", valueinfo[2])
    UIHelper.SetText(tabPart.txt_process, valueinfo[1])
    UIHelper.SetImage(tabPart.icon, valueEffect.buff_icon)
    local desc = string.format(valueEffect.activity_effect_desc, math.floor(valueinfo[3] * valueEffect.activity_value_show[1]))
    UGUIEventListener.AddButtonOnClick(tabPart.btn_process, function()
      noticeManager:ShowTip(desc)
    end)
    tabPart.gameObject:SetActive(true)
  end)
end

function LevelRecordPartPage:_SetCopyNvN()
  local widgets = self.m_tabWidgets
  local copyConfig = configManager.GetMultiDataByKey("config_copy", "copy_id", self.page.nCopyId)
  local fleetList = {}
  for _, c in pairs(copyConfig) do
    for _, fleetId in pairs(c.fleet_id) do
      table.insert(fleetList, fleetId)
    end
  end
  UIHelper.CreateSubPart(widgets.enemy_fleet, widgets.Content_enemy, #fleetList, function(index, tabPart)
    local fleetId = fleetList[index]
    local fleet_info = configManager.GetDataById("config_fleet", fleetId)
    local copy_enemys = fleet_info.copy_enemys
    local buffList = fleet_info.random_factor
    UIHelper.SetText(tabPart.tx_name, fleet_info.display_name)
    UIHelper.SetText(tabPart.recommend_ce, fleet_info.recommend_ce)
    UIHelper.CreateSubPart(tabPart.obj_shipslot, tabPart.rect_shipslot, #copy_enemys, function(nIndex, luaPart)
      local e_id = copy_enemys[nIndex]
      local si_Id = configManager.GetDataById("config_ship_enemy", e_id).ship_info_id
      local si_config = configManager.GetDataById("config_ship_info", si_Id)
      local ss_Config = Logic.shipLogic:GetShipShowByInfoId(si_Id)
      UIHelper.SetImage(luaPart.im_icon, ss_Config.ship_icon5)
      UIHelper.SetImage(luaPart.img_type, NewCardShipTypeImg[si_config.ship_type])
    end)
    UIHelper.CreateSubPart(tabPart.obj_buff, tabPart.rect_buff, #buffList, function(nIndex, luaPart)
      local b_id = buffList[nIndex]
      local setRec = configManager.GetDataById("config_random_factor_set", b_id)
      UIHelper.SetImage(luaPart.img_buff, setRec.set_icon)
      UGUIEventListener.AddButtonOnClick(luaPart.btn_buff, function()
        local buffShow, b_idx = Logic.copyLogic:GetNvNRandFactors(buffList, nIndex)
        UIHelper.OpenPage("RanFactorDetailsPage", {
          copyDisplayId = self.page.nCopyId,
          Factors = buffShow,
          Idx = nIndex
        })
      end)
    end)
  end)
end

function LevelRecordPartPage:_SetCopyMiniPlan()
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
  end
  self.m_popObj = UIHelper.CreateGameObject(self.m_tabWidgets.trans_plan.gameObject, self.m_tabWidgets.obj_plan.transform)
  self.m_popObj:SetActive(true)
end

function LevelRecordPartPage:Close()
  if self.m_popObj ~= nil then
    GameObject.Destroy(self.m_popObj)
  end
end

return LevelRecordPartPage
