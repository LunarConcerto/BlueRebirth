local PlotPage = class("UI.Plot.PlotPage", LuaUIPage)
local chapterDesPlot = require("ui.page.Plot.ChapterDesPlot")
local dialogPlot = require("ui.page.Plot.DialogPlot")
local nobodyDialogPlot = require("ui.page.Plot.NobodyDialogPlot")
local memoirsPageClass = require("ui.page.Plot.PlotMemoirsPage")
local videoPlot = require("ui.page.Plot.VideoPlot")
local Mirror = {NoMirror = 0, HaveMirror = 1}
local RoleExpression = {None = 0}
local BranchParam = {SkipPlot = 1, Continue = 2}
local autoPlay = false

function PlotPage:DoInit()
  GlobalGameState2d = GameState2d.Stop
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.bTowTween = UIHelper.GetTween(self.m_tabWidgets.im_changePlot.gameObject, ETweenType.ETT_ALPHA, "bTow")
  self.wTobTween = UIHelper.GetTween(self.m_tabWidgets.im_changePlot.gameObject, ETweenType.ETT_ALPHA, "wTob")
  self.printTimer = nil
  self.tabPlotInfo = nil
  self.tabCurPlotInfo = nil
  self.tabRecordShowRole = {}
  self.tabWidgetInfo = {}
  self.nfontSpeed = 0
  self.bClickNext = false
  self.ShowNextPlot = false
  self.tabPlotTriggerConf = nil
  self.audioPreload = nil
  self.plotTypeImp = {
    [PlotType.ChapterDes] = chapterDesPlot:new(self, self.m_tabWidgets),
    [PlotType.NormalDialog] = dialogPlot:new(self, self.m_tabWidgets),
    [PlotType.NobodyDialog] = nobodyDialogPlot:new(self, self.m_tabWidgets),
    [PlotType.Video] = videoPlot:new(self, self.m_tabWidgets)
  }
  self.memoirsPage = memoirsPageClass:new(self, self.m_tabWidgets)
end

function PlotPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Next, function()
    self:_ClickNextFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_QuickNext, function()
    self:_ClickNextFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_Skip, function()
    self:_ClickSkipFun()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_barrage_open, self.OnBarrageOpen, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_barrage_close, self.OnBarrageClose, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_input, self.OnBarrageInput, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_auto_open, self.OpenAutoRead, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_auto_close, self.CloseAutoRead, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_memoirs_open, self.OpenMemoirsPage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_memoirs_close, self.CloseMemoirsPage, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_skip_video, function()
    self:_ClickNextFun()
  end)
  self.triggerOver = false
end

function PlotPage:DoOnOpen()
  self.autoPlay = false
  self.currPlayStartTime = 0
  self.autoReadTime = 0
  if plotManager.EditorMode then
    function self.DoOnOpenInterface()
      self:DoOnOpenForEditor()
    end
    
    function self.CheckPlotIsOverInterface()
      return self:_CheckPlotIsOverForEditor()
    end
    
    function self.InitDataInterface()
      self:InitDataForEditor()
    end
    
    function self.PlotOverInterface()
      self:_PlotOverForEditor()
    end
    
    function self._PlotOverImprInterface()
      self:_PlotOverImpForEditor()
    end
  else
    function self.DoOnOpenInterface()
      self:DoOnOpenForGame()
    end
    
    function self.CheckPlotIsOverInterface()
      return self:_CheckPlotIsOverForGame()
    end
    
    function self.InitDataInterface()
      self:InitDataForGame()
    end
    
    function self.PlotOverInterface()
      self:_PlotOverForGame()
    end
    
    function self._PlotOverImprInterface()
      self:_PlotOverImpForGame()
    end
  end
  self:DoOnOpenInterface()
end

function PlotPage:InitData()
  self.InitDataInterface()
end

function PlotPage:InitBarrage()
  local info = self.tabPlotInfo[self.curIndex]
  local funcOpen = moduleManager:CheckFunc(FunctionID.PlotBarrage, false)
  local state = Logic.chatLogic:GetBarrageState()
  local open = funcOpen and state == 1
  self.tab_Widgets.btn_barrage_close.gameObject:SetActive(open)
  self.tab_Widgets.btn_input.gameObject:SetActive(open)
  self.barrageOpen = open
  self.tab_Widgets.obj_barrage:SetActive(info.barrage_ctrl == 1)
  if open then
    UIHelper.OpenPage("BarragePage", {
      btype = BarrageType.Plot,
      sceneId = info.plot_episode_step_id
    })
  end
end

function PlotPage:ChangeBarrageLib()
  local info = self.tabPlotInfo[self.curIndex]
  self.tab_Widgets.obj_barrage:SetActive(info.barrage_ctrl == 1)
  if info.barrage_ctrl == 0 and UIHelper.IsExistPage("BarragePage") then
    UIHelper.ClosePage("BarragePage")
  end
  eventManager:SendEvent(LuaEvent.OnBarrageChanged, {
    btype = BarrageType.Plot,
    sceneId = info.plot_episode_step_id
  })
end

function PlotPage:OnBarrageOpen()
  if moduleManager:CheckFunc(FunctionID.PlotBarrage, true) then
    self.tab_Widgets.btn_barrage_close.gameObject:SetActive(true)
    if self.tabPlotInfo and self.curIndex > 0 then
      Logic.chatLogic:SetBarrageState(1)
      local info = self.tabPlotInfo[self.curIndex]
      UIHelper.OpenPage("BarragePage", {
        btype = BarrageType.Plot,
        sceneId = info.plot_episode_step_id
      })
      self.tab_Widgets.btn_input.gameObject:SetActive(true)
    end
    self.barrageOpen = true
  end
