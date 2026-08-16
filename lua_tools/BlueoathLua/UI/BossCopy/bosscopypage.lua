local BossCopyPage = class("UI.BossCopy.BossCopyPage", LuaUIPage)
local json = require("cjson")

function BossCopyPage:DoInit()
  self.serCopyData = nil
  self.plotId = 0
  self.bossStage = 0
  self.bossData = {}
  self.actIsOpen = false
  self.showBloodPart = {}
  self.count = 0
  self.bossList = {}
  self.bossUIStatus = {}
  self.uid = Data.userData:GetUserUid()
end

function BossCopyPage:DoOnOpen()
  self.enterFromPlot = (not self.param.FunctionID or self.param.FunctionID ~= FunctionID.ActBoss) and true
  self.serCopyData = Data.copyData:GetCopyInfo()
  if self.enterFromPlot then
    self.plotId = self.param.GotoParam[1]
    local title = moduleManager:GetFunctionTitle(FunctionID.BossCopy)
    self:OpenTopPage("BossCopyPage", 1, title, self, true)
    local isFirstPass = Logic.bossCopyLogic:CheckFirstPassBoss(self.plotId)
    if isFirstPass then
      local copyPlotOpen = UIHelper.IsExistPage("PlotCopyDetailPage")
      UIHelper.ClosePage(self:GetName())
      Logic.copyLogic:SetJumpPlotDetails(13)
      UIHelper.OpenPage("CopyPage", {
        selectCopy = Logic.copyLogic.SelectCopyType.PlotCopy,
        chapterId = 13
      })
      Logic.bossCopyLogic:ResetFastPlot()
      return
    end
    self:_ClickPlotStart(nil, true)
  else
    local title = moduleManager:GetFunctionTitle(FunctionID.ActBoss)
    self:OpenTopPage("BossCopyPage", 1, title, self, true)
  end
  local activityID = Logic.activityLogic:GetActivityIdByType(ActivityType.Boss)
  self.actIsOpen = activityID and Logic.activityLogic:CheckActivityOpenById(activityID)
  if self.actIsOpen and not self.enterFromPlot then
    Service.copyService:SendGetBossData()
  else
    self:_UpdateBossInfo()
    PlayerPrefs.DeleteKey(PlayerPrefsKey.ActivityBoss .. self.uid)
  end
end

function BossCopyPage:RegisterAllEvent()
  self:RegisterEvent(LuaEvent.BossInfoRet, self._UpdateBossInfo, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_plotStart, self._ClickPlotStart, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_plotEnd, self._ClickPlotEnd, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_tips, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rankperson, self._ClickRankPerson, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rankteam, self._ClickRankTeam, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_win, self._ClickWin, self)
end

function BossCopyPage:_UpdateBossInfo()
  self.bossData = Data.copyData:GetBossInfo()
  if next(self.bossData) ~= nil then
    self.bossList = Logic.bossCopyLogic:SortBossList(self.bossData.BossList)
  else
    PlayerPrefs.DeleteKey(PlayerPrefsKey.ActivityBoss .. self.uid)
  end
  local isActBoss = not self.enterFromPlot
  self.tab_Widgets.obj_plot.gameObject:SetActive(not isActBoss)
  self.tab_Widgets.obj_rankpersonal.gameObject:SetActive(isActBoss)
  self.tab_Widgets.obj_rankteam.gameObject:SetActive(isActBoss)
  self.tab_Widgets.btn_showreward.gameObject:SetActive(isActBoss)
  self.tab_Widgets.obj_spship.gameObject:SetActive(false)
  self.tab_Widgets.btn_tips.gameObject:SetActive(isActBoss)
  self.tab_Widgets.tx_num.gameObject:SetActive(isActBoss)
  self.bossStage = Logic.bossCopyLogic:GetBossCopyStage(self.enterFromPlot)
  if self.bossStage == BossStage.PlotSecondBoss then
    self:_CreatePlotPart()
  else
    self:_CreateBossList()
  end
  if self.enterFromPlot and (Logic.bossCopyLogic:CheckPlotEndRecorded() or self.bossStage == BossStage.PlotSecondBoss) then
    self.tab_Widgets.obj_plotEnd.gameObject:SetActive(true)
  end
  local battleMaxNum = configManager.GetDataById("config_parameter", 408).value
  local currBattleNum = self.bossData.AtkCount ~= nil and self.bossData.AtkCount or 0
  local leftNum = battleMaxNum - currBattleNum
  UIHelper.SetText(self.tab_Widgets.tx_num, leftNum)
