local BattleAutoChatPage = class("UI.Chat.BattleAutoChatPage", LuaUIPage)

function BattleAutoChatPage:DoInit()
  self.m_tabWidgets = nil
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.objPool = {}
  self.m_allFixedMsg = nil
  self.m_msg_ShowNum = 2
  self.m_index = 0
  self.m_isOpenChat = false
  self.m_timer = {}
  self.m_rate = 100
  self.m_cdTime = 0
end

function BattleAutoChatPage:DoOnOpen()
  self.otherUsertab = {}
  self.m_tabWidgets.obj_chat:SetActive(true)
  self.m_tabWidgets.obj_msgCon:SetActive(false)
  local matchPlayerUids = Data.battleAutoChatData:GetAllMatchPlayerUID()
  if matchPlayerUids and 1 < #matchPlayerUids then
    for i = 1, #matchPlayerUids do
      self:GetOtherUserInfo(matchPlayerUids[i])
    end
  end
  self.m_cdTime, _ = Data.battleAutoChatData:GetSendChatCDTime()
  self:SetMask()
  self:GetMatchCopy()
end

function BattleAutoChatPage:GetMatchCopy()
  local copyId = Data.copyData:GetRecordMatchCopyData()
  self.m_matchType = Logic.copyLogic:GetMatchCopyType(copyId)
end

function BattleAutoChatPage:SetMask()
  local canSend, canSendTime = Logic.battleAutoChatLogic:IsCanSend()
  self.m_tabWidgets.obj_mask:SetActive(canSend == false)
  self.m_tabWidgets.btn_chat.interactable = canSend
  if not canSend then
    self.m_tabWidgets.img_mask.fillAmount = 1
    self:StopAllTimer()
    self.m_timer = nil
    local index = 1
    local now = time.getSvrTime()
    canSendTime = canSendTime * self.m_rate
    now = now * self.m_rate
    self.m_timer = self:CreateTimer(function()
      local fillCount = (canSendTime - now - index) / (self.m_cdTime * self.m_rate)
      index = index + 1
      self.m_tabWidgets.img_mask.fillAmount = fillCount
      if fillCount <= 0 then
        self.m_tabWidgets.obj_mask:SetActive(false)
        self.m_tabWidgets.btn_chat.interactable = true
        self:StopTimer(self.m_timer)
      end
    end, 1 / self.m_rate, -1, false)
    self:StartTimer(self.m_timer)
  else
    self:StopTimer(self.m_timer)
    self.m_timer = nil
  end
end

function BattleAutoChatPage:RegisterAllEvent()
  local widgets = self.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(widgets.btn_chat, self._OpenChatCon, self)
  UGUIEventListener.AddButtonOnClick(widgets.Button, function()
    UIHelper.ClosePage("BattleAutoChatPage")
    UIHelper.OpenPage("HomePage")
  end, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_mask, function()
    noticeManager:OpenTipPage(self, UIHelper.GetString(941002))
  end, self)
  self:RegisterEvent("matchChatMsg", self._ReceiveSeverChatMsg, self)
  self:RegisterEvent("onClickMsgId", self.SetChatConClose, self)
  self:RegisterEvent("onClickMsgId", self.CreatePopMsg, self)
  self:RegisterEvent("hideBattleAutoChatBtn", self.HideAutoBtn, self)
  self:RegisterEvent(LuaEvent.GetOtherUserInfoByUid, self._GetOtherUserInfoCallBack, self)
end

function BattleAutoChatPage:HideAutoBtn()
  self.m_tabWidgets.obj_chat:SetActive(false)
end

function BattleAutoChatPage:GetOtherUserInfo(uid)
  Service.userService:SendGetOtherInfo(uid)
end

function BattleAutoChatPage:_GetOtherUserInfoCallBack(param)
  local uid = param.Uid
  self.otherUsertab[uid] = param
  Data.battleAutoChatData:SetMatchUserInfoData(uid, param)
end

function BattleAutoChatPage:_ReceiveSeverChatMsg(msg)
  self.m_index = self.m_index + 1
  local obj = self:GetMsgObjFromPool(self.m_index)
  self:DealObjTween(obj, msg)
end

