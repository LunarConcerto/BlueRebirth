local TeachRelateTip = class("UI.Teaching.TeachRelateTip", LuaUIPage)
local teachingUserItem = require("ui.page.Teaching.TeachingUserItem")

function TeachRelateTip:DoInit()
  self.m_btnConfig = {
    {
      Name = "\232\129\138\229\164\169",
      Func = self._Chat
    },
    {
      Name = "\230\183\187\229\138\160\229\165\189\229\143\139",
      Func = self._AddFriend
    }
  }
  self.m_user = {}
  self.m_teach = {}
end

function TeachRelateTip:DoOnOpen()
  local param = self:GetParam()
  self.m_user = param.Usr
  self.m_teach = param.Teach
  self:_Refresh()
end

function TeachRelateTip:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
end

function TeachRelateTip:_Refresh()
  self:_ShowRelateInfo(players)
end

function TeachRelateTip:_ShowRelateInfo(players)
  local widgets = self:GetWidgets()
  players = players or self.m_teach.Relation
  UIHelper.CreateSubPart(widgets.obj_item, widgets.trans_item, #players, function(index, tabPart)
    local player = players[index]
    local item = teachingUserItem:new()
    item:Init(self, tabPart, index, player)
    self:_ShowBtn(tabPart, player)
    local title = self:_getRelateTitle(self.m_user.Uname, player)
    UIHelper.SetText(tabPart.tx_title, title)
    local timg = Logic.teachingLogic:CheckIsTeacher() and "uipic_ui_teaching_bg_xueyuanbiaoqian" or "uipic_ui_teaching_bg_daoshibiaoqian"
    UIHelper.SetImage(tabPart.im_title, timg)
  end)
end

function TeachRelateTip:_getRelateTitle(name, player)
  local res = ""
  local sstr = {
    [ETeachingState.TEACHER] = "\229\175\188\229\184\136",
    [ETeachingState.STUDENT] = "\229\173\166\229\145\152"
  }
  if sstr[player.TeachingStatus] then
    res = sstr[player.TeachingStatus]
  end
  if res == "\229\173\166\229\145\152" then
    local scs = player.CreateTime == 0 and "-\229\183\178\230\175\149\228\184\154" or ""
    res = scs .. "\231\154\132" .. res
  end
  return name .. res
end

function TeachRelateTip:_ShowBtn(widgets, data)
  local configs = clone(self.m_btnConfig)
  local mf = Logic.friendLogic:IsMyFriend(data.Uid)
  if mf then
    table.remove(configs, 2)
  end
  UIHelper.CreateSubPart(widgets.obj_btn, widgets.trans_btn, #configs, function(index, tabPart)
    local config = configs[index]
    UIHelper.SetText(tabPart.tx_btn, config.Name)
    UGUIEventListener.AddButtonOnClick(tabPart.obj_btn, config.Func, self, data)
  end)
end

function TeachRelateTip:_CloseSelf()
  UIHelper.ClosePage("TeachingDetailsPage")
end

function TeachRelateTip:_AddFriend(go, param)
  logError("add friend")
  Logic.teachingLogic:AddFriendWrap(param)
end

function TeachRelateTip:_Chat(go, param)
  logError("chat")
  Logic.teachingLogic:ChatWrap(param.UserInfo)
end

function TeachRelateTip:DoOnHide()
end

function TeachRelateTip:DoOnClose()
end

return TeachRelateTip
