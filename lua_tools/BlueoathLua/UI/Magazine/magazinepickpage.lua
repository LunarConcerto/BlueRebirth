local MagazinePickPage = class("UI.Magazine.MagazinePickPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function MagazinePickPage:DoInit()
  self.heroMap = {}
end

function MagazinePickPage:DoOnOpen()
  local params = self:GetParam()
  self.magazineId = params.magazineId
  self.magazineConfig = configManager.GetDataById("config_magazine_info", self.magazineId)
  self:ShowAllShip()
  self:ShowTicket()
  self:ShowTag()
end

function MagazinePickPage:ShowTicket()
  local widgets = self:GetWidgets()
  local sumVote = self:GetVoteSum()
  local parameter = configManager.GetDataById("config_parameter", 356).arrValue
  local num = Logic.bagLogic:GetConsumeCurrNum(parameter[1], parameter[2])
  UIHelper.SetLocText(widgets.tx_ticket_left, 4000013, num - sumVote)
  local startTime, endTime = PeriodManager:GetPeriodTime(self.magazineConfig.period, self.magazineConfig.ticket_period_area)
  local timer = self:CreateTimer(function()
    local timeLeft = endTime - time.getSvrTime()
    widgets.tx_time.gameObject:SetActive(0 < timeLeft)
    if 0 < timeLeft then
      local timeLeftFormat = time.getTimeStringFontTwo(timeLeft)
      UIHelper.SetLocText(widgets.tx_time, 4000025, timeLeftFormat)
    else
      UIHelper.SetLocText(widgets.tx_time, 4000024)
    end
  end, 0.5, -1)
  self:StartTimer(timer)
end

function MagazinePickPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close1, self.btn_close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_clear, self._ClickClear, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_vote, self._ClickVote, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_openbutton, self._ClickClose, self)
end

function MagazinePickPage:_ClickClose()
  UIHelper.ClosePage("MagazinePickPage")
  UIHelper.ClosePage("MagazineSinglePage")
  UIHelper.ClosePage("MagazinePage")
  eventManager:SendEvent(LuaEvent.MagazineBack)
  GR.cameraManager:showCamera(GameCameraType.RoomSceneCamera)
end

function MagazinePickPage:ShowAllShip()
  local widgets = self:GetWidgets()
  local data = self.magazineConfig.ticket_ship_id
  UIHelper.CreateSubPart(widgets.ship, widgets.Content, #data, function(index, tabPart)
    local illustrateId = data[index]
    local config = configManager.GetDataById("config_ship_handbook", illustrateId)
    local config_show = configManager.GetDataById("config_ship_show", illustrateId)
    UIHelper.SetImage(tabPart.im_ship, config_show.ship_icon5)
    local num = self.heroMap[illustrateId] or 0
    tabPart.num:SetActive(0 < num)
    tabPart.btn_sub.gameObject:SetActive(0 < num)
    UIHelper.SetText(tabPart.tx_num, num)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_add, function()
      local sumVote = self:GetVoteSum()
      local parameter = configManager.GetDataById("config_parameter", 356).arrValue
      local num = Logic.bagLogic:GetConsumeCurrNum(parameter[1], parameter[2])
      if sumVote >= num then
        noticeManager:ShowTipById(4000017)
        return
      end
      local num = self.heroMap[illustrateId] or 0
      num = num + 1
      self.heroMap[illustrateId] = num
      tabPart.num:SetActive(0 < num)
      tabPart.btn_sub.gameObject:SetActive(0 < num)
      UIHelper.SetText(tabPart.tx_num, num)
      self:ShowTicket()
      self:ShowTag()
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_sub, function()
      local num = self.heroMap[illustrateId] or 0
      if num <= 0 then
        return
      end
      num = num - 1
      self.heroMap[illustrateId] = num
      tabPart.num:SetActive(0 < num)
      tabPart.btn_sub.gameObject:SetActive(0 < num)
      UIHelper.SetText(tabPart.tx_num, num)
      self:ShowTicket()
      self:ShowTag()
    end)
  end)
end

function MagazinePickPage:ShowTag()
  local widgets = self:GetWidgets()
  local data = self:GetTagList()
  UIHelper.CreateSubPart(widgets.im_tag, widgets.Content_tag, #data, function(index, tabPart)
    local tagId = data[index].id
    local config = configManager.GetDataById("config_magazine_tag", tagId)
    UIHelper.SetText(tabPart.tx_tag, config.name)
  end)
end

function MagazinePickPage:btn_close()
  UIHelper.ClosePage("MagazinePickPage")
end

function MagazinePickPage:_ClickClear()
  if self:GetVoteSum() <= 0 then
    noticeManager:ShowTipById(4000037)
    return
  end
  self.heroMap = {}
  self:ShowAllShip()
  self:ShowTicket()
  self:ShowTag()
end

function MagazinePickPage:GetVoteSum()
  local sum = 0
  for i, v in pairs(self.heroMap) do
    sum = sum + v
  end
  return sum
end

function MagazinePickPage:GetTagMap()
  local tagMap = {}
  for id, num in pairs(self.heroMap) do
    local config = configManager.GetDataById("config_ship_handbook", id)
    local tagList = config.magazine_tag
    for i, tagId in ipairs(tagList) do
      local tagNum = tagMap[tagId] or 0
      tagMap[tagId] = tagNum + num
    end
  end
  return tagMap
end

function MagazinePickPage:GetTagList()
  local result = {}
  local tagMap = self:GetTagMap()
  for id, num in pairs(tagMap) do
    if 0 < num then
      local sub = {}
      sub.id = id
      sub.num = num
      table.insert(result, sub)
    end
  end
  table.sort(result, function(a, b)
    if a.num ~= b.num then
      return a.num > b.num
    else
      return a.id > b.id
    end
  end)
  return result
end

function MagazinePickPage:_ClickVote()
  if self:GetVoteSum() <= 0 then
    noticeManager:ShowTipById(4000037)
    return
  end
  local isOpen = PeriodManager:IsInPeriodArea(self.magazineConfig.period, self.magazineConfig.ticket_period_area)
  if not isOpen then
    noticeManager:ShowTipById(4000024)
    return
  end
  local data = {}
  data.MagazineId = self.magazineId
  data.VoteList = {}
  for id, num in pairs(self.heroMap) do
    local sub = {}
    sub.Id = id
    sub.Num = num
    table.insert(data.VoteList, sub)
  end
  if 0 >= #data.VoteList then
    return
  end
  Service.magazineService:SendMagazineVote(data)
  UIHelper.ClosePage("MagazinePickPage")
end

return MagazinePickPage
