local ARkitProjectionPage = class("UI.ARkit.ARkitProjectionPage", LuaUIPage)

function ARkitProjectionPage:DoInit()
  self.tab_Widgets.obj_startBattle:SetActive(false)
  self.duration = 121
  self.interval = 1
  local time_str = tostring(self.duration - 1) .. "s"
  self.tab_Widgets.text_timer.text = time_str
end

function ARkitProjectionPage:DoOnOpen()
  self.creater = self.param.isMaster
  self.showConfirm = ture
  self.brightEnough = false
  self.tab_Widgets.btn_ok.gameObject:SetActive(false)
  if not self.creater then
    UIHelper.SetText(self.tab_Widgets.text_tip, UIHelper.GetString(1430020))
  end
  self:_StartTimer()
end

function ARkitProjectionPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickEnter, self)
  self:RegisterEvent(LuaCSharpEvent.ARCanPut, self._ShowARConfirm, self)
  self:RegisterEvent(LuaCSharpEvent.ShowStartBattle, self._ShowStartBattle, self)
  self:RegisterEvent(LuaCSharpEvent.ARStartFill, self._HideAll, self)
  self:RegisterEvent(LuaCSharpEvent.ARBrightness, self._ARBrightness, self)
end

function ARkitProjectionPage:_HideAll(param)
  self.tab_Widgets.im_bg:SetActive(false)
  self:_StopTimer(false)
end

function ARkitProjectionPage:_ShowStartBattle(param)
  self:_HideAll()
  self.tab_Widgets.obj_startBattle:SetActive(true)
end

function ARkitProjectionPage:_ARBrightness(param)
  if param < 0.3 then
    self.brightEnough = false
  else
    self.brightEnough = true
  end
end

function ARkitProjectionPage:_ShowARConfirm(enable)
  if self.creater and not self.brightEnough then
    UIHelper.SetText(self.tab_Widgets.text_tip, "\229\189\147\229\137\141\231\142\175\229\162\131\229\133\137\231\186\191\229\188\186\229\186\166\228\184\141\232\182\179")
    if self.showConfirm then
      self.showConfirm = false
      self.tab_Widgets.btn_ok.gameObject:SetActive(false)
    end
    return
  end
  if self.creater and self.showConfirm ~= enable then
    self.showConfirm = enable
    self.tab_Widgets.btn_ok.gameObject:SetActive(enable)
    local tipId = enable and 1430017 or 1430015
    UIHelper.SetText(self.tab_Widgets.text_tip, UIHelper.GetString(tipId))
  end
end

function ARkitProjectionPage:_ClickEnter()
  self:_HideAll()
  eventManager:FireEventToCSharp(LuaCSharpEvent.ARPutConfirm)
end

function ARkitProjectionPage:_ClickClose()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        self:_Close()
      end
    end
  }
  noticeManager:ShowMsgBox(1430018, tabParams)
end

function ARkitProjectionPage:_Close()
  UIHelper.ClosePage("ARkitProjectionPage")
  CS.Battle.Runtime.Env.SetBattleFiledOver(true)
  if self.leftTimer then
    self.leftTimer:Stop()
    self.leftTimer = nil
  end
end

function ARkitProjectionPage:_StartTimer()
  self.endTime = self.duration
  local showTextContent = function()
    self.endTime = self.endTime - 1
    local time_str = tostring(self.endTime) .. "s"
    if not IsNil(self.tab_Widgets.text_timer) then
      self.tab_Widgets.text_timer.text = time_str
    end
    if self.endTime <= 0 then
      self:_StopTimer(true)
    end
  end
  self.leftTimer = Timer.New(showTextContent, self.interval, self.duration, false)
  self.leftTimer:Start()
end

function ARkitProjectionPage:_StopTimer(tip)
  if self.leftTimer then
    self.leftTimer:Stop()
    self.leftTimer = nil
    if tip then
      local tabParams = {
        msgType = NoticeType.OneButton,
        callback = function(bool)
          if bool then
            self:_Close()
          end
        end
      }
      noticeManager:ShowMsgBox(1430029, tabParams)
    end
  end
  self.tab_Widgets.text_timer.enabled = false
end

return ARkitProjectionPage
