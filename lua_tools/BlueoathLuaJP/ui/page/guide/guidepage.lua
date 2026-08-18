local GuidePage = class("UI.Guide.GuidePage", LuaUIPage)
local bRegister = false

function GuidePage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  GR.guideHub:onPageOpen(self)
  self.objSelectCopyPage = nil
end

function GuidePage:DoOnOpen()
  self:SetRayCastSize(Vector2.New(0, 1))
  local curType = stageMgr:GetCurStageType()
  self:_OnEnterStage(curType)
end

function GuidePage:FullTorpedoNumActive(bActive)
  self.m_tabWidgets.fullTorpedo:SetActive(bActive)
end

function GuidePage:TickDisplay(bTick)
  self.m_tabWidgets.tickDisplay:SetActive(bTick)
end

function GuidePage:ShowGuideGirl(bShow, nPosId, strLanId)
  self.m_tabWidgets.guideGirl:SetActive(bShow)
  if bShow then
    local transGirl, transDialog
    transGirl, transDialog = self:GetTransRootById(nPosId)
    CSUIHelper.SetParent(self.m_tabWidgets.transGirlImg, transGirl)
    CSUIHelper.SetParent(self.m_tabWidgets.transGuideTxt, transDialog)
    local strtxt = UIHelper.GetString(strLanId)
    self.m_tabWidgets.txtGuide.text = strtxt
  else
    self.m_tabWidgets.guideGirl:SetActive(bActive)
  end
end

function GuidePage:GetTransRootById(nPosId)
  local posType = type(nPosId)
  local tranRoot = self.m_tabWidgets.transGuideGirl
  local strPath1, strPath2
  if posType == "number" then
    strPath1 = "pos" .. nPosId .. "/girlPos"
    strPath2 = "pos" .. nPosId .. "/duihuaPos"
  else
    strPath1 = nPosId .. "/girlPos"
    strPath2 = nPosId .. "/duihuaPos"
  end
  local transGirlPos = tranRoot:Find(strPath1)
  local transDuihuaPos = tranRoot:Find(strPath2)
  return transGirlPos, transDuihuaPos
end

function GuidePage:ShowResetAirAttack(bShow)
  self.m_tabWidgets.resetAirAttackCD:SetActive(bShow)
end

function GuidePage:SetRayCastSize(vecMin, vecMax)
  if vecMin.x == 0 and vecMin.y == 0 then
    self.m_tabWidgets.transRayCast.offsetMax = Vector3.New(500, 500)
    self.m_tabWidgets.transRayCast.offsetMin = Vector3.New(-500, -500)
  elseif vecMin.x == 0 and vecMin.y == 0.8 then
    self.m_tabWidgets.transRayCast.offsetMax = Vector3.New(500, 500)
    self.m_tabWidgets.transRayCast.offsetMin = Vector3.New(-500, 0)
  else
    self.m_tabWidgets.transRayCast.offsetMax = Vector3.New(0, 0)
    self.m_tabWidgets.transRayCast.offsetMin = Vector3.New(0, 0)
  end
  if vecMin ~= nil then
    self.m_tabWidgets.transRayCast.anchorMin = vecMin
  end
  if vecMax ~= nil then
    self.m_tabWidgets.transRayCast.anchorMax = vecMax
  end
end

function GuidePage:ShowBlackMask(bShow)
  self.m_tabWidgets.objBlackMask:SetActive(bShow)
end

function GuidePage:ShowConver(bShow)
  self.m_tabWidgets.objClickMask:SetActive(bShow)
end

function GuidePage:EnableElement(nElementId, bCanSelfCtrl)
  local tblConfig = GR.guideHub:getUserOpeElementConfig(nElementId)
  if tblConfig == nil then
    return
  end
  self.m_tabWidgets.userOpeElement:EnableElement(tblConfig.opePath, tblConfig.opeType, tblConfig.highLightPath, nElementId, bCanSelfCtrl)
end

function GuidePage:DisableElement()
  self.m_tabWidgets.userOpeElement:DisableElement()
end

function GuidePage:ShowSimpleTip(strPath, bShow)
  if strPath == nil or strPath == "" then
    logError("strPath illegal " .. tostring(strPath))
    return
  end
  local transRoot = self.m_tabWidgets.transSimpleTipRoot
  local transTarget = transRoot:Find(strPath)
  if transTarget ~= nil then
    transTarget.gameObject:SetActive(bShow)
  else
    logError("cant find simple tip " .. strPath)
  end
end

function GuidePage:RegisterAllEvent()
  self:_RegisterEvents()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.objOptionalBtn, self.OnClickOptional)
  bRegister = true
end

function GuidePage:init()
  if not bRegister then
    self:_RegisterEvents()
  end
end

