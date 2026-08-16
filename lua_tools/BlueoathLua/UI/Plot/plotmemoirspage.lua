local PlotMemoirsPage = class("UI.Plot.PlotMemoirsPage")

function PlotMemoirsPage:initialize(parent, tabWidgets)
  self.m_tabWidgets = tabWidgets
  self.parent = parent
  self.m_minMsgItemHeight = 130
end

function PlotMemoirsPage:DoOnOpen()
  self.parent:OpenTopPage("PlotMemoirsPage", TopPageType.User, UIHelper.GetString(931005), self, true, function()
    self.parent:CloseMemoirsPage()
  end)
  self.lastaudio_id = nil
  self.barrageOpen = self.parent.barrageOpen
  self.autoPlay = self.parent.autoPlay
  if self.autoPlay == true then
    self.parent:CloseAutoRead()
  end
  if self.parent.last_audio_ID ~= nil and self.parent.last_audio_ID ~= "" then
    SoundManager.Instance:StopAudio(self.parent.last_audio_ID)
  end
  self.m_tabWidgets.memoirs_root:SetActive(true)
  self.cachedHeigh = {}
  local records = plotManager:GetRecords()
  self.records = {}
  for i = 1, #records - 1 do
    if records[i].plot_episode_type ~= PlotType.Video then
      table.insert(self.records, records[i])
    end
  end
  self.brancHistory = plotManager:GetBranchRecords()
  self:_LoadPlotList(self.m_tabWidgets.tableview, self.m_tabWidgets.obj_plotItem, self.m_tabWidgets.sbar_plot, self.records)
end

function PlotMemoirsPage:DoOnHide()
  self.parent:CloseTopPage()
  if not IsNil(self.m_tabWidgets.memoirs_root) then
    self.m_tabWidgets.memoirs_root:SetActive(false)
    if self.autoPlay == true then
      self.parent:OpenAutoRead()
    end
    self:HidePlayImage()
    self.currPlay = nil
    if self.plotAudioTimer ~= nil then
      self.plotAudioTimer:Stop()
    end
    self:UnloadAudioRes()
    self.parent:PreloadCV()
    if self.barrageOpen == true then
      self.parent:OnBarrageOpen()
    end
    if self.lastaudio_id ~= nil then
      SoundManager.Instance:StopAudio(self.lastaudio_id)
    end
  end
end

function PlotMemoirsPage:_LoadPlotList(tableview, obj, sbar, tabPlotList)
  if tabPlotList == nil or #tabPlotList == 0 then
    return
  end
  UIHelper.SetTableViewParam(tableview, obj, #tabPlotList, self.m_minMsgItemHeight, function(index, luaPart)
    self:_FillMsgItem(index, luaPart, tabPlotList)
  end, function(index)
    return self:_GetMsgItemHeight(index, tabPlotList[index])
  end)
end

function PlotMemoirsPage:_GetMsgItemHeight(index, msgData)
  local indicator = self.m_tabWidgets.txt_indicator
  indicator.NoImage = true
  local content = self:GetTalkerContent(msgData, index)
  UIHelper.SetText(indicator, content)
  local startPosY = indicator.rectTransform.anchoredPosition.y
  local text_h = indicator:CalculateLineHeight()
  local extend_h = math.abs(2 * startPosY - text_h)
  return math.max(extend_h, self.m_minMsgItemHeight)
end

