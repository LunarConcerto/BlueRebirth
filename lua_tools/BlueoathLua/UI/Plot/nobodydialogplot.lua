local NobodyDialogPlot = class("UI.Plot.NobodyDialogPlot")

function NobodyDialogPlot:initialize(parent, tabWidget)
  self.m_tabWidget = tabWidget
  self.parent = parent
  self.printTimer = nil
end

function NobodyDialogPlot:PlayPlot(plotTab, index)
  self.plotTab = plotTab
  self.curPlotInfo = plotTab[index]
  local plotInfo = self.curPlotInfo
  local preIndex = 0
  if plotInfo.cut_scentence == 1 then
    if self.tabParts then
      for k, v in pairs(self.tabParts) do
        v.gameObject:SetActive(false)
      end
    end
    if 1 < index then
      preIndex = index - 1
    end
  else
    for i = index, 1, -1 do
      if plotTab[i].cut_scentence == 1 then
        preIndex = i - 1
        break
      end
    end
  end
  self.tabParts = {}
  self.contentObj = nil
  UIHelper.CreateSubPart(self.m_tabWidget.obj_desItem, self.m_tabWidget.trans_desContent, index - preIndex, function(nIndex, tabPart)
    tabPart.txt_des.text = ""
    if nIndex == index - preIndex then
      self.contentObj = tabPart.txt_des
    else
      tabPart.txt_des.text = self.plotTab[nIndex + preIndex].content
      tabPart.txt_des.fontSize = self.plotTab[nIndex + preIndex].text_size
    end
    table.insert(self.tabParts, tabPart)
  end)
  self.contentObj.text = ""
  self.contentObj.fontSize = plotInfo.text_size
  self:_StopPrintTimer()
  local curIndex = 1
  local contentTab = self.parent:GetContent(plotInfo.content)
  local strLen = utf8.len(contentTab.content)
  local showTextContent = function()
    curIndex = curIndex + 1
    self.contentObj.text = string.format(contentTab.color, utf8.sub(contentTab.content, 1, curIndex))
    if curIndex > strLen then
      self:_StopPrintTimer()
      curIndex = 1
    end
  end
  self.printTimer = Timer.New(showTextContent, self.parent.nfontSpeed, strLen, false)
  self.printTimer:Start()
  self:_PlayAudio(plotInfo)
end

function NobodyDialogPlot:_StopPrintTimer()
  if self.printTimer then
    self.printTimer:Stop()
    self.printTimer = nil
  end
end

function NobodyDialogPlot:InitData()
  if self.tabParts then
    for k, v in pairs(self.tabParts) do
      v.gameObject:SetActive(false)
    end
    self.tabParts = nil
  end
end

function NobodyDialogPlot:ClickNext(callBack)
  if self.printTimer and self.printTimer.running then
    self:_StopPrintTimer()
    self.contentObj.text = self.curPlotInfo.content
  else
    callBack()
  end
end

function NobodyDialogPlot:ShowInfoDir(plotInfo, index)
  if self.printTimer ~= nil then
    self:_StopPrintTimer()
  end
  self:_ShowAllChapterPlot(index)
end

function NobodyDialogPlot:_ShowAllChapterPlot(index)
  self.tabParts = {}
  self.tabChapter = {}
  for i = index, 1, -1 do
    if self.plotTab[i].plot_episode_type == PlotType.NobodyDialog and self.plotTab[i].cut_scentence ~= 1 then
      table.insert(self.tabChapter, self.plotTab[i])
    else
      if self.plotTab[i].plot_episode_type == PlotType.NobodyDialog then
        table.insert(self.tabChapter, self.plotTab[i])
      end
      break
    end
  end
  if #self.tabChapter < 1 then
    return
  end
  table.sort(self.tabChapter, function(a, b)
    return a.step < b.step
  end)
  UIHelper.CreateSubPart(self.m_tabWidget.obj_desItem, self.m_tabWidget.trans_desContent, #self.tabChapter, function(nIndex, tabPart)
    tabPart.txt_des.fontSize = self.tabChapter[nIndex].text_size
    tabPart.txt_des.text = self.tabChapter[nIndex].content
    table.insert(self.tabParts, tabPart)
  end)
end

function NobodyDialogPlot:Destroy()
  self:_StopPrintTimer()
end

function NobodyDialogPlot:_PlayAudio(plotInfo)
  local audioinfo = Logic.plotLogic:GetPlotAudioInfoConfigById(plotInfo.plot_episode_step_id, plotInfo.plot_episode_id)
  if conditionCheckManager:Checkvalid(audioinfo.audio_effect) and not plotManager.MuteEffect then
    local effects = string.split(audioinfo.audio_effect, ",")
    if 0 < #effects then
      for _, e in ipairs(effects) do
        SoundManager.Instance:PlayAudio(e)
      end
    end
    Logic.plotMaker.audio_effect = audioinfo.audio_effect
  end
end

return NobodyDialogPlot