end

function PlotPage:OnBarrageClose()
  UIHelper.ClosePage("BarragePage")
  self.tab_Widgets.btn_barrage_close.gameObject:SetActive(false)
  self.tab_Widgets.btn_input.gameObject:SetActive(false)
  Logic.chatLogic:SetBarrageState(0)
  self.barrageOpen = false
end

function PlotPage:OnBarrageInput()
  self:CloseAutoRead()
  eventManager:SendEvent(LuaEvent.BarrageInput)
end

function PlotPage:_CheckReward()
  return not Data.guideData:PlotIsGot(self.curTriggerId)
end

function PlotPage:_PlayPlot()
  if self.CheckPlotIsOverInterface() then
    return
  end
  self.playTimes = self.playTimes + 1
  self.curIndex = self.curIndex + 1
  local info = self.tabPlotInfo[self.curIndex]
  self.time = info.auto_next_time
  self.tabCurPlotInfo = info
  self:_SetWidgetsActive(info)
  local txt_obj
  self:ChangeBarrageLib()
  self.plotImp = self.plotTypeImp[info.plot_episode_type]
  if info.black_scene ~= nil and 1 < #info.black_scene and info.black_scene_color ~= nil and info.black_scene_color ~= "" then
    self.m_tabWidgets.im_changePlot.color = UIHelper.GetColor(info.black_scene_color)
  else
    self.m_tabWidgets.im_changePlot.color = UIHelper.GetColor("000000")
  end
  local audioinfo = Logic.plotLogic:GetPlotAudioInfoConfigById(info.plot_episode_step_id, info.plot_episode_id)
  self:_DelayPlayAudio(audioinfo, self.curIndex)
  self:_ShowBlackSwitch(info, function()
    if info.plot_episode_type ~= PlotType.Video then
      self.plotImp:PlayPlot(self.tabPlotInfo, self.curIndex)
    else
      self.plotImp:PlayPlot(self.tabPlotInfo, self.curIndex, function()
        self.m_tabWidgets.video_node:SetActive(false)
        self.m_tabWidgets.btn_root:SetActive(true)
        self:_ClickNextFun()
      end)
    end
  end, true)
  if info.plot_episode_type ~= PlotType.Video then
    self:PlayAutoRead(info)
  end
  if plotManager.EditorMode == true then
    PlayPlotCallBack.PlayStep(info.plot_episode_step_id)
  end
  plotManager:Record(self.tabPlotInfo[self.curIndex])
  if self.autoPlay ~= true then
    self:_AutoClickNextFunc(info)
  end
end

function PlotPage:_AutoClickNextFunc(info)
  if self.plotTimer ~= nil then
    self.plotTimer:Stop()
  end
  if self.time > 0 then
    local nextTime = self.time + self:GetPreSwitchBlackScreenTime(info) + 0.1
    self.plotTimer = Timer.New(function()
      self:_ClickNextFun()
    end, nextTime, -1, false)
    self.plotTimer:Start()
  end
end

function PlotPage:GetPlayerCVTime(plotinfo)
  local audio = Logic.plotLogic:GetPlotAudioInfoConfigById(plotinfo.plot_episode_step_id, plotinfo.plot_episode_id)
  if audio ~= nil and audio.audio_id ~= nil and audio.audio_id ~= "" then
    return SoundManager.Instance:GetSoundDuration(audio.audio_id)
  end
  return 0
end

function PlotPage:_DelayPlayAudio(audioinfo, index)
  self.curAudioInfo = audioinfo
  if self.delayPlayAudioTimer ~= nil then
    self.delayPlayAudioTimer:Stop()
  end
  local handle = function()
    if self.curAudioInfo ~= nil and conditionCheckManager:Checkvalid(self.curAudioInfo.background_music) and not plotManager.MuteBackgroundMusic then
      SoundManager.Instance:PlayMusic(self.curAudioInfo.background_music)
      Logic.plotMaker.background_music = self.curAudioInfo.background_music
    end
    if self.curAudioInfo ~= nil and conditionCheckManager:Checkvalid(self.curAudioInfo.audio_id) and not plotManager.MuteCV then
      SoundManager.Instance:PlayAudio(self.curAudioInfo.audio_id)
      Logic.plotMaker.audio_id = self.curAudioInfo.audio_id
      self.last_audio_ID = self.curAudioInfo.audio_id
    end
  end
  if index == 1 then
    SoundManager.Instance:PlayAudio("mute_timeup")
    self.delayPlayAudioTimer = FrameTimer.New(handle, 1, 0)
    self.delayPlayAudioTimer:Start()
  else
    handle()
  end
end

function PlotPage:GetPreSwitchBlackScreenTime(plotinfo)
  if plotinfo.black_scene_timing == 1 then
    local time = 0
    if plotinfo.black_scene[2] ~= nil then
      time = time + plotinfo.black_scene[2]
    end
    if plotinfo.black_scene[3] ~= nil then
      time = time + plotinfo.black_scene[3]
    end
    return time
  end
  return 0
end

