local Discuss_Page = class("UI.GirlInfo.Discuss_Page", LuaUIPage)

function Discuss_Page:DoInit()
  self.mHotCommentMaxNum = 0
  self.mNoramlCommentMaxMum = 0
  self.m_tabSerStartDiscussData = nil
  self.shipId = 0
  self.m_tabmsgInfo = nil
  self.discussContent = nil
  self.m_tabUserInfo = nil
  self.disLikeMaxNum = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function Discuss_Page:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_send, function()
    self:_ClickSend()
  end)
  self:RegisterEvent("GetDiscussMsg", self._GetDiscussCallBack, self)
  self:RegisterEvent("DiscussMsg", self._DiscussCallBack, self)
  self:RegisterEvent("DiscussMaskWord", self._GetMaskWordCallBack, self)
  self:RegisterEvent(LuaEvent.UpdateGirlTog, self.UpdateGirlTog)
  self:RegisterEvent(LuaEvent.GirlInfoTween, self._GirlInfoTween)
  self:RegisterEvent(LuaEvent.GirlInfoUIReset, self._ResetUI)
end

function Discuss_Page:_ResetUI()
  local widgets = self:GetWidgets()
  widgets.tween_dongHua:ResetToEnd()
end

function Discuss_Page:_GirlInfoTween(delta)
  local position = configManager.GetDataById("config_parameter", 95).arrValue
  if delta then
    self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D = Vector2.New(delta, position[3])
  else
    self.m_tabWidgets.tween_dongHua.from = self.m_tabWidgets.obj_dongHua.transform.anchoredPosition3D
    self.m_tabWidgets.tween_dongHua:ResetToBeginning()
    self.m_tabWidgets.tween_dongHua:Play(true)
  end
end

function Discuss_Page:_GetMaskWordCallBack(param)
  if noticeManager:GetIsClose() then
    noticeManager:ShowMsgBox(param)
  end
end

function Discuss_Page:DoOnOpen()
  self.mHotCommentMaxNum = Logic.discussLogic:GetHotCommentNum()
  self.mNoramlCommentMaxMum = Logic.discussLogic:GetNormalCommentMaxNum()
  self.disLikeMaxNum = Logic.discussLogic:GetDiskLikeMaxNum()
  self.m_tabUserInfo = Data.userData:GetUserData()
  local params = self:GetParam()
  self.shipId = params.heroId
  self.isNpc = params.isNpc
  self.m_tabWidgets.input_content.text = ""
  local ok, data = Logic.discussLogic:TryGetDisData(self.shipId)
  if ok then
    self:_ShowDiscussInfo(data)
  end
end

function Discuss_Page:UpdateGirlTog(shipId)
  self.m_tabWidgets.tween_dongHua:ResetToBeginning()
  self.m_tabWidgets.tween_dongHua:Play(true)
  noticeManager:CloseTip()
  local tabHeroInfo = Data.heroData:GetHeroById(shipId)
  local htid = tabHeroInfo.TemplateId
  local shipInfoId = configManager.GetDataById("config_ship_main", htid).ship_info_id
  self.shipId = configManager.GetDataById("config_ship_info", shipInfoId).sf_id
  local ok, data = Logic.discussLogic:TryGetDisData(self.shipId)
  if ok then
    self:_ShowDiscussInfo(data)
  end
end

function Discuss_Page:_GetDiscussCallBack()
  local data = Data.discussData:GetStartDiscussData()
  self:_ShowDiscussInfo(data)
end

function Discuss_Page:_ShowDiscussInfo(data)
  self.m_tabSerStartDiscussData = data
  self.m_tabmsgInfo = data.MsgInfo
  self:SetEvalueteInfo(#self.m_tabmsgInfo)
end

function Discuss_Page:SetEvalueteInfo(nEvaluateNum)
  self.m_tabWidgets.im_girl:SetActive(nEvaluateNum <= 0)
  self.m_tabWidgets.ill_EvaluateContent.gameObject:SetActive(0 < nEvaluateNum)
  if nEvaluateNum <= 0 then
    return
  end
  UIHelper.SetInfiniteItemParam(self.m_tabWidgets.ill_EvaluateContent, self.m_tabWidgets.obj_EvaluateItem, nEvaluateNum, function(tabPart)
    local tabTemp = {}
    for k, v in pairs(tabPart) do
      tabTemp[tonumber(k)] = v
    end
    for index, luaPart in pairs(tabTemp) do
      self:_SetEvaluateItem(index, luaPart)
    end
  end)
end

function Discuss_Page:_SetEvaluateItem(index, tabPart)
  local txt_msg, txt_name, txt_num
  txt_msg = self.m_tabmsgInfo[index].Msg
  txt_name = self.m_tabmsgInfo[index].Name
  txt_num = self:_getUILikeNum(self.m_tabmsgInfo[index].LikeNum)
  tabPart.obj_Hot:SetActive(index <= self.mHotCommentMaxNum)
  tabPart.txt_OEvaluateCon.text = txt_msg
  tabPart.txt_OplayerName.text = txt_name
  tabPart.txt_OPraiseNum.text = txt_num
  if type(self.m_tabmsgInfo[index].Level) ~= "number" then
    tabPart.txt_userLv.text = ""
  else
    tabPart.txt_userLv.text = "LV." .. Mathf.ToInt(self.m_tabmsgInfo[index].Level)
  end
  tabPart.btn_Praise.gameObject:SetActive(self.m_tabmsgInfo[index].IsLiked == 0)
  tabPart.btn_Praised.gameObject:SetActive(self.m_tabmsgInfo[index].IsLiked ~= 0)
  tabPart.btn_NoPraise.gameObject:SetActive(self.m_tabmsgInfo[index].IsDisLiked == 0)
  tabPart.btn_NoPraised.gameObject:SetActive(self.m_tabmsgInfo[index].IsDisLiked ~= 0)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_Praise, function()
    self:_ClickLikeFresh(index, tabPart)
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_Praised, function()
    noticeManager:OpenTipPage(self, 140219)
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_NoPraise, function()
    self:_ClickDislikeFresh(index, tabPart)
  end)
  UGUIEventListener.AddButtonOnClick(tabPart.btn_NoPraised, function()
    noticeManager:OpenTipPage(self, 140220)
  end)