function GuidePage:_RegisterEvents()
  self:RegisterEvent(LuaEvent.GuideShowNotice, self.ShowNoticePage)
  self:RegisterEvent(LuaEvent.GuideUserOpe, self.ReleaseNotice)
  self:RegisterEvent(LuaEvent.StageEnter, self._OnEnterStage)
end

function GuidePage:_OnEnterStage(nStageType)
  if nStageType ~= EStageType.eStageLogin then
    self.m_tabWidgets.objHightlightCopyRoot:SetActive(true)
    self.m_tabWidgets.behaviourRoot:SetActive(true)
  else
    self.m_tabWidgets.objHightlightCopyRoot:SetActive(false)
    self.m_tabWidgets.behaviourRoot:SetActive(false)
  end
end

function GuidePage:DisableHighLight()
  self.m_tabWidgets.highLightMask:CancleShowHightLight()
end

function GuidePage:OnClickNotice()
  self:ReleaseNotice()
  eventManager:SendEvent(LuaEvent.GuideUserOpe, 0)
end

function GuidePage:OnClickOptional()
  eventManager:SendEvent(LuaEvent.GuideUserOpe, 0)
end

function GuidePage:Reset()
  self:SetRayCastSize(Vector2.New(0, 1))
  self:ShowBlackMask(false)
  self:FullTorpedoNumActive(false)
  self:TickDisplay(false)
  self:ShowResetAirAttack(false)
  self:ShowOptionalBtn(false)
  if self.objSelectCopyPage ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.objSelectCopyPage)
    self.objSelectCopyPage = nil
  end
  self:ShowGuideGirl(false)
  self:ReleaseNotice()
  self:ReleaseSimpleTip()
  self:UnregisterAllEvent()
  bRegister = false
end

function GuidePage:ReleaseSimpleTip()
  local transRoot = self.m_tabWidgets.transSimpleTipRoot
  local nChildCount = transRoot.childCount
  for i = 0, nChildCount - 1 do
    local transChild = transRoot:GetChild(i)
    if not IsNil(transChild) then
      local objChild = transChild.gameObject
      objChild:SetActive(false)
    end
  end
end

function GuidePage:ReleaseNotice()
  if self.objNotice ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.objNotice)
    self.objNotice = nil
  end
end

function GuidePage:ShowNoticePage(tblParam)
  local nID = tblParam[1]
  local bShowBtn = tblParam[2]
  self.objNotice = self:LoadNoticePage(nID)
  local objLuapart = CSUIHelper.GetObjComponent(self.objNotice, BabelTime.Lobby.UI.LuaPart.GetClassType())
  local tblItems = objLuapart:GetLuaTableParts()
  local transNotice = self.objNotice.transform
  CSUIHelper.SetParent(transNotice, self.m_tabWidgets.transNoticeRoot)
  UGUIEventListener.AddButtonOnClick(tblItems.btnNotice, self.OnClickNotice, self)
  tblItems.btnNotice.gameObject:SetActive(bShowBtn)
end

function GuidePage:ShowSelectCopy(strName)
  local strPath = "ui/pages/guidenotice/copy/" .. strName
  eventManager:SendEvent(LuaEvent.HomeTimerStop)
  self.objSelectCopyPage = GR.objectPoolManager:LuaGetGameObject(strPath)
  local objLuapart = CSUIHelper.GetObjComponent(self.objSelectCopyPage, BabelTime.Lobby.UI.LuaPart.GetClassType())
  local tblItems = objLuapart:GetLuaTableParts()
  local transPage = self.objSelectCopyPage.transform
  CSUIHelper.SetParent(transPage, self.m_tabWidgets.transPageRoot)
  transPage.offsetMin = Vector2.zero
  transPage.offsetMax = Vector2.zero
  UGUIEventListener.AddButtonOnClick(tblItems.btnFight, function()
    self:_OnclickFight()
    eventManager:SendEvent(LuaEvent.GuideUserOpe)
  end, self)
end

function GuidePage:_OnclickFight()
  if self.objSelectCopyPage ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.objSelectCopyPage)
    self.objSelectCopyPage = nil
  end
end

function GuidePage:ShowOptionalBtn(bShow)
  self.m_tabWidgets.objOptionalBtn:SetActive(bShow)
end

function GuidePage:LoadNoticePage(nID)
  local strPath = "ui/pages/guidenotice/guidenotice_" .. nID
  return GR.objectPoolManager:LuaGetGameObject(strPath)
end

function GuidePage:GetAirSearchPoint()
  return self.m_tabWidgets.transAirSearhPoint
end

function GuidePage:ShowSpecial(strPath, bShow)
  local transTarget = self.m_tabWidgets.transSpecialRoot:Find(strPath)
  if not IsNil(transTarget) then
    transTarget.gameObject:SetActive(bShow)
  end
end

return GuidePage