function PlotMemoirsPage:_FillMsgItem(index, luaPart, tabPlotList)
  luaPart.talker_content.NoImage = false
  luaPart.gameObject.name = "item" .. tostring(index)
  luaPart.talker_content:SetHrefClickAction(function(param, id)
    self:PlayAudio(self.records[index], luaPart, index)
  end)
  luaPart.talker_content:SetClickAction(function(uid)
    self:PlayAudio(self.records[index], luaPart, index)
  end)
  local info = tabPlotList[index]
  local talkerName = self:GetTalkerName(info)
  local content = self:GetTalkerContent(info, index)
  UIHelper.SetText(luaPart.talker_name, talkerName)
  UIHelper.SetText(luaPart.talker_content, content)
  luaPart.talker_content.UID = index
  self:HideAnimation(luaPart)
  if self.currPlay ~= nil and self.currPlay == index then
    self:ShowPlayAnimation(luaPart)
  end
  local indicator = self.m_tabWidgets.txt_indicator
  UIHelper.SetText(indicator, content)
  local startPosY = indicator.rectTransform.anchoredPosition.y
  local text_h = indicator:CalculateLineHeight()
  local extend_h = math.abs(2 * startPosY - text_h)
  extend_h = math.max(extend_h, self.m_minMsgItemHeight)
  local pos = luaPart.talker_border.rectTransform.anchoredPosition
  pos.y = -1 * extend_h + luaPart.talker_border.rectTransform.sizeDelta.y
  luaPart.talker_border.rectTransform.anchoredPosition = pos
  local sizeDelta = luaPart.talker_border.rectTransform.sizeDelta
  sizeDelta.y = extend_h
  luaPart.talker_bk.rectTransform.sizeDelta = sizeDelta
  sizeDelta = luaPart.talker_content.rectTransform.sizeDelta
  sizeDelta.y = text_h
  luaPart.talker_content.rectTransform.sizeDelta = sizeDelta
end

function PlotMemoirsPage:GetTalkerName(info)
  if info.talker_name ~= nil and info.talker_name ~= "" then
    return string.format("<i><color=#5e718a>%s:</color></i>", self.parent:GetAllRichContent(info.talker_name))
  end
  return info.talker_name
end

function PlotMemoirsPage:GetTalkerContent(info, index)
  local text = ""
  local content = self.parent:GetAllRichContent(info.content)
  if self:CheckAudioRes(info) == true then
    text = string.format("<color=#a9bbcc>%s  [#%s:%d]</color>", content, "uipic_ui_story_bu_yuyinbofang_01", index)
  else
    text = string.format("<color=#a9bbcc>%s</color>", content)
  end
  local branchText = self.parent:GetAllRichContent(self:GetPlotBranchText(info))
  text = text .. branchText
  return text
end

function PlotMemoirsPage:CheckValid(audio)
end

function PlotMemoirsPage:PlayAudio(info, luaPart, index)
  if not self:CheckAudioRes(info) then
    return
  end
  local audio = self:LoadAudioRes(info)
  if audio ~= nil and conditionCheckManager:Checkvalid(audio.audio_id) and (self.currPlay == nil or self.currPlay ~= index) then
    SoundManager.Instance:PlayAudio(audio.audio_id)
    self.lastaudio_id = audio.audio_id
    local time = SoundManager.Instance:GetSoundDuration(audio.audio_id)
    if self.plotAudioTimer ~= nil then
      self:HidePlayImage()
      self.plotAudioTimer:Stop()
      self.currPlay = nil
    end
    self.plotAudioTimer = Timer.New(function()
      self:HidePlayImage()
      self.currPlay = nil
    end, time, -1, false)
    self.plotAudioTimer:Start()
    self.currPlay = index
    self:ShowPlayAnimation(luaPart)
  end
end

function PlotMemoirsPage:HidePlayImage()
  if self.currPlay ~= nil then
    local part = self.m_tabWidgets.tex_container:Find(string.format("item%d/tx_content/ImageElem/animation", self.currPlay))
    if part ~= nil then
      self.m_tabWidgets.playcv_animation:SetActive(false)
      self.m_tabWidgets.playcv_animation.transform:SetParent(self.m_tabWidgets.tex_container)
    end
    local part2 = self.m_tabWidgets.tex_container:Find(string.format("item%d/tx_content/ImageElem", self.currPlay))
    if part2 ~= nil then
      part2.gameObject:GetComponent(UIImage.GetClassType()).enabled = true
    end
  end
end

function PlotMemoirsPage:HideAnimation(luaPart)
  local part = luaPart.talker_content.transform:Find("ImageElem/animation")
  if part ~= nil then
    self.m_tabWidgets.playcv_animation:SetActive(false)
    self.m_tabWidgets.playcv_animation.transform:SetParent(self.m_tabWidgets.tex_container)
  end
end