function PlotPage:PlayAutoRead(info)
  if plotManager.EditorMode then
    return
  end
  self.currPlayStartTime = time.getSvrTime()
  if info.auto_read < 0 then
    self:CloseAutoRead()
    self:ShowAutoRead(false)
    return -1
  else
    self:ShowAutoRead(true)
  end
  local contentTab = self:GetContent(info.content)
  local strLen = utf8.len(contentTab.content)
  self.autoReadTime = strLen / (self.nfontSpeed * 1000)
  local time = self:GetPlayerCVTime(info)
  self.autoReadTime = math.max(self.autoReadTime, info.auto_read, time)
  self.autoReadTime = self.autoReadTime + 0.1 + self:GetPreSwitchBlackScreenTime(info)
  self.autoReadTime = math.max(self.autoReadTime, 1, self.time)
  if self.plotAutoReadTimer then
    self.plotAutoReadTimer:Stop()
  end
  if self.autoPlay == true then
    self.plotAutoReadTimer = Timer.New(function()
      self:_ClickNextFun()
    end, self.autoReadTime, -1, false)
    self.plotAutoReadTimer:Start()
  end
  return 0
end

function PlotPage:OpenAutoRead()
  if self.plotAutoReadTimer then
    self.plotAutoReadTimer:Stop()
  end
  if self.triggerOver == true then
    return
  end
  self.m_tabWidgets.btn_auto_open.gameObject:SetActive(false)
  self.m_tabWidgets.btn_auto_close.gameObject:SetActive(true)
  if self.autoPlay == false then
    self.autoPlay = true
    self.autoReadTime = self.autoReadTime - (time.getSvrTime() - self.currPlayStartTime)
    if self.autoReadTime <= 1 then
      self:_ClickNextFun()
    else
      self.plotAutoReadTimer = Timer.New(function()
        self:_ClickNextFun()
      end, self.autoReadTime, -1, false)
      self.plotAutoReadTimer:Start()
    end
  end
end

function PlotPage:CloseAutoRead()
  self.autoPlay = false
  if self.plotAutoReadTimer then
    self.plotAutoReadTimer:Stop()
  end
  self.m_tabWidgets.btn_auto_open.gameObject:SetActive(true)
  self.m_tabWidgets.btn_auto_close.gameObject:SetActive(false)
end

function PlotPage:ShowAutoRead(yes)
  if yes ~= true then
    self.m_tabWidgets.btn_auto_open.gameObject:SetActive(false)
    self.m_tabWidgets.btn_auto_close.gameObject:SetActive(false)
  elseif self.autoPlay == false then
    self.m_tabWidgets.btn_auto_open.gameObject:SetActive(true)
    self.m_tabWidgets.btn_auto_close.gameObject:SetActive(false)
  else
    self.m_tabWidgets.btn_auto_open.gameObject:SetActive(false)
    self.m_tabWidgets.btn_auto_close.gameObject:SetActive(true)
  end
end

function PlotPage:_SetWidgetsActive(info)
  self.m_tabWidgets.obj_chapterDes:SetActive(info.plot_episode_type == PlotType.ChapterDes or info.plot_episode_type == PlotType.NobodyDialog)
  self.m_tabWidgets.obj_normalDialog:SetActive(info.plot_episode_type == PlotType.NormalDialog)
  self.m_tabWidgets.btn_Skip.gameObject:SetActive(false)
  if info.plot_episode_skip == PlotSkipType.Current or info.plot_episode_skip == PlotSkipType.All then
    self.m_tabWidgets.btn_Skip.gameObject:SetActive(true)
  end
  if info.plot_episode_skip == PlotSkipType.CurrentUnread and plotManager:CheckShowTip(info) then
    self.m_tabWidgets.btn_Skip.gameObject:SetActive(true)
  end
  self.m_tabWidgets.btn_memoirs_open.gameObject:SetActive(info.log == 1)
end

function PlotPage:_ShowBlackSwitch(plotInfo, callBack, isBefore)
  if isBefore == true then
    self.lockNextClick = true
  end
  local funcCallBack = function()
    if callBack then
      callBack()
      self.lockNextClick = false
    end
  end
  local flag = false
  if isBefore then
    flag = plotInfo.black_scene_timing == 1
  else
    flag = plotInfo.black_scene_timing == 2
  end
  if flag and plotInfo.black_scene ~= nil and #plotInfo.black_scene > 0 then
    self.m_tabWidgets.im_changePlot.gameObject:SetActive(true)
    if plotInfo.black_scene[1] == 1 then
      funcCallBack()
      self:_ShowBlackToWhiteSwitch(function()
        self.m_tabWidgets.im_changePlot.gameObject:SetActive(false)
      end, plotInfo.black_scene[2])
    elseif isBefore == true then
      self:_ShowWhiteToBlackSwitch(function()
        if plotInfo.black_scene[3] > 0 then
          funcCallBack()
          self:_ShowBlackToWhiteSwitch(function()
            self.m_tabWidgets.im_changePlot.gameObject:SetActive(false)
          end, plotInfo.black_scene[3])
        else
          funcCallBack()
        end
      end, plotInfo.black_scene[2])
    elseif isBefore == false then
      self:_ShowWhiteToBlackSwitch(function()
        if plotInfo.black_scene[3] <= 0 then
          self.m_tabWidgets.im_changePlot.gameObject:SetActive(false)
          if self.whiteToBlackTimer ~= nil then
            self.whiteToBlackTimer:Stop()
          end
          self.whiteToBlackTimer = FrameTimer.New(function()
            funcCallBack()
          end, 0, 0)
          self.whiteToBlackTimer:Start()
        elseif plotInfo.black_scene[3] > 0 then
          funcCallBack()
          self:_ShowBlackToWhiteSwitch(function()
            self.m_tabWidgets.im_changePlot.gameObject:SetActive(false)
          end, plotInfo.black_scene[3])
        end
      end, plotInfo.black_scene[2])
    end
  else
    funcCallBack()
  end
