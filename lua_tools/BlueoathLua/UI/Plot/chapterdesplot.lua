local ChapterDesPlot = class("UI.Plot.ChapterDesPlot")

function ChapterDesPlot:initialize(parent, tabWidget)
  self.m_tabWidget = tabWidget
  self.parent = parent
  self.printTimer = nil
  self.tabParts = nil
  self.plotTab = nil
  self.plotCount = 0
end

function ChapterDesPlot:PlayPlot(plotTab, index)
  self.plotTab = plotTab
  self.curPlotInfo = plotTab[index]
  local plotInfo = self.curPlotInfo
  self.tabParts = {}
  self.contentObj = nil
  self.plotCount = self.plotCount + 1
  local diff = index - self.plotCount
  UIHelper.CreateSubPart(self.m_tabWidget.obj_desItem, self.m_tabWidget.trans_desContent, self.plotCount, function(nIndex, tabPart)
    tabPart.txt_des.text = ""
    if nIndex == self.plotCount then
      self.contentObj = tabPart.txt_des
    else
      tabPart.txt_des.text = self.plotTab[nIndex + diff].content
      tabPart.txt_des.fontSize = self.plotTab[nIndex + diff].text_size
    end
    table.insert(self.tabParts, tabPart)
  end)
  self.contentObj.text = ""
  self.contentObj.fontSize = plotInfo.text_size
  self:_StopPrintTimer()
  local curIndex = 1
  local sample_text, split_text, colors = self.parent:Parse(plotInfo.content)
  local strLen = utf8.len(sample_text)
  local showTextContent = function()
    curIndex = curIndex + 1
    local curbyteIndex = utf8.byte_index(sample_text, curIndex)
    if curbyteIndex == nil then
      self:_StopPrintTimer()
      curIndex = 1
    else
      self.contentObj.text = self.parent:GetRichText(curIndex, sample_text, split_text, colors)
      if curIndex > strLen then
        self:_StopPrintTimer()
        curIndex = 1
      end
    end
  end
  self.printTimer = Timer.New(showTextContent, self.parent.nfontSpeed, strLen, false)
  self.printTimer:Start()
end

function ChapterDesPlot:_StopPrintTimer()
  if self.printTimer then
    self.printTimer:Stop()
    self.printTimer = nil
  end
end

function ChapterDesPlot:ClickNext(callBack)
  if self.printTimer and self.printTimer.running then
    self:_StopPrintTimer()
    self.contentObj.text = self.curPlotInfo.content
  else
    callBack()
  end
end

function ChapterDesPlot:ShowInfoDir(plotTab, index)
  if self.printTimer ~= nil then
    self:_StopPrintTimer()
  end
  self:_ShowAllChapterPlot(index)
end

function ChapterDesPlot:_ShowAllChapterPlot(index)
  self.tabParts = {}
  self.tabChapter = {}
  for i = index, 1, -1 do
    if self.plotTab[i].plot_episode_type == PlotType.ChapterDes then
      table.insert(self.tabChapter, self.tabPlotInfo[i])
    else
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

function ChapterDesPlot:InitData()
  self.plotCount = 0
  if self.tabParts then
    for k, v in pairs(self.tabParts) do
      v.gameObject:SetActive(false)
    end
    self.tabParts = nil
  end
end

function ChapterDesPlot:Destroy()
  self:_StopPrintTimer()
end

return ChapterDesPlot