function BattleAutoChatPage:GetMsgObj()
  return UIHelper.CreateGameObject(self.m_tabWidgets.obj_chatshow, self.m_tabWidgets.trans_Container)
end

function BattleAutoChatPage:DealObjTween(obj, msg)
  local go = obj.go
  go:SetActive(true)
  go.transform:SetAsFirstSibling()
  obj.enable = true
  local part = go:GetComponent(BabelTime.Lobby.UI.LuaPart.GetClassType()):GetLuaTableParts()
  part.tween_msg:ResetToBeginning()
  UIHelper.SetText(part.tx_chat, self:GetFixedChatMsgById(msg.MsgId))
  local userInfo = self.otherUsertab[msg.Uid]
  local icon, qualityIcon = Data.userData:GetUserHeadIcon(userInfo)
  UIHelper.SetImage(part.im_playerhead, icon)
  UIHelper.SetText(part.tx_playernum, Data.battleAutoChatData:GetMatchUserOrder(msg.Uid))
  part.tween_msg:Play(true)
  part.tween_msg:SetOnFinished(function()
    go:SetActive(false)
    obj.enable = false
    part.tween_msg:ResetToBeginning()
  end)
end

function BattleAutoChatPage:GetMsgObjFromPool(msgIndex)
  if self.objPool == nil or #self.objPool < self.m_msg_ShowNum then
    for i = 1, self.m_msg_ShowNum do
      local obj = {
        go = self:GetMsgObj(),
        enable = false,
        index = i
      }
      self.objPool[i] = obj
    end
  end
  table.sort(self.objPool, function(r, l)
    return r.index < l.index
  end)
  for _, v in ipairs(self.objPool) do
    if v.enable == false then
      v.go:SetActive(false)
      v.index = msgIndex
      return v
    end
  end
  for _, obj in ipairs(self.objPool) do
    obj.go:SetActive(false)
    obj.enable = false
    obj.index = msgIndex
    return obj
  end
end

function BattleAutoChatPage:_OpenChatCon()
  if self.m_isOpenChat then
    self.m_isOpenChat = false
    self:SetChatConEnable(false)
  else
    self.m_isOpenChat = true
    self:SetChatConEnable(true)
    self:ReadFixedChatMsg()
    self:LoadFixedChatMsg()
  end
end

function BattleAutoChatPage:CreatePopMsg(msgId)
end

function BattleAutoChatPage:SetChatConClose()
  self:SetChatConEnable(false)
  self.m_isOpenChat = false
  self:SetMask()
end

function BattleAutoChatPage:SetChatConEnable(isOpen)
  self.m_tabWidgets.obj_msgCon:SetActive(isOpen)
end

function BattleAutoChatPage:ReadFixedChatMsg()
  if self.m_allFixedMsg == nil then
    self.m_allFixedMsg = configManager.GetData("config_battle_auto_chat")
  end
  return self.m_allFixedMsg
end

function BattleAutoChatPage:GetFixedChatMsgById(id)
  if self.m_allFixedMsg == nil then
    self.m_allFixedMsg = configManager.GetData("config_battle_auto_chat")
  end
  return self.m_allFixedMsg[id].text
end

function BattleAutoChatPage:LoadFixedChatMsg()
  if #self.m_allFixedMsg > 0 then
    UIHelper.CreateSubPart(self.m_tabWidgets.obj_text, self.m_tabWidgets.trans_myContent, #self.m_allFixedMsg, function(index, part)
      UIHelper.SetText(part.tx_chat, self.m_allFixedMsg[index].text)
      UGUIEventListener.AddButtonOnClick(part.btn_text, function()
        local isOn = Logic.battleAutoChatLogic:IsCanSend()
        if isOn then
          self:SendChatMsg(index)
        else
          noticeManager:ShowMsgBox("Is on CD!!!!")
        end
      end, self)
    end)
  end
end

function BattleAutoChatPage:SendChatMsg(id)
  Data.battleAutoChatData:RecordSendMsgTime()
  eventManager:SendEvent("onClickMsgId", index)
  Service.battleAutoChatService:SendMatchChatMsg(id, self.m_matchType)
end

function BattleAutoChatPage:DoOnClose()
  Data.copyData:SetRecordMatchCopyData(0)
end

return BattleAutoChatPage