function PlotMemoirsPage:ShowPlayImage()
  if self.currPlay ~= nil then
    local part = self.m_tabWidgets.tex_container:Find(string.format("item%d/tx_content/ImageElem", self.currPlay))
    if part ~= nil then
      self.m_tabWidgets.playcv_animation.transform:SetParent(part)
      self.m_tabWidgets.playcv_animation.transform.localPosition = Vector3.zero
      self.m_tabWidgets.playcv_animation.transform.localScale = Vector3.one
      self.m_tabWidgets.playcv_animation.transform.localRotation = Quaternion.identity
      self.m_tabWidgets.playcv_animation:SetActive(true)
      part.gameObject:GetComponent(UIImage.GetClassType()).enabled = false
    end
  end
end

function PlotMemoirsPage:ShowPlayAnimation(luaPart)
  if self.currPlay ~= nil then
    local part = luaPart.talker_content.transform:Find("ImageElem")
    if part ~= nil then
      self.m_tabWidgets.playcv_animation.transform:SetParent(part)
      self.m_tabWidgets.playcv_animation.transform.localPosition = Vector3.zero
      self.m_tabWidgets.playcv_animation.transform.localScale = Vector3.one
      self.m_tabWidgets.playcv_animation.transform.localRotation = Quaternion.identity
      self.m_tabWidgets.playcv_animation:SetActive(true)
      part.gameObject:GetComponent(UIImage.GetClassType()).enabled = false
    end
  end
end

function PlotMemoirsPage:LoadAudioRes(plotinfo)
  local audio = Logic.plotLogic:GetPlotAudioInfoConfigById(plotinfo.plot_episode_step_id, plotinfo.plot_episode_id)
  if audio ~= nil and audio.preload ~= nil and audio.preload ~= "" then
    if self.preloadRes == nil then
      self.preloadRes = {}
    end
    local need = true
    for k, v in pairs(self.preloadRes) do
      if v == audio.preload then
        need = false
        break
      end
    end
    if need == true then
      CS.SoundManager.Instance:PreLoad(audio.preload)
      table.insert(self.preloadRes, audio.preload)
    end
    return audio
  end
  return nil
end

function PlotMemoirsPage:CheckAudioRes(plotinfo)
  local audio = Logic.plotLogic:GetPlotAudioInfoConfigById(plotinfo.plot_episode_step_id, plotinfo.plot_episode_id)
  if audio ~= nil and audio.audio_id ~= nil and audio.audio_id ~= "" and string.sub(audio.audio_id, -string.len("silence")) ~= "silence" then
    return true
  end
  return false
end

function PlotMemoirsPage:UnloadAudioRes()
  if self.preloadRes == nil then
    self.preloadRes = {}
  end
  local need = true
  for k, v in pairs(self.preloadRes) do
    CS.SoundManager.Instance:UnLoad(v)
  end
  self.preloadRes = {}
end

function PlotMemoirsPage:GetPlotBranchText(plotInfo)
  local text = ""
  local his = self.brancHistory[plotInfo.plot_episode_step_id]
  if his == nil then
    return text
  end
  if plotInfo.multistep_branch ~= nil and plotInfo.multistep_branch ~= "" then
    local selectiveTree = Logic.plotLogic:CreateSelectiveTree(plotInfo.multistep_branch)
    if selectiveTree.child == nil then
      return text
    end
    text = text .. "\n"
    for i = 1, #his do
      selectiveTree = selectiveTree.child[his[i]]
      if selectiveTree ~= nil then
        local branchInfo = Logic.plotLogic:GetBranchConfigByID(selectiveTree.info)
        text = text .. string.format("  <i><color=#417ae3>%s </color></i>", branchInfo.branch_content)
        if selectiveTree.child ~= nil then
          text = text .. "\n"
        else
          break
        end
      else
        break
      end
    end
  else
    local tabBranch = Logic.plotLogic:SetPlotBranch(plotInfo)
    local selected = his[1]
    if 0 < #tabBranch then
      text = text .. "\n"
    end
    for k = 1, #tabBranch do
      if selected == k then
        text = text .. string.format("  <i><color=#417ae3>%s </color></i>", tabBranch[k].Name)
      end
    end
  end
  return text
end

function PlotMemoirsPage:Create()
end

function PlotMemoirsPage:Destroy()
end

return PlotMemoirsPage
