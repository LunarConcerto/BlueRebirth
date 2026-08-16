local TeachingUserItem = class("UI.Teaching.TeachingUserItem")

function TeachingUserItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.index = nil
  self.data = nil
end

function TeachingUserItem:Init(obj, tabPart, index, data)
  self.page = obj
  self.tabPart = tabPart
  self.index = index
  self.data = data
  self:_SetUserInfo()
end

function TeachingUserItem:_SetUserInfo()
  local icon, quality = Logic.chatLogic:GetUserHead(self.data.UserInfo)
  UIHelper.SetImage(self.tabPart.img_head, icon)
  UIHelper.SetImage(self.tabPart.img_quality, quality)
  local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(self.data.UserInfo)
  if self.data.UserInfo.Uid == Data.userData:GetUserUid() then
    _, headFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame()
  end
  self.tabPart.obj_headFrame.gameObject:SetActive(true)
  UIHelper.SetImage(self.tabPart.obj_headFrame, headFrameInfo.icon)
  self.tabPart.txt_name.text = Logic.teachingLogic:DisposeUname(self.data.UserInfo.Uname)
  self.tabPart.txt_level.text = "LV." .. self.data.UserInfo.Level
  local onlineColor = self.data.UserInfo.OfflineTime == 0 and "4FC95A" or "A9BBCC"
  local status = Logic.teachingLogic:GetUserStatus(self.data.UserInfo.OfflineTime)
  UIHelper.SetTextColor(self.tabPart.txt_online, status, onlineColor)
  local sexConf = Logic.teachingLogic:GetSelfInfoById(ETeachingIntroGroupId.SEX, self.data.Sex)
  UIHelper.SetImage(self.tabPart.img_sex, sexConf.icon)
  local favorConf = Logic.teachingLogic:GetSelfInfoById(ETeachingIntroGroupId.ATTR, self.data.Interest)
  UIHelper.SetImage(self.tabPart.img_favor, favorConf.icon)
  self.tabPart.txt_favor.text = favorConf.name
  self.tabPart.txt_time.text = Logic.teachingLogic:GetSelfInfoById(ETeachingIntroGroupId.TIME, self.data.Active).name
  self.tabPart.txt_intro.text = self.data.Sign or ""
  local serName = Logic.serverLogic:GetServerNameById(self.data.UserInfo.ServerId)
  self.tabPart.txt_server.text = string.format(UIHelper.GetString(2200082), serName)
end

function TeachingUserItem:GetTeachingUserPart()
  return self.page, self.tabPart, self.index
end

return TeachingUserItem