end

function PlotPage:_ResetBlackTween()
  self.bTowTween:Stop()
  self.wTobTween:Stop()
  self.m_tabWidgets.im_changePlot.gameObject:SetActive(false)
end

function PlotPage:_ShowWhiteToBlackSwitch(callBack, duration)
  self.wTobTween.duration = duration
  local func = function()
    callBack()
  end
  self.wTobTween:SetOnFinished(func)
  self.wTobTween:ResetToBeginning()
  self.wTobTween:Play()
end

function PlotPage:_ShowBlackToWhiteSwitch(callBack, duration)
  self.bTowTween.duration = duration
  local func = function()
    callBack()
  end
  self.bTowTween:SetOnFinished(func)
  self.bTowTween:ResetToBeginning()
  self.bTowTween:Play()
end

function PlotPage:GetContent(content)
  local playerName = Data.userData:GetUserName()
  if playerName ~= nil then
    content = string.gsub(content, "_playername_", playerName)
  end
  local color = ""
  local result = content
  local sTab = string.split(content, ">")
  if 1 < #sTab then
    local bColor = sTab[1] .. ">"
    local ssTab = string.split(sTab[2], "<")
    result = ssTab[1]
    local aColor = "<" .. ssTab[2] .. ">"
    color = bColor .. "%s" .. aColor
  else
    result = content
    color = "%s"
  end
  return {content = result, color = color}
end

function PlotPage:GetAllRichContent(content)
  local playerName = Data.userData:GetUserName()
  if playerName ~= nil then
    content = string.gsub(content, "_playername_", playerName)
  end
  return content
end

function PlotPage:Parse(content)
  local playerName = Data.userData:GetUserName()
  if playerName ~= nil then
    content = string.gsub(content, "_playername_", playerName)
  end
  return self:__Parse(content, "</?color=?#?%w*>")
end

function PlotPage:__Parse(content, pattern)
  local len = string.len(content)
  local offset = 1
  local color_index = 1
  local text = ""
  local color_begin_index = 1
  local color_begin = false
  local color_end_index = 1
  local color = "none"
  local color_tag_len = 0
  local text = ""
  local split = {}
  local colors = {}
  local text = ""
  while len > offset do
    local startIndex, endIndex = string.find(content, pattern, offset, false)
    if startIndex ~= nil and endIndex ~= nil then
      if color_index == 1 then
        if startIndex ~= 1 then
          color_begin = false
          color_end_index = 1
          color = "none"
        else
          color_begin = true
          color_begin_index = 1
        end
      end
      if color_begin == true then
        table.insert(split, color_begin_index - color_tag_len)
        table.insert(split, startIndex - 1 - color_tag_len)
        text = text .. string.sub(content, color_begin_index, startIndex - 1)
        colors[color_index] = color
      elseif color_index == 1 and startIndex == 1 then
      else
        table.insert(split, color_end_index - color_tag_len)
        table.insert(split, startIndex - 1 - color_tag_len)
        text = text .. string.sub(content, color_end_index, startIndex - 1)
        colors[color_index] = color
      end
      if endIndex - startIndex == 14 then
        color = string.sub(content, startIndex, endIndex)
        color_begin = true
        color_begin_index = endIndex + 1
      else
        color_begin = false
        color_end_index = endIndex + 1
        color = "none"
      end
      color_tag_len = color_tag_len + endIndex + 1 - startIndex
      color_index = color_index + 1
      offset = endIndex
    else
      break
    end
  end
  if offset == 1 then
    offset = 0
  end
  local len_ss = len - color_tag_len - (offset - color_tag_len)
  if 0 < len_ss then
    table.insert(split, len - color_tag_len - len_ss + 1)
    table.insert(split, len - color_tag_len)
    colors[color_index] = "none"
    text = text .. string.sub(content, len - len_ss + 1, len)
  end
  return text, split, colors
end

function PlotPage:GetRichText(cur, text, split, colors)
  local final = ""
  local color_index = 1
  for i = 1, #split, 2 do
    color_index, _ = math.modf((i + 1) / 2)
    if cur <= split[i + 1] then
      if colors[color_index] == "none" then
        final = final .. string.sub(text, split[i], cur)
        break
      end
      if colors[color_index] ~= nil then
        local add_text = string.format(colors[color_index] .. "%s</color>", string.sub(text, split[i], cur))
        final = final .. add_text
      end
      break
    elseif colors[color_index] == "none" then
      final = final .. string.sub(text, split[i], split[i + 1])
    elseif colors[color_index] ~= nil then
      local add_text = string.format(colors[color_index] .. "%s</color>", string.sub(text, split[i], split[i + 1]))
      final = final .. add_text
    end
  end
  return final
end

