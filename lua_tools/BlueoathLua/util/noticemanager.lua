local NoticeManager = class("util.NoticeManager")

function NoticeManager:initialize()
  self.tabNoticeParams = {}
  self.isClose = true
  self.curNoticeOrder = 0
  self.m_boxStack = {}
  self.m_preLayer = nil
end

function NoticeManager:_DealNotice()
  self.curNoticeOrder = self.curNoticeOrder - 1
  eventManager:SendEvent(LuaEvent.UpdataNotice, self.tabNoticeParams[self.curNoticeOrder])
  table.remove(self.tabNoticeParams)
  if self.curNoticeOrder == 0 then
    eventManager:UnregisterEvent(LuaEvent.CloseNotice, self._DealNotice)
  end
end

function NoticeManager:SetIsClose(isClose)
  self.isClose = isClose
end

function NoticeManager:GetIsClose()
  return UIBoxManager.BoxNum <= 0
end

function NoticeManager:OpenTipPage(handler, content, contentNum)
  if type(content) == "number" then
    content = UIHelper.GetString(content)
    if contentNum ~= nil then
      content = string.format(content, contentNum)
    end
  end
  self:ShowTip(content)
end

function NoticeManager:ShowTip(content, position)
  position = position or Vector3.zero
  UIBoxManager:Tips(content, position)
end

function NoticeManager:ShowTipById(languageId, ...)
  local content = string.format(UIHelper.GetString(languageId), ...)
  UIBoxManager:Tips(content, Vector3.zero)
end

function NoticeManager:CloseTip()
  UIBoxManager:CloseTips()
end

function NoticeManager:DestroyAllBox()
  UIBoxManager:DestroyAllBox()
  self:_ResetBoxData()
end

function NoticeManager:ForceCloseBox()
  UIBoxManager:ForceCloseBox()
  self:_ResetBoxData()
end

function NoticeManager:ShowMsgBox(content, tabParams, layer)
  if type(content) == "number" then
    content = UIHelper.GetString(content) or ""
  end
  tabParams = tabParams or {}
  tabParams.msgType = tabParams.msgType or NoticeType.OneButton
  tabParams.nameOk = tabParams.nameOk or "\231\161\174\229\174\154"
  tabParams.nameCancel = tabParams.nameCancel or "\229\143\150\230\182\136"
  layer = layer or UILayer.MAIN
  local callback = function(isOn)
    local len = #self.m_boxStack
    if 0 < len then
      local layer = self.m_boxStack[len]
      self:_TrySetBoxLayer(layer)
      table.remove(self.m_boxStack, len)
    else
      self:_ResetBoxData()
    end
    if tabParams.callback then
      tabParams.callback(isOn)
    end
  end
  self:_RecordBoxLayer()
  if self.m_preLayer then
    table.insert(self.m_boxStack, self.m_preLayer)
  end
  if tabParams.msgType == NoticeType.OneButton then
    UIBoxManager:CreateOneBtnBox(content, tabParams.nameOk, callback, layer)
  else
    UIBoxManager:CreateTwoBtnBox(content, tabParams.nameOk, tabParams.nameCancel, callback, layer)
  end
  self:_TrySetBoxLayer(layer)
end

function NoticeManager:ShowSuperNotice(content, contentTg, tgIsShow, tgIsON, callBackConfirm, callBackCancel, nameCustom, callBackCustom, titleTxt, customTxt, isHideCancel)
  local data = {
    content = content,
    contentTg = contentTg,
    tgIsShow = tgIsShow,
    tgIsON = tgIsON,
    callBackConfirm = callBackConfirm,
    callBackCancel = callBackCancel,
    nameCustom = nameCustom,
    callBackCustom = callBackCustom,
    titleTxt = titleTxt,
    customTxt = customTxt,
    isHideCancel = isHideCancel
  }
  UIHelper.OpenPage("SuperNoticePage", data)
end

function NoticeManager:_TrySetBoxLayer(layer)
  if UIHelper.IsExistPage("NoticePage") then
    local pageObj = UIPageManager:GetPageFromHistory("NoticePage")
    if pageObj then
      local layerRoot = UIManager:GetLayerRoot(layer)
      CSUIHelper.SetParent(pageObj.gameObject.transform, layerRoot)
      pageObj.canvas.sortingLayerName = UIManager:GetCanvasLayerName(layer)
      pageObj:SetAdditionOrder(1000)
    end
  end
end

function NoticeManager:_RecordBoxLayer()
  if UIHelper.IsExistPage("NoticePage") then
    local pageObj = UIPageManager:GetPageFromHistory("NoticePage")
    if pageObj then
      self.m_preLayer = UILayerStr[pageObj.canvas.sortingLayerName]
    end
  end
end

function NoticeManager:_ResetBoxData()
  self.m_preLayer = nil
  self.m_boxStack = {}
end

return NoticeManager