end

function Discuss_Page:_getUILikeNum(data)
  if data - 10 > 999 then
    return "999+"
  elseif data - 10 < 0 then
    return 0
  else
    return Mathf.ToInt(data - 10)
  end
end

function Discuss_Page:_ClickLikeFresh(index, tabPart)
  if self:_checkLock() then
    return
  end
  Service.discussService:SendLike(self.shipId, self.m_tabmsgInfo[index].MsgID)
  self.m_tabmsgInfo[index].IsLiked = time.getSvrTime()
  self.m_tabmsgInfo[index].LikeNum = self.m_tabmsgInfo[index].LikeNum + 1
  local txt_num
  if self.m_tabmsgInfo[index].LikeNum - 10 + 1 > 999 then
    txt_num = "999+"
  else
    txt_num = self:_getUILikeNum(self.m_tabmsgInfo[index].LikeNum)
  end
  tabPart.txt_OPraiseNum.text = math.tointeger(txt_num)
  tabPart.btn_Praise.gameObject:SetActive(false)
  tabPart.btn_Praised.gameObject:SetActive(true)
  noticeManager:OpenTipPage(self, 140224)
end

function Discuss_Page:_ClickDislikeFresh(index, tabPart)
  if self:_checkLock() then
    return
  end
  local sameDay = time.isSameDay(self.m_tabSerStartDiscussData.DisLikeTime, time.getSvrTime())
  if self.m_tabSerStartDiscussData.DisLikeNum + 1 > self.disLikeMaxNum and sameDay then
    noticeManager:OpenTipPage(self, 140221, self.disLikeMaxNum)
    return
  else
    Service.discussService:SendDislike(self.shipId, self.m_tabmsgInfo[index].MsgID)
    self.m_tabmsgInfo[index].LikeNum = self.m_tabmsgInfo[index].LikeNum - 1
    self.m_tabmsgInfo[index].IsDisLiked = time.getSvrTime()
    local txt_num
    txt_num = self:_getUILikeNum(self.m_tabmsgInfo[index].LikeNum)
    tabPart.txt_OPraiseNum.text = math.tointeger(txt_num)
    tabPart.btn_NoPraise.gameObject:SetActive(false)
    tabPart.btn_NoPraised.gameObject:SetActive(true)
  end
end

function Discuss_Page:_ClickSend()
  if self:_checkLock() then
    return
  end
  local commentMaxLength = Logic.discussLogic:GetCommentMaxNum()
  self.discussContent = self.m_tabWidgets.input_content.text
  local sendLength = utf8.len(self.discussContent)
  local sameDay = time.isSameDay(self.m_tabSerStartDiscussData.MsgTime, time.getSvrTime())
  if sameDay then
    noticeManager:OpenTipPage(self, UIHelper.GetString(920000226))
  elseif sendLength ~= 0 then
    if commentMaxLength < sendLength then
      noticeManager:OpenTipPage(self, 140222, commentMaxLength)
    else
      local mask = Logic.chatLogic:HaveMask(self.discussContent)
      if mask then
        noticeManager:ShowTip(UIHelper.GetString(220003))
        return
      end
      Service.discussService:SendDiscuss(self.shipId, self.discussContent)
      Service.discussService:SendGetDiscuss(self.shipId)
    end
  else
    noticeManager:OpenTipPage(self, UIHelper.GetString(920000227))
  end
end

function Discuss_Page:_DiscussCallBack()
  self.m_tabWidgets.input_content.text = ""
end

function Discuss_Page:_checkLock()
  local illustrateState = Logic.illustrateLogic:GetIllustrateState(self.shipId)
  if illustrateState ~= IllustrateState.UNLOCK then
    noticeManager:ShowTip(UIHelper.GetString(920000228))
    return true
  end
  return false
end

function Discuss_Page:DoHide()
  self:DestroyAllEffect()
  self:StopAllTimer()
  self:CloseTopPage()
  self:DoOnHide()
  eventManager:SendEvent(LuaEvent.OnPageHide, self:GetName())
end

function Discuss_Page:DoOnHide(...)
  if self.m_tabWidgets.tween_IlluDiscussPage ~= nil then
    self.m_tabWidgets.tween_IlluDiscussPage:Stop()
  end
end

function Discuss_Page:DoOnClose(...)
end

return Discuss_Page