end

function BossCopyPage:_CreateBossList()
  self.showBloodPart = {}
  self.tab_Widgets.obj_plotBoss:SetActive(false)
  self.tab_Widgets.obj_boss:SetActive(true)
  self.tab_Widgets.btn_win.gameObject:SetActive(false)
  self.tab_Widgets.obj_plotEnd.gameObject:SetActive(false)
  self:_LoadBossList()
  if self.actIsOpen and self.bossStage == BossStage.PlotFirstBoss and not Logic.bossCopyLogic:CheckPlotEndRecorded() then
    self:_ShowBloodEff()
  end
  if self.bossStage == BossStage.ActBattleBoss or self.bossStage == BossStage.ActKillBoss then
    self:_ShowUpShipGril()
  end
end

function BossCopyPage:_ClickRankPerson()
  UIHelper.OpenPage("RankPage", {
    RankType = RankType.ActivityBossSinge
  })
end

function BossCopyPage:_ClickRankTeam()
  UIHelper.OpenPage("RankPage", {
    RankType = RankType.ActivityBossTeam
  })
end

function BossCopyPage:_LoadBossList()
  self:DestroyAllEffect()
  local bossCopyTab = Logic.bossCopyLogic:GetBossCopyConfig()
  local activtyBossConf = Logic.bossCopyLogic:GetActBossConfig()
  local normalBossConf = Logic.bossCopyLogic:GetBossCopyConfig()
  local bossUIPartTab = {}
  local bossConf = {}
  bossConf = self.enterFromPlot and normalBossConf or activtyBossConf
  if (not self.bossList or #self.bossList <= 0) and not self.enterFromPlot then
    logError("\230\156\170\232\142\183\229\143\150\229\136\176boss\229\136\151\232\161\168\230\149\176\230\141\174")
    return
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_bossItem, self.tab_Widgets.trans_boss, #bossConf, function(nIndex, tabPart)
    local copyConf = bossConf[nIndex]
    local currBlood = 0
    tabPart.slider.gameObject:SetActive(true)
    tabPart.obj_mask:SetActive(false)
    tabPart.obj_last:SetActive(false)
    tabPart.obj_success:SetActive(false)
    tabPart.anim_bosseffect.gameObject:SetActive(false)
    UIHelper.SetImage(tabPart.img_bosseffect_now, copyConf.image_boss)
    UIHelper.SetImage(tabPart.img_bosseffect_lock, copyConf.image_boss_2)
    bossUIPartTab[copyConf.id] = tabPart
    if self.bossStage == BossStage.ActBattleBoss then
      local copyDisplayId = copyConf.copy_display_id[1]
      local bossStatus = Logic.bossCopyLogic:GetSingleBossStatusById(self.bossList[nIndex].BossId)
      UIHelper.SetImage(tabPart.img_boss, copyConf.image_boss_2)
      currBlood = currBlood > self.bossList[nIndex].Hp and currBlood or self.bossList[nIndex].Hp
      logError("HP__________________\229\189\147\229\137\141\232\161\128\233\135\143\239\188\154\230\128\187\232\161\128\233\135\143\239\188\154\230\175\148\228\190\139\239\188\154", currBlood, tonumber(copyConf.boss_life), currBlood / tonumber(copyConf.boss_life))
      tabPart.slider.value = currBlood / tonumber(copyConf.boss_life)
      local bloodValue = currBlood / tonumber(copyConf.boss_life)
      bloodValue = (bloodValue - 5.0E-5) * 100.0
      if bloodValue < 0 then
        bloodValue = 0.0
      end
      local str = string.format("%.2f", bloodValue)
      UIHelper.SetText(tabPart.tx_life, str .. "%")
      UGUIEventListener.AddButtonOnClick(tabPart.btn_boss, self._ClickBoss, self, {copyDisplayId, false})
    elseif self.bossStage == BossStage.ActKillBoss then
      local copyDisplayId = copyConf.copy_display_id[1]
      UIHelper.SetImage(tabPart.img_boss, copyConf.image_boss_2)
      tabPart.obj_clear:SetActive(true)
      tabPart.slider.value = 0
      local str = string.format("%.2f", 0)
      UIHelper.SetText(tabPart.tx_life, str .. "%")
      UGUIEventListener.AddButtonOnClick(tabPart.btn_boss, self._ClickBoss, self, {copyDisplayId, false})
    elseif self.bossStage == BossStage.PlotFirstBoss then
      local copyDisplayId = copyConf.copy_display_id[2]
      UIHelper.SetImage(tabPart.img_boss, copyConf.image_boss)
      tabPart.slider.gameObject:SetActive(false)
      if not Logic.bossCopyLogic:CheckPlotEndRecorded() then
        UGUIEventListener.AddButtonOnClick(tabPart.btn_boss, self._ClickPlotEnd, self)
      else
        tabPart.obj_last:SetActive(true)
        UGUIEventListener.AddButtonOnClick(tabPart.btn_boss, self._ClickBoss, self, {copyDisplayId, true})
      end
      if self.serCopyData[copyDisplayId] ~= nil and 0 < self.serCopyData[copyDisplayId].FirstPassTime then
        UIHelper.SetImage(tabPart.img_boss, copyConf.image_boss_2)
        tabPart.obj_clear:SetActive(true)
        tabPart.obj_mask:SetActive(true)
        tabPart.obj_last:SetActive(false)
      end
    end
    UIHelper.SetText(tabPart.tx_boss, copyConf.name)
    tabPart.trans_item.localPosition = Vector2.New(copyConf.image_position[1], copyConf.image_position[2])
    tabPart.trans_item.localScale = Vector3.NewFromTab(copyConf.image_scale)
  end)
  if self.bossStage == BossStage.ActBattleBoss then
    local strUIStatusTab = PlayerPrefs.GetString(PlayerPrefsKey.ActivityBoss .. self.uid)
    local preUIStatusTab
    if strUIStatusTab and strUIStatusTab ~= "" then
      preUIStatusTab = json.decode(strUIStatusTab)
    end
    local bossStatusChange = false
    local haveBossBekilled = false
    for id, UIPart in ipairs(bossUIPartTab) do
      local bossStatus = Logic.bossCopyLogic:GetSingleBossStatusById(id)
      if preUIStatusTab == nil and bossStatus == SingleBossStatus.UnLockedAndLive then
        bossStatusChange = true
        UIPart.img_boss.gameObject:SetActive(false)
        UIPart.anim_bosseffect.gameObject:SetActive(true)
        UIPart.anim_bosseffect:SetBool("IsLock", false)
        self:PerformDelay(1.5, function()
          local effObj = self:CreateUIEffect("effects/prefabs/ui/" .. activtyBossConf[id].eff_boss, UIPart.btn_boss.transform)
        end)
      end
      if preUIStatusTab ~= nil then
        local preStatus = preUIStatusTab[id]
        if preStatus ~= bossStatus then
          bossStatusChange = true
        end
        if preStatus == SingleBossStatus.UnLockedAndLive and bossStatus == SingleBossStatus.Killed then
          haveBossBekilled = true
          UIPart.img_boss.gameObject:SetActive(false)
          UIPart.anim_bosseffect.gameObject:SetActive(true)
          UIPart.anim_bosseffect:SetBool("IsLock", true)
          local bornEffectFunc = function(bossID)
            if bossID <= #self.bossList and 0 < bossID then
              local nextBossPreStatus = preUIStatusTab[bossID]
              local nextBossStatus = Logic.bossCopyLogic:GetSingleBossStatusById(bossID)
              if nextBossPreStatus == SingleBossStatus.Locked and nextBossStatus == SingleBossStatus.UnLockedAndLive then
                bossUIPartTab[bossID].img_boss.gameObject:SetActive(false)
                bossUIPartTab[bossID].anim_bosseffect.gameObject:SetActive(true)
                bossUIPartTab[bossID].anim_bosseffect:SetBool("IsLock", false)
                self:PerformDelay(1.5, function()
                  local effObj = self:CreateUIEffect("effects/prefabs/ui/" .. activtyBossConf[bossID].eff_boss, bossUIPartTab[bossID].btn_boss.transform)
                end)
              end
            end
          end
          self:PerformDelay(2, function()
            self.tab_Widgets.btn_win.gameObject:SetActive(true)
            UIHelper.SetLocText(self.tab_Widgets.tx_win, 4300012, activtyBossConf[id].name)
            UGUIEventListener.ClearBabelButtonEventListener(self.tab_Widgets.btn_win)
            UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_win, function()
              self.tab_Widgets.btn_win.gameObject:SetActive(false)
              bornEffectFunc(id + 1)
            end, self)
          end)
        end
        if preStatus == SingleBossStatus.Locked and bossStatus == SingleBossStatus.UnLockedAndLive and not haveBossBekilled then
          UIPart.img_boss.gameObject:SetActive(false)
          UIPart.anim_bosseffect.gameObject:SetActive(true)
          UIPart.anim_bosseffect:SetBool("IsLock", false)
          self:PerformDelay(1.5, function()
            local effObj = self:CreateUIEffect("effects/prefabs/ui/" .. activtyBossConf[id].eff_boss, bossUIPartTab[id].btn_boss.transform)
          end)
        end
      end
      if not bossStatusChange then
        UIPart.img_boss.gameObject:SetActive(true)
        local bossStatus = Logic.bossCopyLogic:GetSingleBossStatusById(id)
        if bossStatus == SingleBossStatus.UnLockedAndLive then
          local effObj = self:CreateUIEffect("effects/prefabs/ui/" .. activtyBossConf[id].eff_boss, UIPart.btn_boss.transform)
        elseif bossStatus == SingleBossStatus.Killed then
          UIPart.obj_clear:SetActive(true)
        end
      end
      self.bossUIStatus[id] = bossStatus
    end
    local strBossStatus = json.encode(self.bossUIStatus)
    PlayerPrefs.SetString(PlayerPrefsKey.ActivityBoss .. self.uid, strBossStatus)
  elseif self.bossStage == BossStage.ActKillBoss then
    self.tab_Widgets.btn_win.gameObject:SetActive(true)
    UIHelper.SetLocText(self.tab_Widgets.tx_win, 4300013)
    UGUIEventListener.ClearBabelButtonEventListener(self.tab_Widgets.btn_win)
    UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_win, function()
      self.tab_Widgets.btn_win.gameObject:SetActive(false)
    end, self)
  end
