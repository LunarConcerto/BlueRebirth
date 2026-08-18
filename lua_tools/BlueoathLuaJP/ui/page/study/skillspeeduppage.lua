local SkillSpeedUpPage = class("UI.Study.SkillSpeedUpPage", LuaUIPage)
local CommonRewardItem = require("ui.page.CommonItem")

function SkillSpeedUpPage:DoInit()
  self.m_tabWidgets = nil
  self.m_timer = nil
  self.m_itemMasks = {}
end

function SkillSpeedUpPage:DoOnOpen()
  self.m_param = self:GetParam()
  self:Refresh()
end

function SkillSpeedUpPage:Refresh()
  self:_ShowItem()
  self:_ShowNum()
  self:_ShowSkill()
  self:_ShowTime()
  self:_ShowUpTime()
end

function SkillSpeedUpPage:_ShowItem()
  local widgets = self:GetWidgets()
  local items = Logic.studyLogic:GetFormatBooksAndSort()
  self.m_items = items
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #items, function(index, tabParts)
    local item = CommonRewardItem:new()
    local book = items[index]
    item:Init(index, book, tabParts)
    local temp = Logic.studyLogic:GetSelectIndexById(index)
    tabParts.obj_mask:SetActive(temp ~= nil)
    local ismatch = Logic.studyLogic:IsMatch(book.ConfigId, self.m_param.pskillId)
    tabParts.obj_tag:SetActive(ismatch)
    local curIndex = Logic.studyLogic:GetCurUpItem()
    tabParts.obj_curSelect:SetActive(0 < curIndex and curIndex == index)
    local num = Logic.studyLogic:GetUpSelectNum(book.ConfigId)
    UIHelper.SetText(tabParts.tx_select, num)
    local time = Logic.studyLogic:GetUpTime(book.ConfigId, self.m_param.pskillId)
    UIHelper.SetText(tabParts.tx_time, UIHelper.GetCountDownStr(time))
    UGUIEventListener.AddButtonOnClick(tabParts.img_frame, self.OnClickItem, self, {
      index = index,
      parts = tabParts,
      item = book
    })
    self.m_itemMasks[index] = tabParts.obj_mask
  end)
end

function SkillSpeedUpPage:OnClickItem(go, param)
  local widgets = param.parts
  local index = param.index
  widgets.obj_mask:SetActive(true)
  Logic.studyLogic:SetCurUpItem(index)
  Logic.studyLogic:RemoveZeroSelect()
  Logic.studyLogic:AddSelectIndex(index, 0)
  self:_AddItem(nil, 1)
  self:_ShowItem()
  self:_ShowNum()
end

function SkillSpeedUpPage:_ShowNum()
  local widgets = self:GetWidgets()
  local curIndex = Logic.studyLogic:GetCurUpItem()
  if curIndex <= 0 then
    UIHelper.SetText(widgets.tx_num, 0)
  else
    local items = Logic.studyLogic:GetFormatBooksAndSort()
    local num = Logic.studyLogic:GetUpSelectNum(items[curIndex].ConfigId)
    UIHelper.SetText(widgets.tx_num, num)
  end
end

function SkillSpeedUpPage:_ShowTime()
  local widgets = self:GetWidgets()
  local remain = self:_getRemainTime()
  if remain <= 0 then
    remain = 0
  end
  UIHelper.SetText(widgets.tx_time, UIHelper.GetCountDownStr(remain))
  self:_UpdataTime()
end

function SkillSpeedUpPage:_UpdataTime()
  if self.m_timer then
    self:StopTimer(self.m_timer)
  end
  self.m_timer = self:CreateTimer(function()
    local remain = self:_getRemainTime()
    if remain <= 0 then
      remain = 0
    end
    if 0 < remain then
      local widgets = self:GetWidgets()
      UIHelper.SetText(widgets.tx_time, UIHelper.GetCountDownStr(remain))
    else
      self:StopTimer(self.m_timer)
    end
  end, 1, -1, false)
  self:StartTimer(self.m_timer)
end

function SkillSpeedUpPage:_getRemainTime()
  local uptime = Logic.studyLogic:GetSelectItemUpTime(self.m_param.pskillId)
  local res = self.m_param.finishTime - time.getSvrTime() - uptime
  return res
end

function SkillSpeedUpPage:_ShowUpTime()
  local widgets = self:GetWidgets()
  local uptime = Logic.studyLogic:GetSelectItemUpTime(self.m_param.pskillId)
  UIHelper.SetText(widgets.tx_uptime, UIHelper.GetCountDownStr(uptime))
end

