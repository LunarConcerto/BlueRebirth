local m = class("SelectPSkillItem")

function m:SetData(data, part, index)
  self.data = data
  self.part = part
  self.m_selected = data.bSelect
  self.index = index
end

function m:Display()
  local data = self.data
  local part = self.part
  local index = self.index
  local color = TalentColor[data.pskillType]
  UIHelper.SetTextColor(part.txt_name, data.pskillName, color)
  UIHelper.SetImage(part.img_icon, data.pskillIcon)
  UIHelper.SetText(part.txt_lv, data.pskillLv)
  UIHelper.SetText(part.txt_desc, data.pskillDesc)
  local strNext = Logic.shipLogic:CheckHeroPSkillReachMax(Logic.studyLogic:GetStudyFlow().data.heroId, data.pskillId) and "MAX" or string.format("%s/%s", math.tointeger(data.curExp - data.lastLvExp), data.nextLvExp - data.lastLvExp)
  UIHelper.SetText(part.txt_next, strNext)
end

function m:OnSelect()
  eventManager:SendEvent(LuaEvent.StudySelectPSkillItem, self.data)
end

function m:OnUnSelect()
end

return m