end

function BossCopyPage:_ShowBloodEff()
  UIHelper.SetUILock(true)
  self.count = 0
  local duration = configManager.GetDataById("config_parameter", 382).value / 10000
  local timer = self:CreateTimer(function()
    self:_SliderValueChange()
  end, duration, 101, false)
  self:StartTimer(timer)
end

function BossCopyPage:_ShowUpShipGril()
  self.tab_Widgets.obj_spship.gameObject:SetActive(true)
  local activityID = Logic.activityLogic:GetActivityIdByType(ActivityType.Boss)
  local activityConf = configManager.GetDataById("config_activity", activityID)
  local upShipList = activityConf.p2
  UIHelper.CreateSubPart(self.tab_Widgets.obj_shipItem, self.tab_Widgets.trans_spship, #upShipList, function(nIndex, tabPart)
    local heroId = upShipList[nIndex]
    local heroShowConf = configManager.GetDataById("config_ship_show", heroId)
    UIHelper.SetImage(tabPart.im_ship, heroShowConf.ship_icon5)
  end)
end

function BossCopyPage:_SliderValueChange()
  self.count = self.count + 1
  if self.count <= 100 then
    for _, tabPart in ipairs(self.showBloodPart) do
      tabPart.slider.value = self.count / 100
      UIHelper.SetText(tabPart.tx_life, self.count .. "%")
    end
  else
    self:_ClickPlotEnd()
  end