function PlotPage:_SkipToEnd()
  self.time = -1
  self.clickSkip = true
  self.clickSkipStepIndex = self.curIndex
  local lastIndex = self.curIndex
  local _origin = true
  local _plotStepInfo, choiceNormal, choiceMulti
  while self.curIndex <= #self.tabPlotInfo do
    lastIndex = self.curIndex
    if self.selectiveTree ~= nil then
    else
      for i = lastIndex, #self.tabPlotInfo do
        _plotStepInfo = self.tabPlotInfo[i]
        self.curIndex = i
        if _plotStepInfo.multistep_branch ~= nil and _plotStepInfo.multistep_branch ~= "" then
          self.selectiveTree = Logic.plotLogic:CreateSelectiveTree(self.branch.multistep_branch)
          break
        else
          choiceNormal = Logic.plotLogic:GetPlotBranchOptionOfEnd(_plotStepInfo)
          if choiceNormal ~= nil then
            break
          end
        end
      end
    end
    if self.selectiveTree ~= nil then
      choiceMulti = Logic.plotLogic:GetPlotMultiBranchOptionOfEnd(self.selectiveTree)
      local branchInfo = Logic.plotLogic:GetBranchConfigByID(choiceMulti.info)
      local param = branchInfo.branch_parameter
      if next(param) ~= nil and 1 <= #param then
        if param[1] == BranchParam.SkipPlot then
          self.selectiveTree = nil
          self:_PlotOverImp()
          self.curTriggerId = param[2]
          self:_RetentionPlotStart(param[2])
          self.tabPlotTriggerConf = Logic.plotLogic:GetPlotTriggerConfById(self.curTriggerId)
          local plotId = self.tabPlotTriggerConf.plot_episode_id
          self.tabPlotInfo = Logic.plotLogic:GetPlotInfoByTrigger(plotId)
          self.curIndex = 1
        else
          self.curIndex = self.curIndex + 1
        end
      end
    elseif choiceNormal ~= nil then
      if choiceNormal.Param[1] == BranchParam.SkipPlot then
        self:_PlotOverImp()
        self.curTriggerId = choiceNormal.Param[2]
        self:_RetentionPlotStart(choiceNormal.Param[2])
        self.tabPlotTriggerConf = Logic.plotLogic:GetPlotTriggerConfById(self.curTriggerId)
        local plotId = self.tabPlotTriggerConf.plot_episode_id
        self.tabPlotInfo = Logic.plotLogic:GetPlotInfoByTrigger(self.tabPlotTriggerConf)
        self.curIndex = 1
      else
        self.curIndex = self.curIndex + 1
      end
    else
      self.curIndex = self.curIndex + 1
    end
    if self.curIndex > #self.tabPlotInfo then
      local triggerID = plotManager:CheckPlot(PlotTriggerType.plot_episode_reward, self.curTriggerId)
      if triggerID ~= nil then
        self.curIndex = #self.tabPlotInfo
        self:_PlotOverImp()
        self.curTriggerId = triggerID
        self:_RetentionPlotStart(triggerID)
        self.tabPlotTriggerConf = Logic.plotLogic:GetPlotTriggerConfById(self.curTriggerId)
        local plotId = self.tabPlotTriggerConf.plot_episode_id
        self.tabPlotInfo = Logic.plotLogic:GetPlotInfoByTrigger(self.tabPlotTriggerConf)
        self.curIndex = 1
      end
    end
  end
  self.curIndex = #self.tabPlotInfo
  self:_PlayPlot()
end

function PlotPage:_ShowRewards()
  local rewards = Logic.rewardLogic:FormatRewardById(self.tabPlotTriggerConf.rewards)
  if not isMemoryBattleMode and 0 < #rewards and self:_CheckReward() then
    local params = {
      Rewards = rewards,
      Page = "PlotPage",
      callBack = function()
        self:_RewardClose()
      end
    }
    Logic.rewardLogic:ShowCommonReward(rewards, "PlotPage", function()
      self:_RewardClose()
    end)
  end
end

function PlotPage:_SkipCurrent(currPlotInfo, callBack)
  if plotManager.EditorMode then
    callBack()
  else
    self:_CheckSkipToggle(info, callBack)
  end
end

function PlotPage:_CheckSkipToggle(info, callBack)
  local callBackCancel = function()
    if self.keepAutoPlay == true then
      self:OpenAutoRead()
    end
    self.keepAutoPlay = nil
  end
  local callBackConfirm = function(isOn)
    plotManager:SetToggleSkipTip(isOn)
    callBack()
    if self.keepAutoPlay == true then
      self:OpenAutoRead()
    end
    self.keepAutoPlay = nil
  end
  if info then
    if plotManager:CheckTomorrow() then
      plotManager:SetToggleSkipTip(false)
    end
    local enable = plotManager.toggleSkipTips
    local pass = plotManager:GetReadPassFlag(info.plot_episode_id)
    if pass ~= true then
      if enable and plotManager:CheckToday() then
        callBack()
      else
        self.keepAutoPlay = self.autoPlay
        self:CloseAutoRead()
        noticeManager:ShowSuperNotice(UIHelper.GetString(931001), UIHelper.GetString(931002), true, enable, callBackConfirm, callBackCancel)
      end
    else
      callBack()
    end
  else
    callBack()
  end
end

function PlotPage:_ClickSkipFun()
  if self.triggerOver == true then
    return
  end
  local currPlotInfo = self.tabPlotInfo[self.curIndex]
  self.time = -1
  self.clickSkip = true
  self.clickSkipStepIndex = self.curIndex
  local lastIndex = self.curIndex
  local haveBranch = false
  for i = lastIndex, #self.tabPlotInfo do
    if self.selectiveTree == nil then
      plotManager:Record(self.tabPlotInfo[i])
    end
    if self:_CheckIsHavePlotBranch(i) then
      self.curIndex = i
      haveBranch = true
      break
    elseif lastIndex ~= i then
    end
  end
  if not haveBranch then
    self.curIndex = #self.tabPlotInfo
  end
  local info = self.tabPlotInfo[self.curIndex]
  local callBack = function()
    if currPlotInfo.plot_episode_skip == PlotSkipType.All then
      self:_SkipToEnd()
    elseif not haveBranch then
      self.curIndex = #self.tabPlotInfo
      self:_PlayPlot()
    else
      self:_ShowInfoDir(self.curIndex)
      if self:_CheckReward() then
        self:_GetReward()
      end
    end
  end
  if currPlotInfo ~= nil and currPlotInfo.plot_episode_type == PlotType.Video then
    self._ClickNextFun()
    return
  end
  self:_SkipCurrent(currPlotInfo, callBack)