function SkillSpeedUpPage:_ShowSkill()
  local widgets = self:GetWidgets()
  UIHelper.SetImage(widgets.im_icon, self.m_param.pskillIcon)
  UIHelper.SetText(widgets.tx_name, self.m_param.pskillName)
  UIHelper.SetText(widgets.tx_lv, "Lv." .. self.m_param.pskillLv)
end

function SkillSpeedUpPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_bg, self._Close, self)
  UGUIEventListener.AddButtonOnClick(widgets.im_close, self._Close, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_add, self._AddItem, self, 1)
  UGUIEventListener.AddButtonOnClick(widgets.btn_sub, self._AddItem, self, -1)
  UGUIEventListener.AddButtonOnClick(widgets.btn_rmd, self._RmdItem, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_ok, self._SendUp, self)
  self:RegisterEvent(LuaEvent.StudyUpSuccess, self._Close)
end

function SkillSpeedUpPage:DoOnHide()
end

function SkillSpeedUpPage:DoOnClose()
  Logic.studyLogic:SetUpItems({})
  Logic.studyLogic:SetCurUpItem(0)
  Logic.studyLogic:SetSelectIndex({})
end

function SkillSpeedUpPage:_AddItem(go, num)
  local curIndex = Logic.studyLogic:GetCurUpItem()
  if curIndex <= 0 then
    noticeManager:ShowTip("\232\175\183\233\128\137\230\139\169\230\138\128\232\131\189\228\185\166\230\157\165\229\138\160\233\128\159\230\138\128\232\131\189\229\141\135\231\186\167")
    return
  end
  local items = Logic.studyLogic:GetFormatBooksAndSort()
  local book = items[curIndex]
  local curNum = Logic.studyLogic:GetUpSelectNum(book.ConfigId)
  if book.Num < curNum + num then
    noticeManager:ShowTip("\232\190\190\229\136\176\230\183\187\229\138\160\228\184\138\233\153\144")
    return
  end
  if curNum + num < 0 then
    noticeManager:ShowTip("\232\190\190\229\136\176\230\183\187\229\138\160\228\184\139\233\153\144")
    return
  end
  local remain = self:_getRemainTime()
  if remain < 0 and 0 < num then
    noticeManager:ShowTip(UIHelper.GetString(600001))
    return
  end
  Logic.studyLogic:AddUpItem(book.ConfigId, num)
  Logic.studyLogic:AddSelectIndex(curIndex, num)
  self:Refresh()
end

function SkillSpeedUpPage:_RmdItem()
  local remain = self:_getRemainTime()
  if remain <= 0 then
    noticeManager:ShowTip("\229\189\147\229\137\141\233\128\137\230\139\169\229\143\175\228\187\165\229\174\140\230\136\144\229\173\166\228\185\160\229\149\166")
    return
  end
  local rmds = Logic.studyLogic:GetRmdUpItems(self.m_param.pskillId, remain)
  for id, num in pairs(rmds) do
    Logic.studyLogic:AddUpItem(id, num)
    local index = self:_findIndexById(id)
    Logic.studyLogic:AddSelectIndex(index, num)
  end
  self:Refresh()
end

function SkillSpeedUpPage:_findIndexById(id)
  for i, v in ipairs(self.m_items) do
    if v.ConfigId == id then
      return i
    end
  end
  return 1
end

function SkillSpeedUpPage:_SendUp()
  local have = Logic.studyLogic:IsSelectUpItem()
  if not have then
    noticeManager:ShowTip("\232\175\183\233\128\137\230\139\169\230\138\128\232\131\189\228\185\166\230\157\165\229\138\160\233\128\159\230\138\128\232\131\189\229\141\135\231\186\167")
    return
  end
  local remain = self:_getRemainTime()
  if remain < 0 then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          self:_SendUpImp()
        end
      end
    }
    local str = string.format(UIHelper.GetString(600000), UIHelper.GetTimeStr(-remain))
    noticeManager:ShowMsgBox(str, tabParams)
    return
  end
  self:_SendUpImp()
end

function SkillSpeedUpPage:_SendUpImp()
  local items = Logic.studyLogic:GetUpItems()
  local temp = {}
  for id, num in pairs(items) do
    if 0 < num then
      table.insert(temp, {TextbookId = id, TextbookNum = num})
    end
  end
  Service.studyService:SendSpeedUp(self.m_param.heroId, self.m_param.pskillId, temp)
  local dotinfo = {
    info = "ui_study_accelerate",
    item_num = self:_DotSpeedUpItems2Str(temp)
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
end

function SkillSpeedUpPage:_Close()
  UIHelper.ClosePage("SkillSpeedUpPage")
end

function SkillSpeedUpPage:_DotSpeedUpItems2Str(items)
  local res = {}
  for _, item in ipairs(items) do
    res[tostring(item.TextbookId)] = item.TextbookNum
  end
  return res
end

return SkillSpeedUpPage
