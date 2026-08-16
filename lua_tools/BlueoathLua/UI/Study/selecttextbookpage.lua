local m = class("UI.Study.SelectTextbookPage", require("ui.page.SelectBasePage"))
local super = m.super
local SelectTextbookItem = require("ui.page.Study.SelectTextbookItem")
m.TestDisplayData = {
  textbookDisplayInfo = {
    {
      bookId = 70000,
      bookName = "\230\148\187\229\135\187\230\149\153\230\157\144",
      bookIcon = "",
      bookNum = 10,
      bookExp = 150,
      bookDesc = "\230\148\187\229\135\187\230\138\128\232\131\189\230\149\153\230\157\144\229\136\157\231\186\167,\231\148\168\228\186\142\232\174\173\231\187\131\230\136\152\229\167\172,xx\230\138\128\232\131\189\229\143\175\228\187\165\232\142\183\229\190\151\233\162\157\229\164\150\231\187\143\233\170\140",
      bookCostTime = 20000,
      spExp = true
    },
    {
      bookId = 70000,
      bookName = "\230\148\187\229\135\187\230\149\153\230\157\144",
      bookIcon = "",
      bookNum = 10,
      bookExp = 150,
      bookDesc = "\230\148\187\229\135\187\230\138\128\232\131\189\230\149\153\230\157\144\229\136\157\231\186\167,\231\148\168\228\186\142\232\174\173\231\187\131\230\136\152\229\167\172,xx\230\138\128\232\131\189\229\143\175\228\187\165\232\142\183\229\190\151\233\162\157\229\164\150\231\187\143\233\170\140",
      bookCostTime = 20000,
      spExp = true
    },
    {
      bookId = 70000,
      bookName = "\230\148\187\229\135\187\230\149\153\230\157\144",
      bookIcon = "",
      bookNum = 10,
      bookExp = 150,
      bookDesc = "\230\148\187\229\135\187\230\138\128\232\131\189\230\149\153\230\157\144\229\136\157\231\186\167,\231\148\168\228\186\142\232\174\173\231\187\131\230\136\152\229\167\172,xx\230\138\128\232\131\189\229\143\175\228\187\165\232\142\183\229\190\151\233\162\157\229\164\150\231\187\143\233\170\140",
      bookCostTime = 20000,
      spExp = true
    }
  }
}

function m:DoInit()
  self.m_tabWidgets = nil
  self.m_itemArr = {}
end

function m:SetData(data)
  self.m_maxSelectNum = 1
  self.m_selectableGroup = data.textbookDisplayInfo
  self.m_filterAndSortGroup = {}
  table.insertto(self.m_filterAndSortGroup, self.m_selectableGroup, 1)
  table.sort(self.m_filterAndSortGroup, function(a, b)
    if a.quality ~= b.quality then
      return a.quality > b.quality
    else
      return a.bookId < b.bookId
    end
  end)
  self.m_selectedMap = {}
  self.m_selectedMap[self.m_filterAndSortGroup[1]] = true
  self.itemClass = SelectTextbookItem
end

function m:DisplayItemList()
  super.DisplayItemList(self)
  local widgets = self:GetWidgets()
  widgets.togGroup_item:SetActiveToggleIndex(0)
end

function m:RegisterUIEvent()
  local widgets = self:GetWidgets()
  widgets.togGroup_item:RegisterActiveToggleChange(function()
    self:DisplaySelectExtra()
  end)
  UGUIEventListener.AddButtonOnClick(widgets.btn_confirm, self._OnConfirm, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._OnClose, self)
end

function m.GenDisplayData(textbookArr, pskillId)
  local data = {}
  data.textbookDisplayInfo = {}
  for i, textbook in ipairs(textbookArr) do
    local info = {}
    info.bookName = Logic.studyLogic:GetTextBookName(textbook.templateId)
    info.quality = Logic.studyLogic:GetTextBookQuality(textbook.templateId)
    info.bookCostTime = Logic.studyLogic:GetTextBookDuration(textbook.templateId)
    info.bookDesc = Logic.studyLogic:GetTextBookDesc(textbook.templateId)
    info.bookExp, info.expRatio = Logic.studyLogic:GetTextBookExp(textbook.templateId, pskillId)
    info.bookNum = textbook.num
    info.bookIcon = Logic.studyLogic:GetTextBookIcon(textbook.templateId)
    info.bookId = textbook.templateId
    info.spExp = info.expRatio > 1
    table.insert(data.textbookDisplayInfo, info)
  end
  return data
end

function m:DisplaySelectExtra()
  local widgets = self:GetWidgets()
  local info, _ = next(self.m_selectedMap)
  widgets.obj_selectInfo:SetActive(info ~= nil)
  if info ~= nil then
    UIHelper.SetText(widgets.txt_name, info.bookName)
    UIHelper.SetText(widgets.txt_desc, info.bookDesc)
    UIHelper.SetText(widgets.txt_exp, info.bookExp)
    UIHelper.SetText(widgets.txt_costValue, UIHelper.GetCountDownStr(info.bookCostTime))
  end
end

function m:GetSelectedArr()
  local ret = {}
  local map = self.m_selectedMap
  for i, v in ipairs(self.m_selectableGroup) do
    if map[v] == true then
      table.insert(ret, v.bookId)
    end
  end
  return ret
end

function m:_OnConfirm()
  local flow = Logic.studyLogic:GetStudyFlow()
  local selectedArr = self:GetSelectedArr()
  if #selectedArr == 0 then
    noticeManager:OpenTipPage(self, "\232\175\183\233\128\137\230\139\169\230\149\153\230\157\144")
    return
  end
  flow:Input(flow.InputType.Confirm, selectedArr)
end

function m:_OnClose()
  local flow = Logic.studyLogic:GetStudyFlow()
  flow:Input(flow.InputType.Cancel)
  if eventManager:HaveListener(LuaEvent.StudyGoOnSelectBookCancel) then
    eventManager:SendEvent(LuaEvent.StudyGoOnSelectBookCancel)
    eventManager:RemoveAllListener(LuaEvent.StudyGoOnSelectBookCance)
  end
end

function m:Select(index)
  super.Select(self, index)
  self:DisplaySelectExtra()
end

function m:DoOnClose()
  Logic.studyLogic:SetSendEnd(true)
end

return m