end

function PlotPage:_PlotOver()
  self.PlotOverInterface()
end

function PlotPage:_PlotOverImp()
  self._PlotOverImprInterface()
end

function PlotPage:_ClickNextImp()
  self:_ShowBlackSwitch(self.tabCurPlotInfo, function()
    self:_PlayPlot()
  end, false)
end

function PlotPage:_CheckPlotIsOver()
  if self.curIndex >= #self.tabPlotInfo then
    local rewards = Logic.rewardLogic:FormatRewardById(self.tabPlotTriggerConf.rewards)
    if 0 < #rewards and self:_CheckReward() then
      local params = {
        Rewards = rewards,
        Page = "PlotPage",
        callBack = function()
          self:_RewardClose()
        end
      }
      Logic.rewardLogic:ShowCommonReward(rewards, "PlotPage", function()
        self:_RewardClose()
      end)
    else
      self:_PlotOver()
    end
    return true
  end
  return false
end

function PlotPage:_RewardClose()
  self:_PlotOver()
end

function PlotPage:_ClickNextFun()
  if self.triggerOver == true then
    return
  end
  if self.lockNextClick then
    return
  end
  if self.plotAutoReadTimer then
    self.plotAutoReadTimer:Stop()
  end
  if self.plotImp ~= nil then
    self.plotImp:ClickNext(function()
      self.time = -1
      if self.plotTimer ~= nil then
        self.plotTimer:Stop()
      end
      if not self:_CheckIsHavePlotBranch(self.curIndex) then
        self:_ClickNextImp()
      elseif self:_CheckReward() then
        self:_GetReward()
      end
    end)
  end
end

function PlotPage:_ShowInfoDir(index)
  local info = self.tabPlotInfo[index]
  self.plotImp = self.plotTypeImp[info.plot_episode_type]
  self:_SetWidgetsActive(info)
  self.plotImp:ShowInfoDir(self.tabPlotInfo, index)
end

function PlotPage:_CheckIsHavePlotBranch(index)
  self.branch = self.tabPlotInfo[index]
  if self.selectiveTree ~= nil then
    return true
  end
  if self.branch.multistep_branch ~= nil and self.branch.multistep_branch ~= "" then
    self.selectiveTree = Logic.plotLogic:CreateSelectiveTree(self.branch.multistep_branch)
    self:_NextBranch(self.selectiveTree)
    return true
  end
  local tabBranch = Logic.plotLogic:SetPlotBranch(self.tabPlotInfo[index])
  if next(tabBranch) ~= nil then
    self:_CreateBranchInfo(tabBranch)
    return true
  end
  return false
end

function PlotPage:_GetReward()
end

function PlotPage:_CreateBranchInfo(tabBranch)
  self.m_tabWidgets.over_mask:SetActive(true)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_branchItem, self.m_tabWidgets.trans_branchContent, #tabBranch, function(nIndex, tabPart)
    tabPart.txt_name.text = tabBranch[nIndex].Name
    UIHelper.SetImage(tabPart.im_bg, "uipic_ui_story_bu_xuanzhong")
    local param = tabBranch[nIndex].Param
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item.gameObject, function()
      UIHelper.SetImage(tabPart.im_bg, "uipic_ui_story_bu_weixuanzhong")
      self.m_tabWidgets.over_mask:SetActive(false)
      if param[1] == BranchParam.SkipPlot then
        UIHelper.SetImage(tabPart.im_bg, "uipic_ui_story_bu_xuanzhong")
        self:_SkipPlotImp(param[2])
      else
        self:_PlayPlot()
      end
      plotManager:RecordBranch(self.branch.plot_episode_step_id, nIndex)
    end)
  end)
end

function PlotPage:_NextBranch(node)
  self:_CreateSelectionItem(node)
end

function PlotPage:_CreateSelectionItem(node)
  self.m_tabWidgets.over_mask:SetActive(true)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_branchItem, self.m_tabWidgets.trans_branchContent, #node.child, function(nIndex, tabPart)
    local branchNode = node.child[nIndex]
    local branchInfo = Logic.plotLogic:GetBranchConfigByID(branchNode.info)
    tabPart.txt_name.text = branchInfo.branch_content
    UIHelper.SetImage(tabPart.im_bg, "uipic_ui_story_bu_xuanzhong")
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item.gameObject, function()
      local param = branchInfo.branch_parameter
      UIHelper.SetImage(tabPart.im_bg, "uipic_ui_story_bu_weixuanzhong")
      self.m_tabWidgets.over_mask:SetActive(false)
      if param ~= nil then
      end
      if param[1] == BranchParam.SkipPlot then
        UIHelper.SetImage(tabPart.im_bg, "uipic_ui_story_bu_xuanzhong")
        self.selectiveTree = nil
        self:_SkipPlotImp(param[2])
      elseif branchNode.child ~= nil and #branchNode.child > 0 then
        self:_NextBranch(branchNode)
      else
        self.selectiveTree = nil
        self:_PlayPlot()
      end
      plotManager:RecordBranch(self.branch.plot_episode_step_id, nIndex)
    end)
  end)
