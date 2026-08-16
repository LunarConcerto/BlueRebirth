local UserLevelUpPage = class("UI.Common.UserLevelUpPage", LuaUIPage)

function UserLevelUpPage:DoInit()
end

function UserLevelUpPage:DoOnOpen()
  self:_Refresh()
end

function UserLevelUpPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_skip, self._Next, self)
end

function UserLevelUpPage:_Refresh()
  local oldLv = self:GetParam().OldLv
  local newLv = self:GetParam().NewLv
  self:_ShowLv(oldLv)
  local rewards = Logic.userLogic:GetUsrLvUpRewards(oldLv, newLv)
  self:_ShowRewards(rewards)
  local timer = self:CreateTimer(function()
    self:_ShowLvUpTween()
  end, 0.5, 1, true)
  self:StartTimer(timer)
end

function UserLevelUpPage:_ShowLv(lv)
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.tx_lv, lv)
end

function UserLevelUpPage:_ShowRewards(rewards)
  local widgets = self:GetWidgets()
  local reward
  UIHelper.CreateSubPart(widgets.obj_reward, widgets.trans_reward, #rewards, function(index, tabPart)
    reward = rewards[index]
    UIHelper.SetText(tabPart.txt_num, reward.Num)
    local icon = Logic.goodsLogic:GetIcon(reward.ConfigId, reward.Type)
    UIHelper.SetImage(tabPart.img_icon, icon)
  end)
end

function UserLevelUpPage:_ShowLvUpTween()
  local param = self:GetParam()
  local oldLv, newLv = param.OldLv, param.NewLv
  local delta = newLv - oldLv
  if 0 < delta then
    local count = 0
    local timer = self:CreateTimer(function()
      count = count + 1
      self:_ShowLv(oldLv + count)
    end, 1, delta, true)
    self:StartTimer(timer)
  end
end

function UserLevelUpPage:_Next()
  self:_CloseSelf()
end

function UserLevelUpPage:_CloseSelf()
  UIHelper.ClosePage("UserLevelUpPage")
  eventManager:SendEvent(LuaEvent.COMMONUI_UserLvShowEnd)
end

function UserLevelUpPage:DoOnHide()
end

function UserLevelUpPage:DoOnClose()
end

return UserLevelUpPage
