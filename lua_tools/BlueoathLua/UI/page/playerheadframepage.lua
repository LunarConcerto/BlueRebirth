local PlayerHeadFramePage = class("ui.page.PlayerHeadFramePage", LuaUIPage)

function PlayerHeadFramePage:DoInit()
  self.m_curHeadFrame = 0
  self.m_allHeadFrameList = {}
  self.m_ownedHeadFrameList = {}
  self.m_userInfo = {}
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function PlayerHeadFramePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._CloseHFPage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_confirm, self._ClickConfirm, self)
end

function PlayerHeadFramePage:DoOnOpen()
  self.m_curHeadFrame, _ = Logic.playerHeadFrameLogic:GetNowHeadFrame()
  self.m_allHeadFrameList = Data.playerHeadFrameData:GetAllHeadFrameData()
  self.m_ownedHeadFrameList = Data.playerHeadFrameData:GetOwnedHeadFrameData()
  self:_RefreshView()
end

function PlayerHeadFramePage:_RefreshView()
  self:_ShowHeadFrameList()
  self:_ShowHeadFrameDetail()
end

function PlayerHeadFramePage:_ShowHeadFrameList()
  local allFrameList = self:_MakeAllHeadFrame()
  local ownedFrameList = self.m_ownedHeadFrameList
  local isMarry = Logic.playerHeadFrameLogic:IsSecretaryMarried()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_frameItem, self.tab_Widgets.rect_Content, #allFrameList, function(indexs, tabPart)
    local index = allFrameList[indexs].id
    local frameInfo = self.m_allHeadFrameList[index]
    if index == InitialHeadFrame.Marry then
      tabPart.btn_frameItem.gameObject:SetActive(false)
    end
    if frameInfo == nil then
      tabPart.btn_frameItem.gameObject:SetActive(false)
    else
      if index == InitialHeadFrame.Default and isMarry then
        frameInfo = self.m_allHeadFrameList[InitialHeadFrame.Marry]
      end
      if frameInfo ~= nil then
        local icon, quality = self:__GetUserHead()
        UIHelper.SetImage(tabPart.img_quality, quality)
        UIHelper.SetImage(tabPart.img_icon, icon)
        local frameImg = frameInfo.icon
        UIHelper.SetImage(tabPart.img_frame, frameImg)
        tabPart.img_select.gameObject:SetActive(index == self.m_curHeadFrame)
        tabPart.img_lock.gameObject:SetActive(ownedFrameList[index] == nil)
        UGUIEventListener.AddButtonOnClick(tabPart.btn_frameItem, self._SelectHFItem, self, {id = index})
      end
    end
  end)
end

function PlayerHeadFramePage:__GetUserHead()
  local myData = Data.userData:GetUserData()
  local config = Logic.shipLogic:GetShipShowByHeroId(myData.SecretaryId)
  local shipInfo = Logic.shipLogic:GetShipInfoByHeroId(myData.SecretaryId)
  if config and shipInfo then
    local icon = config.ship_icon5
    local qualityIcon = UserHeadQualityImg[shipInfo.quality]
    return icon, qualityIcon
  end
end

function PlayerHeadFramePage:_ShowHeadFrameDetail()
  local curId = self.m_curHeadFrame
  local widgets = self:GetWidgets()
  local icon, quality = self:__GetUserHead()
  UIHelper.SetImage(widgets.img_quality, quality)
  UIHelper.SetImage(widgets.img_icon, icon)
  local frameInfo = self.m_allHeadFrameList[curId]
  local isMarry = Logic.playerHeadFrameLogic:IsSecretaryMarried()
  if curId == InitialHeadFrame.Default and isMarry then
    frameInfo = self.m_allHeadFrameList[InitialHeadFrame.Marry]
  end
  UIHelper.SetImage(widgets.img_frame, frameInfo.icon)
  UIHelper.SetText(widgets.txt_name, frameInfo.name)
  UIHelper.SetText(widgets.txt_framedesc, frameInfo.description)
  widgets.txt_limit.gameObject:SetActive(self.m_ownedHeadFrameList[curId] == nil)
end

function PlayerHeadFramePage:_CloseHFPage()
  UIHelper.ClosePage("PlayerHeadFramePage")
end

function PlayerHeadFramePage:_ClickConfirm()
  local selectedId = self.m_curHeadFrame
  local isOwned = self.m_ownedHeadFrameList[selectedId]
  if not isOwned then
    noticeManager:ShowTip(UIHelper.GetString(290011))
    return
  end
  if selectedId == InitialHeadFrame.Marry then
    noticeManager:ShowTip(UIHelper.GetString(290010))
    return
  end
  local argTab = {headFrameId = selectedId}
  Service.userService:SetPlayerHeadFrame(argTab)
  noticeManager:ShowTip(UIHelper.GetString(290012))
  self:_CloseHFPage()
end

function PlayerHeadFramePage:_SelectHFItem(go, param)
  self.m_curHeadFrame = param.id
  self:_RefreshView()
end

function PlayerHeadFramePage:_MakeAllHeadFrame()
  local tmp = {}
  local oriTemp = self.m_allHeadFrameList
  for _, v in pairs(oriTemp) do
    table.insert(tmp, v)
  end
  return tmp
end

function PlayerHeadFramePage:DoOnHide()
end

function PlayerHeadFramePage:DoOnClose()
end

function PlayerHeadFramePage:_CallBackFunc()
end

return PlayerHeadFramePage