end

function PlotPage:_SkipPlotImp(id)
  self:_PlotOverImp()
  self.curTriggerId = id
  self:_RetentionPlotStart(id)
  self:InitData()
  self:_PlayPlot()
end

function PlotPage:_RetentionPlotEnd(skip, id, stepId)
  local skipType = skip and 1 or 0
  local dotUIInfo = {
    info = "ui_story_end",
    type = skipType,
    plot_id = id,
    step_id = stepId
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotUIInfo)
end

function PlotPage:_RetentionPlotStart(id)
  local dotUIInfo = {
    info = "ui_story_begin",
    plot_id = id
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotUIInfo)
end

function PlotPage:DoOnHide()
end

function PlotPage:DoOnClose()
  self.triggerOver = true
  if self.whiteToBlackTimer ~= nil then
    self.whiteToBlackTimer:Stop()
  end
  for k, v in pairs(self.plotTypeImp) do
    v:Destroy()
  end
  self.time = nil
  if self.plotTimer ~= nil then
    self.plotTimer:Stop()
  end
  UIHelper.ClosePage("BarragePage")
  self.autoPlay = false
  if self.plotAutoReadTimer then
    self.plotAutoReadTimer:Stop()
  end
  plotManager:MarryEndBefore()
  if self.param.callback then
    self.param.callback()
  end
  GR.luaInteraction:clearUnusedRes()
end

function PlotPage:OpenMemoirsPage()
  self.memoirsPage:DoOnOpen()
  self.m_tabWidgets.btn_root:SetActive(false)
  self.tab_Widgets.obj_barrage:SetActive(false)
  self:OnBarrageClose()
end

function PlotPage:CloseMemoirsPage()
  self.memoirsPage:DoOnHide()
  self.m_tabWidgets.btn_root:SetActive(true)
  local info = self.tabPlotInfo[self.curIndex]
  self.tab_Widgets.obj_barrage:SetActive(info.barrage_ctrl == 1)
end

function PlotPage:_PlayExchangeMusic(plotInfo)
  local audioinfo = Logic.plotLogic:GetPlotAudioInfoConfigById(plotInfo.plot_episode_step_id, plotInfo.plot_episode_id)
  if audioinfo ~= nil and conditionCheckManager:Checkvalid(audioinfo.exchange_music) and not plotManager.MuteExchangedMusic then
    local effects = string.split(audioinfo.exchange_music, ",")
    local count = 0
    if 0 < #effects then
      for _, e in ipairs(effects) do
        count = count + 1
        if 1 < count then
          SoundManager.Instance:PlayAudio(e)
        else
          SoundManager.Instance:PlayMusic(e)
        end
      end
    end
    Logic.plotMaker.exchange_music = audioinfo.exchange_music
  end
  SoundManager.Instance:PlayAudio("reset_timeup")
end

function PlotPage:DoOnOpenForEditor()
  Logic.plotMaker.plotPage = self
end

function PlotPage:Play(config)
  self.time = -1
  self.autoReadTime = -1
  self.m_tabWidgets.im_changePlot.gameObject:SetActive(false)
  self.nfontSpeed = configManager.GetDataById("config_parameter", 74).value / 1000
  self:InitDataForEditor(config)
  self:_PlayPlot()
  if self.plotTimer ~= nil then
    self.plotTimer:Stop()
  end
end

function PlotPage:InitDataForEditor(config)
  self:UnloadloadEffects()
  self.tabPlotInfo = config
  self.curIndex = 0
  if self.plotImp then
    self.plotImp:InitData()
  end
  self.playTimes = 0
  self.plotImp = nil
  self.m_tabWidgets.over_mask:SetActive(false)
  self:PreloadCV()
end

function PlotPage:_CheckPlotIsOverForEditor()
  if self.curIndex >= #self.tabPlotInfo then
    self:_PlotOverForEditor()
    return true
  end
  return false
end

function PlotPage:_PlotOverForEditor()
  self:_PlotOverImpForEditor()
end

function PlotPage:_PlotOverImpForEditor()
  local info = self.tabPlotInfo[self.curIndex]
  log("\229\137\167\230\131\133\230\146\173\230\148\190\229\174\140\230\175\149\239\188\140 \230\156\128\229\144\142\228\184\128\230\173\165==" .. info.plot_episode_step_id)
  local audioinfo = Logic.plotLogic:GetPlotAudioInfoConfigById(info.plot_episode_step_id, info.plot_episode_id)
  self:_PlayExchangeMusic(info)
end

function PlotPage:DoOnOpenForGame()
  self.time = -1
  self.autoReadTime = -1
  self.triggerOver = false
  if self.plotTimer ~= nil then
    self.plotTimer:Stop()
  end
  self.m_tabWidgets.im_changePlot.gameObject:SetActive(false)
  self.nfontSpeed = configManager.GetDataById("config_parameter", 74).value / 1000
  self.curTriggerId = self.param.PlotTriggerId
  self:InitData()
  self:_RetentionPlotStart(self.curTriggerId)
  self:_PlayPlot()
  self:InitBarrage()
end