end

function BossCopyPage:_ClickBoss(go, params)
  local baseId = params[1]
  local isPlot = params[2]
  local isHasFleet = Logic.fleetLogic:IsHasFleet()
  if not isHasFleet then
    noticeManager:OpenTipPage(self, 110007)
    return
  end
  if not self.serCopyData[baseId] then
    logError("\230\156\141\229\138\161\229\153\168\232\191\148\229\155\158\231\154\132\230\149\176\230\141\174\228\184\173\230\178\161\230\156\137\229\175\185\229\186\148\229\137\175\230\156\172\230\149\176\230\141\174copyId: ", baseId)
    return
  end
  if not isPlot then
    local bossInfo, bossConfInfo = Logic.bossCopyLogic:GetActBossInfoByCopyId(baseId)
    local bossStatus = Logic.bossCopyLogic:GetSingleBossStatusById(bossInfo.BossId)
    logError("Click BossStatus..............0.\233\148\129\229\174\154\239\188\1401.\232\167\163\233\148\129\229\185\182\229\173\152\230\180\187\239\188\1402.\230\173\187\228\186\161", bossStatus)
    if self.bossStage == BossStage.ActBattleBoss then
      local battleMaxNum = configManager.GetDataById("config_parameter", 408).value
      local currBattleNum = self.bossData.AtkCount ~= nil and self.bossData.AtkCount or 0
      if battleMaxNum - currBattleNum <= 0 then
        noticeManager:OpenTipPage(self, 4300008)
        return
      end
      self.actIsOpen = Logic.activityLogic:CheckActivityOpenById(ActivityType.Boss)
      if not self.actIsOpen then
      end
      local tabParams = {
        msgType = NoticeType.OneButton,
        callback = function(bool)
          if bool then
            Service.copyService:SendGetBossData()
          end
        end
      }
      if bossStatus == SingleBossStatus.Locked then
        if Logic.bossCopyLogic:HaveAliveBoss() then
          noticeManager:ShowMsgBox(4300014, tabParams)
        else
          local lastBossID = bossInfo.BossId - 1
          if 0 < lastBossID then
            local lastBossStatus = Logic.bossCopyLogic:GetSingleBossStatusById(lastBossID)
            if lastBossStatus == SingleBossStatus.Killed then
              noticeManager:ShowMsgBox(4300025, tabParams)
            else
              noticeManager:ShowMsgBox(4300014, tabParams)
            end
          else
            noticeManager:ShowMsgBox(4300025, tabParams)
          end
        end
        return
      elseif bossStatus == SingleBossStatus.Killed then
        noticeManager:ShowMsgBox(4300011, tabParams)
        return
      end
    elseif self.bossStage == BossStage.ActKillBoss then
      return
    end
  elseif isPlot and self.serCopyData[baseId] ~= nil and self.serCopyData[baseId].FirstPassTime == 0 then
    Logic.bossCopyLogic:SetFastPlot()
  end
  local cType = isPlot and CopyType.COMMONCOPY or CopyType.BOSS
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(baseId)
  local areaConfig = {
    copyType = cType,
    tabSerData = self.serCopyData[baseId],
    chapterId = chapterId,
    IsRunningFight = false,
    copyId = baseId,
    isBossPlot = self.enterFromPlot or false
  }
  Logic.copyLogic:SetEnterLevelInfo(true)
  UIHelper.OpenPage("LevelDetailsPage", areaConfig)
