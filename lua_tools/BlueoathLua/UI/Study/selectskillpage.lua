local SelectSkillPage = class("UI.Study.SelectSkillPage", require("ui.page.SelectBasePage"))
local SelectPSkillItem = require("ui.page.Study.SelectPSkillItem")
SelectSkillPage.TestDisplayData = {
  skillDisplayInfo = {
    {
      pskillId = 1,
      pskillName = "\230\156\128\229\188\186\228\185\139\231\155\190",
      pskillIcon = "",
      pskillDesc = "\230\138\128\232\131\189xxxxxxxxxxx",
      pskillLv = 7,
      curExp = 1050,
      nextLvExp = 3200
    },
    {
      pskillId = 1,
      pskillName = "\230\156\128\229\188\186\228\185\139\231\155\190",
      pskillIcon = "",
      pskillDesc = "\230\138\128\232\131\189xxxxxxxxxxx",
      pskillLv = 7,
      curExp = 1050,
      nextLvExp = 3200
    },
    {
      pskillId = 1,
      pskillName = "\230\156\128\229\188\186\228\185\139\231\155\190",
      pskillIcon = "",
      pskillDesc = "\230\138\128\232\131\189xxxxxxxxxxx",
      pskillLv = 7,
      curExp = 1050,
      nextLvExp = 3200
    },
    {
      pskillId = 1,
      pskillName = "\230\156\128\229\188\186\228\185\139\231\155\190",
      pskillIcon = "",
      pskillDesc = "\230\138\128\232\131\189xxxxxxxxxxx",
      pskillLv = 7,
      curExp = 1050,
      nextLvExp = 3200
    }
  }
}

function SelectSkillPage:DoInit()
  self.m_tabWidgets = nil
  self.m_itemArr = {}
  self.m_show = false
end

function SelectSkillPage:SetData(data)
  self.m_maxSelectNum = 1
  self.m_selectableGroup = data.skillDisplayInfo
  self.m_filterAndSortGroup = {}
  table.insertto(self.m_filterAndSortGroup, self.m_selectableGroup, 1)
  table.sort(self.m_filterAndSortGroup, function(a, b)
    return a.pskillId < b.pskillId
  end)
  self.m_selectedMap = {}
  for i, index in pairs(data.selectedIndexArr or {}) do
    self.m_selectedMap[self.m_selectableGroup[index]] = ture
  end
  self.itemClass = SelectPSkillItem
end

function SelectSkillPage:RegisterUIEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_confirm, self._OnConfirm, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._OnClose, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self._OnClose, self)
  self:RegisterEvent(LuaEvent.StudySelectPSkillItem, self._ShowPSkillTip, self)
end

function SelectSkillPage:_ShowPSkillTip(data)
  local ismax = Logic.shipLogic:CheckHeroPSkillReachMax(Logic.studyLogic:GetStudyFlow().data.heroId, data.pskillId)
  if ismax then
    return
  end
  local widgets = self:GetWidgets()
  if not self.m_show then
    widgets.obj_tip:SetActive(true)
    self.m_show = true
  end
  local lv = data.pskillLv + 1
  local max = Logic.shipLogic:GetPSkillLvMax(data.pskillId)
  local des = Logic.shipLogic:GetPSkillDesc(data.pskillId, lv, false)
  UIHelper.SetText(widgets.tx_lv, "LV." .. lv)
  UIHelper.SetText(widgets.tx_tip, "(\230\156\128\233\171\152\229\143\175\229\141\135\232\135\179" .. max .. "\231\186\167)")
  UIHelper.SetText(widgets.tx_des, des)
end

function SelectSkillPage.GenDisplayData(pskillArr, heroId)
  local data = {}
  data.skillDisplayInfo = {}
  for i, pskill in ipairs(pskillArr) do
    local info = {}
    info.pskillId = pskill.PSkillId
    info.pskillType = Logic.shipLogic:GetPSkillType(pskill.PSkillId)
    info.pskillName = Logic.shipLogic:GetPSkillName(pskill.PSkillId)
    info.curExp = pskill.PSkillExp
    info.pskillLv = Logic.shipLogic:GetPSkillLvByExp(pskill.PSkillExp)
    info.pskillIcon = Logic.shipLogic:GetPSkillIcon(pskill.PSkillId)
    info.lastLvExp, info.nextLvExp = Logic.shipLogic:GetPSkillLvLowerAndUpper(info.pskillLv)
    info.pskillDesc = Logic.shipLogic:GetPSkillDesc(pskill.PSkillId, info.pskillLv, false)
    table.insert(data.skillDisplayInfo, info)
  end
  return data
end

function SelectSkillPage:DisplaySelectExtra()
end

function SelectSkillPage:GetSelectedArr()
  local ret = {}
  local map = self.m_selectedMap
  for i, v in ipairs(self.m_selectableGroup) do
    if map[v] == true then
      table.insert(ret, v.pskillId)
    end
  end
  return ret
end

function SelectSkillPage:_OnConfirm()
  local flow = Logic.studyLogic:GetStudyFlow()
  local selectedArr = self:GetSelectedArr()
  if #selectedArr == 0 then
    noticeManager:OpenTipPage(self, "\232\175\183\233\128\137\230\139\169\230\138\128\232\131\189")
    return
  end
  local heroId = Logic.studyLogic:GetStudyFlow().data.heroId
  if Logic.shipLogic:CheckHeroPSkillReachMax(heroId, selectedArr[1]) then
    noticeManager:ShowTip("\230\138\128\232\131\189\229\183\178\232\190\190\230\156\128\229\164\167\231\173\137\231\186\167")
    return
  end
  flow:Input(flow.InputType.Confirm, selectedArr)
end

function SelectSkillPage:_OnClose()
  local flow = Logic.studyLogic:GetStudyFlow()
  flow:Input(flow.InputType.Cancel)
end

return SelectSkillPage