function PlotPage:_CheckPlotIsOverForGame()
  local battleMode = self.param.battleMode or BattleMode.Normal
  logDebug("battleMode", battleMode)
  local isMemoryBattleMode = battleMode == BattleMode.Memory
  if self.curIndex >= #self.tabPlotInfo then
    local rewards = Logic.rewardLogic:FormatRewardById(self.tabPlotTriggerConf.rewards)
    if not isMemoryBattleMode and 0 < #rewards and self:_CheckReward() then
      local params = {
        Rewards = rewards,
        Page = "PlotPage",
        callBack = function()
          self:_RewardClose()
        end
      }
      Logic.rewardLogic:ShowCommonReward(rewards, "PlotPage", function()
        self:_RewardClose()
      end)
    else
      self:_PlotOver()
    end
    return true
  end
  return false
end

function PlotPage:_PlotOverForGame()
  local triggerID = plotManager:CheckPlot(PlotTriggerType.plot_episode_reward, self.curTriggerId)
  if triggerID then
    self:_SkipPlotImp(triggerID)
  else
    if self.plotOverTime ~= nil then
      self.plotOverTime:Stop()
    end
    if self.delayPlayAudioTimer ~= nil then
      self.delayPlayAudioTimer:Stop()
    end
    self.plotOverTime = FrameTimer.New(function()
      self:_PlotOverImp()
    end, 0, 0)
    self.plotOverTime:Start()
    UIHelper.Back()
  end
end

function PlotPage:InitDataForGame()
  self.tabPlotTriggerConf = Logic.plotLogic:GetPlotTriggerConfById(self.curTriggerId)
  local plotId = self.tabPlotTriggerConf.plot_episode_id
  self.tabPlotInfo = Logic.plotLogic:GetPlotInfoByTrigger(self.tabPlotTriggerConf)
  self.curIndex = 0
  if self.plotImp then
    self.plotImp:InitData()
  end
  self.plotImp = nil
  self.m_tabWidgets.over_mask:SetActive(false)
  self:PreloadCV()
  self:PreloadEffects()
  self.playTimes = 0
end

function PlotPage:GetScreenEffect(plotInfo)
  if self.preScreenEffects == nil then
    self.preScreenEffects = {}
  end
  if self.preScreenEffects[plotInfo.screen_effect] == nil then
    local effectObj = self:CreateUIEffect(plotInfo.screen_effect)
    effectObj:AddComponent(UISortEffectComponent.GetClassType())
    effectObj.transform.position = Vector3.New(0, 0, 0)
    effectObj.gameObject:SetActive(false)
    self.preScreenEffects[plotInfo.screen_effect] = effectObj
  end
  return self.preScreenEffects[plotInfo.screen_effect]
end

function PlotPage:PreloadEffects()
  self.preScreenEffects = {}
  for i = 1, #self.tabPlotInfo do
    local plotInfo = self.tabPlotInfo[i]
    if plotInfo ~= nil and conditionCheckManager:Checkvalid(plotInfo.screen_effect) and self.preScreenEffects[plotInfo.screen_effect] == nil then
      local effectObj = self:CreateUIEffect(plotInfo.screen_effect)
      effectObj:AddComponent(UISortEffectComponent.GetClassType())
      effectObj.transform.position = Vector3.New(0, 0, 0)
      effectObj.gameObject:SetActive(false)
      self.preScreenEffects[plotInfo.screen_effect] = effectObj
    end
  end
end

function PlotPage:UnloadloadEffects()
  if self.preScreenEffects == nil then
    self.preScreenEffects = {}
  end
  for k, v in pairs(self.preScreenEffects) do
    v.gameObject:SetActive(false)
  end
end

function PlotPage:PreloadCV()
  self.audioPreload = nil
  local firstinfo = self.tabPlotInfo[1]
  if firstinfo ~= nil then
    self.audioPreload = Logic.plotLogic:GetPlotAudioInfoConfigById(firstinfo.plot_episode_step_id, firstinfo.plot_episode_id)
    if self.audioPreload ~= nil and self.audioPreload.preload ~= nil and self.audioPreload.preload ~= "" then
      CS.SoundManager.Instance:PreLoad(self.audioPreload.preload)
    end
  end
end

function PlotPage:UnloadCV()
  if self.audioPreload ~= nil and self.audioPreload.preload ~= nil and self.audioPreload.preload ~= "" then
    CS.SoundManager.Instance:UnLoad(self.audioPreload.preload)
  end
end

function PlotPage:_PlotOverImpForGame()
  self:UnloadCV()
  local info = self.tabPlotInfo[self.curIndex]
  local audioinfo = Logic.plotLogic:GetPlotAudioInfoConfigById(info.plot_episode_step_id, info.plot_episode_id)
  self:_PlayExchangeMusic(info)
  if not self.clickSkipStepIndex then
    self.clickSkipStepIndex = self.curIndex
  end
  local skipInfo = self.tabPlotInfo[self.clickSkipStepIndex]
  self:_RetentionPlotEnd(self.clickSkip, self.curTriggerId, skipInfo.plot_episode_step_id)
  self.clickSkip = false
  self.clickSkipStepIndex = nil
  if self.playTimes == #self.tabPlotInfo then
    plotManager:SetReadPassFlag(self.tabPlotInfo[self.playTimes].plot_episode_id)
  end
  if plotManager.EditorMode then
    log("\229\189\147\229\137\141\229\164\132\228\186\142\231\188\150\232\190\145\230\168\161\229\188\143")
    return
  end
  plotManager:PlotEnd(self.curTriggerId)
  local battleMode = self.param.battleMode or BattleMode.Normal
  logDebug("battleMode", battleMode)
  if battleMode ~= BattleMode.Memory then
    Data.guideData:SetPlotId(self.curTriggerId)
    Service.guideService:SendPlotReward(self.curTriggerId)
  end
end

return PlotPage