end

function BossCopyPage:_CreatePlotPart()
  self.tab_Widgets.obj_plotBoss:SetActive(true)
  self.tab_Widgets.obj_boss:SetActive(false)
  local plotCopyData = Data.copyData:GetPlotCopyDataCopyId(self.plotId)
  local playEffRecorede = Logic.bossCopyLogic:CheckBlackEffRecorded()
  if plotCopyData ~= nil and plotCopyData.FirstPassTime == 0 and not playEffRecorede then
    self.tab_Widgets.obj_plotBoss:SetActive(false)
    self.tab_Widgets.eff_black1:SetActive(true)
    local timer = self:CreateTimer(function()
      self:_ShowBlack2Eff()
    end, 0.9, 1, false)
    self:StartTimer(timer)
    local uid = Data.userData:GetUserUid()
    PlayerPrefs.SetBool("BlackEffRecorded" .. uid, true)
  end
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_plotBoss, self._ClickBoss, self, {
    self.plotId,
    true
  })
end

function BossCopyPage:_ShowBlack2Eff()
  self.tab_Widgets.eff_black2:SetActive(true)
  local timer = self:CreateTimer(function()
    self:_ShowBoss()
  end, 1, 1, false)
  self:StartTimer(timer)
end

function BossCopyPage:_ShowBoss()
  self.tab_Widgets.obj_plotBoss:SetActive(true)
end

function BossCopyPage:_ClickPlotStart(go, openPage)
  openPage = openPage ~= nil and openPage or false
  local plotId = configManager.GetDataById("config_parameter", 378).value
  local recorded = Logic.bossCopyLogic:CheckPlotStartRecorded()
  if openPage and recorded then
    return
  end
  plotManager:OpenPlotPage(plotId)
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetInt("BossPlotStartId" .. uid, plotId)
end

function BossCopyPage:_ClickPlotEnd()
  UIHelper.SetUILock(false)
  local plotId = configManager.GetDataById("config_parameter", 379).value
  plotManager:OpenPlotPage(plotId)
  local uid = Data.userData:GetUserUid()
  PlayerPrefs.SetInt("BossPlotEndId" .. uid, plotId)
end

function BossCopyPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {
    content = UIHelper.GetString(4300020),
    title = UIHelper.GetString(4300019)
  })
end

function BossCopyPage:_ClickWin()
  self.tab_Widgets.btn_win.gameObject:SetActive(false)
end

return BossCopyPage
