local DialogPlot = class("UI.Plot.DialogPlot")

function DialogPlot:initialize(parent, tabWidget)
  self.m_tabWidgets = tabWidget
  self.parent = parent
  self.tabRoleImagePos = self:_GetRoleImagePos()
  self.tabWidgetInfo = self:_GetWidgetLevel()
  self.tabRoleRootPos = self:_GetRoleRootPos()
  self.tabRoleInitPos = self:_GetRoleInitPos()
  self.printTimer = nil
  self.allShowText = ""
  self.showText = ""
  self.curPlotInfo = nil
  self.tabRecordShowRole = {}
  self.roleActionTimer = {}
  self.roleProcedureActionEnd = {}
  self:InitObjActive()
  self.outScreenRole = {}
  self.tweenTimers = {}
  self.BGTweenTimers = {}
  plotManager.plotOver = false
  self.playEffects = {}
end

local RoleMovePosType = {
  None = 0,
  Left = 1,
  Mid = 2,
  Right = 3,
  LeftOut = -1,
  RightOut = -2,
  UpOut = -3,
  DownOut = -4
}
local tweenParam = {
  [RoleMovePosType.LeftOut] = {
    {
      x = -864,
      y = 0,
      z = 0
    },
    {
      x = -864,
      y = 0,
      z = 0
    },
    {
      x = -864,
      y = 0,
      z = 0
    }
  },
  [RoleMovePosType.RightOut] = {
    {
      x = 859,
      y = 0,
      Z = 0
    },
    {
      x = 859,
      y = 0,
      Z = 0
    },
    {
      x = 859,
      y = 0,
      Z = 0
    }
  },
  [RoleMovePosType.UpOut] = {
    {
      x = 0,
      y = 666,
      z = 0
    },
    {
      x = 0,
      y = 666,
      z = 0
    },
    {
      x = 0,
      y = 666,
      z = 0
    }
  },
  [RoleMovePosType.DownOut] = {
    {
      x = 0,
      y = -666,
      z = 0
    },
    {
      x = 0,
      y = -666,
      z = 0
    },
    {
      x = 0,
      y = -666,
      z = 0
    }
  }
}
local RolePos = {
  None = 0,
  Left = 1,
  Middle = 2,
  Right = 3
}
local RoleMoveType = {Gleam = 0, Easy = 1}
local RoleActionType = {
  Once = 1,
  Loop = 2,
  PingPong = 3
}
local RoleOffest = {
  [1] = "left_ship_center",
  [2] = "middle_ship_center",
  [3] = "right_ship_center"
}

function DialogPlot:_RestRoleState()
  for i, v in ipairs(self.tabWidgetInfo) do
    v.CavasGroup.alpha = 1
    v.Root:SetActive(false)
    v.Root.transform.localScale = Vector3.New(1, 1, 1)
    v.ActionTween.enabled = false
    v.ActionTween.style = 0
    v.ActionTween.duration = 0
    v.ActionTween:ResetToBeginning()
    v.Im:GetComponent(RectTransform.GetClassType()).localRotation = {
      x = 0,
      y = 0,
      z = 0,
      w = 1
    }
  end
end

function DialogPlot:_GetRoleImagePos()
  local tabTemp = {}
  tabTemp[1] = self.m_tabWidgets.obj_leftRole:GetComponent(RectTransform.GetClassType())
  tabTemp[2] = self.m_tabWidgets.obj_midRole:GetComponent(RectTransform.GetClassType())
  tabTemp[3] = self.m_tabWidgets.obj_rightRole:GetComponent(RectTransform.GetClassType())
  return tabTemp
end

function DialogPlot:_GetRoleInitPos()
  local tabTemp = {}
  tabTemp[1] = self.m_tabWidgets.obj_leftRole:GetComponent(RectTransform.GetClassType()).anchoredPosition
  tabTemp[2] = self.m_tabWidgets.obj_midRole:GetComponent(RectTransform.GetClassType()).anchoredPosition
  tabTemp[3] = self.m_tabWidgets.obj_rightRole:GetComponent(RectTransform.GetClassType()).anchoredPosition
  return tabTemp
end

function DialogPlot:_GetRoleRootPos()
  local tabTemp = {}
  tabTemp[1] = self.m_tabWidgets.root_leftRole:GetComponent(RectTransform.GetClassType()).anchoredPosition
  tabTemp[2] = self.m_tabWidgets.root_midRole:GetComponent(RectTransform.GetClassType()).anchoredPosition
  tabTemp[3] = self.m_tabWidgets.root_rightRole:GetComponent(RectTransform.GetClassType()).anchoredPosition
  return tabTemp
end

function DialogPlot:_GetWidgetLevel()
  local RoleWeidgetInfo = {
    {
      Root = self.m_tabWidgets.root_leftRole,
      Obj = self.m_tabWidgets.obj_leftRole,
      Im = self.m_tabWidgets.im_leftRole,
      Txt = self.m_tabWidgets.txt_leftRole,
      Tween = self.m_tabWidgets.tween_leftRole,
      Expression = self.m_tabWidgets.im_leftExpression,
      ObjName = self.m_tabWidgets.obj_leftName,
      ActionTween = self.m_tabWidgets.actionTween_leftRole,
      Alpha = self.m_tabWidgets.alpha_leftRole,
      CavasGroup = self.m_tabWidgets.left_role_cg,
      Scale = self.m_tabWidgets.scale_left_role
    },
    {
      Root = self.m_tabWidgets.root_midRole,
      Obj = self.m_tabWidgets.obj_midRole,
      Im = self.m_tabWidgets.im_midRole,
      Txt = self.m_tabWidgets.txt_midRole,
      Tween = self.m_tabWidgets.tween_midRole,
      Expression = self.m_tabWidgets.im_midExpression,
      ObjName = self.m_tabWidgets.obj_midName,
      ActionTween = self.m_tabWidgets.actionTween_midRole,
      Alpha = self.m_tabWidgets.alpha_midRole,
      CavasGroup = self.m_tabWidgets.mid_role_cg,
      Scale = self.m_tabWidgets.scale_mid_role
    },
    {
      Root = self.m_tabWidgets.root_rightRole,
      Obj = self.m_tabWidgets.obj_rightRole,
      Im = self.m_tabWidgets.im_rightRole,
      Txt = self.m_tabWidgets.txt_rightRole,
      Tween = self.m_tabWidgets.tween_rightRole,
      Expression = self.m_tabWidgets.im_rightExpression,
      ObjName = self.m_tabWidgets.obj_rightName,
      ActionTween = self.m_tabWidgets.actionTween_rightRole,
      Alpha = self.m_tabWidgets.alpha_rightRole,
      CavasGroup = self.m_tabWidgets.right_role_cg,
      Scale = self.m_tabWidgets.scale_right_role
    }
  }
  return RoleWeidgetInfo
end

function DialogPlot:InitObjActive()
  for k, v in pairs(self.tabWidgetInfo) do
    v.Root:SetActive(false)
    v.ObjName:SetActive(false)
  end
  self:_InitRoleActionInfo()
end

function DialogPlot:PlayPlot(plotTab, index)
  self.ClickTime = -100
  self.dispearMaxTime = 0
  plotManager.plotOver = false
  self.nextCallBack = nil
  self.plotIndex = index
  self.talkerPos = nil
  for k, v in pairs(self.tabWidgetInfo) do
    v.ObjName:SetActive(false)
  end
  if self.ResetOrder ~= nil then
    self.ResetOrder:Stop()
  end
  self.curPlotInfo = plotTab[index]
  local plotInfo = self.curPlotInfo
  self:HideEffect(plotInfo)
  self.offsets = self:GetInitialOffset(plotInfo)
  self.textWidget = self.m_tabWidgets.txt_talk
  if plotInfo.show_dialog ~= 0 then
    self.textWidget = self.m_tabWidgets.txt_background
  end
  self.textWidget.fontSize = plotInfo.text_size
  self.textWidget.text = self.allShowText
  self:_RestRoleState()
  self:_SetBackGround(plotInfo)
  self:_SetCurName(plotInfo)
  if plotInfo.talker_id ~= 0 then
    self:SetCurTalkerRoleInfo(plotInfo)
  end
  self:_ShowOtherRoles(plotInfo)
  self:_AnotherRolesAction(plotInfo)
  self:_ShakeScreen(plotInfo)
  self:_ShakeDialog(plotInfo)
  self:_AddEffects(plotInfo)
  self:_PlayMultiScreenEffects(plotInfo)
  self:_PlayAudio(plotInfo)
  if self.talkerPos then
    local transIndex = 0
    for i = 1, 3 do
      if i ~= self.talkerPos then
        self.tabWidgetInfo[i].Root.transform:SetSiblingIndex(transIndex)
        transIndex = transIndex + 1
      end
    end
    self.tabWidgetInfo[self.talkerPos].Root.transform:SetSiblingIndex(transIndex)
  end
  if plotInfo.show_dialog == 0 or plotInfo.show_dialog == 1 then
    self:ShowTypewriting(plotInfo)
  else
    self:ShowlyricsRollUp(plotInfo, plotTab, index)
  end
  self:_ShowDialog(plotInfo)
end

function DialogPlot:ShowlyricsRollUp(plotInfo, plotTab, index)
  if plotInfo.cut_scentence == 1 then
    if self.txtLines == nil then
      self.txtLines = {}
    end
    for i = 1, #self.txtLines do
      self.txtLines[i].gameObject:SetActive(false)
    end
    local next
    local count = 1
    for i = index, #plotTab do
      next = plotTab[i]
      if next.show_dialog == 2 then
        local b = next.cut_scentence == 1 and index == i or next.cut_scentence > 1
        if b == true then
          if self.txtLines[count] == nil then
            local tempTex = GameObject.Instantiate(self.m_tabWidgets.txt_node.gameObject, self.m_tabWidgets.txt_viewNode)
            table.insert(self.txtLines, tempTex:GetComponent(UIText.GetClassType()))
            tempTex:SetActive(true)
          end
          self.txtLines[count].text = next.content
          count = count + 1
        else
          break
        end
      else
        break
      end
    end
    self.__rollIndex = 0
    self.__highlightedPos = Vector2.New(0, 0)
  end
  local moveDis = self.__rollIndex * self.m_tabWidgets.txt_node.rectTransform.sizeDelta.y
  local endPos = Vector2.New(self.__highlightedPos.x, self.__highlightedPos.y + moveDis)
  local startPos = self.m_tabWidgets.txt_viewNode.anchoredPosition
  local time = 0
  local duration = 0.3
  local deltaTime = 0.01
  local rollaction = function()
    time = time + deltaTime
    local t = time / duration
    local h = 0
    h = 1.5707963 * (t * t * t)
    t = ((-1 * (t - 1) * (t - 1) + 1) * 100 + 2 * math.sin(h)) / 100
    self.m_tabWidgets.txt_viewNode.anchoredPosition = Vector2.Lerp(startPos, endPos, t)
  end
  self.__Timer = Timer.New(rollaction, deltaTime, duration / deltaTime, false)
  self.__Timer:Start()
  self.__rollIndex = self.__rollIndex + 1
end

function DialogPlot:ShowTypewriting(plotInfo)
  self.allShowText = ""
  self.textWidget.text = ""
  self.showText = tostring(self.textWidget.text)
  self.allShowText = self.allShowText .. plotInfo.content
  self:_StopPrintTimer()
  local curIndex = 1
  local sample_text, split_text, colors = self.parent:Parse(plotInfo.content)
  local strLen = utf8Helper.SubStringGetTotalIndex(sample_text)
  local showTextContent = function()
    curIndex = curIndex + 1
    local curbyteIndex = utf8Helper.SubStringGetTrueEndIndex(sample_text, curIndex)
    if curbyteIndex == nil then
      self:_StopPrintTimer()
      curIndex = 1
    else
      self.textWidget.text = self.showText .. self.parent:GetRichText(curbyteIndex, sample_text, split_text, colors)
      if curIndex > strLen then
        self:_StopPrintTimer()
        curIndex = 1
      end
    end
  end
  self.printTimer = Timer.New(showTextContent, self.parent.nfontSpeed, strLen, false)
  self.printTimer:Start()
  if self.allShowText ~= nil and self.allShowText ~= "" then
    self.allShowText = self.parent:GetAllRichContent(self.allShowText)
  end
end

function DialogPlot:ClickNext(callBack)
  if plotManager.plotOver == true then
    return
  end
  if self.ClickTime == nil then
    self.ClickTime = 0
  end
  if time.getSvrTime() - self.ClickTime < self.dispearMaxTime then
    return
  end
  self.ClickTime = time.getSvrTime()
  self:_StopActionTimer(false)
  self:_StopTweenTimers(false)
  if self.printTimer ~= nil and self.printTimer.running then
    self:_StopPrintTimer()
    self.textWidget.text = self.allShowText
  else
    function self.nextCallBack()
      callBack()
    end
    
    self:_MoveRoleDispear(self.curPlotInfo)
  end
end

function DialogPlot:_ShowDialog(plotinfo)
  if plotinfo.show_dialog == 0 then
    self.m_tabWidgets.txt_talk.transform.parent.gameObject:SetActive(true)
    self.m_tabWidgets.txt_backgroundRoot:SetActive(false)
  end
  if plotinfo.show_dialog == 1 then
    self.m_tabWidgets.txt_talk.transform.parent.gameObject:SetActive(false)
    self.m_tabWidgets.txt_backgroundRoot:SetActive(true)
    self.m_tabWidgets.txt_background.gameObject:SetActive(true)
    self.m_tabWidgets.roll:SetActive(false)
  end
  if plotinfo.show_dialog == 2 then
    self.m_tabWidgets.txt_talk.transform.parent.gameObject:SetActive(false)
    self.m_tabWidgets.txt_backgroundRoot:SetActive(true)
    self.m_tabWidgets.txt_background.gameObject:SetActive(false)
    self.m_tabWidgets.roll:SetActive(true)
  end
end

function DialogPlot:ShowInfoDir(plotTab, index)
  if self.plotIndex == nil then
    self.plotIndex = 1
  end
  self:_ShowSkipRole(plotTab, index)
  self.plotIndex = index
  if self.printTimer ~= nil then
    self:_StopPrintTimer()
  end
  self:_SetTalkText(plotTab[index])
  self:_ShowDialog(plotTab[index])
end

function DialogPlot:_ShowSkipRole(plotTab, index)
  local initIndex = self.plotIndex
  for i = index, self.plotIndex, -1 do
    if plotTab[i].plot_episode_type ~= PlotType.NormalDialog then
      initIndex = i + 1
      break
    end
  end
  if initIndex ~= self.plotIndex then
    self.tabRecordShowRole = {}
  end
  for i = initIndex, index do
    self:_SetSinglePlotRole(plotTab[i])
  end
  self.offsets = self:GetInitialOffset(plotTab[index])
  self:_ShowSkipRoleImp()
end

function DialogPlot:_SetTalkText(plotInfo)
  self:HideEffect(plotInfo)
  self:_PlayMultiScreenEffects(plotInfo)
  for k, v in pairs(self.tabWidgetInfo) do
    v.ObjName:SetActive(false)
  end
  self.curPlotInfo = plotInfo
  self.textWidget = self.m_tabWidgets.txt_talk
  if plotInfo.show_dialog ~= 0 then
    self.textWidget = self.m_tabWidgets.txt_background
  end
  self.textWidget.fontSize = plotInfo.text_size
  self.textWidget.text = self.allShowText
  self:_SetBackGround(plotInfo)
  self:_SetCurName(plotInfo)
  if plotInfo.cut_scentence == 1 then
    self.allShowText = ""
  end
  self.allShowText = self.allShowText .. plotInfo.content
  self.textWidget.text = self.parent:GetAllRichContent(self.allShowText)
end

function DialogPlot:_ShowSkipRoleImp()
  for i = 1, 3 do
    local k = i
    local v = self.tabRecordShowRole[i]
    local root_role = self.tabWidgetInfo[k].Root
    if v then
      local plotShipConf = Logic.plotLogic:GetPlotShipConfById(v)
      local obj_role = self.tabWidgetInfo[k].Obj
      local img_role = self.tabWidgetInfo[k].Im
      local obj_expresion = self.tabWidgetInfo[k].Expression
      obj_expresion.gameObject:SetActive(false)
      img_role.fillCenter = true
      root_role:SetActive(true)
      UIHelper.SetImage(img_role, plotShipConf.ship_res_path)
      local rt = img_role.gameObject:GetComponent(RectTransform.GetClassType())
      rt.localRotation = Quaternion.Euler(0, 0, plotShipConf.euler) * rt.localRotation
      local tempPos, scale = self:_SetRoleOffest(k, plotShipConf)
      tempPos = self:AddOffset(k, tempPos)
      rt.anchoredPosition = tempPos
      rt.localScale = scale
      img_role:SetNativeSize()
      self:_SetMaskEnable(k, false)
    else
      root_role.gameObject:SetActive(false)
    end
  end
end

function DialogPlot:_SetSinglePlotRole(plotInfo)
  local talkerPos
  if plotInfo.talker_id > 0 and 0 < #plotInfo.talker_initial_position then
    talkerPos = plotInfo.talker_initial_position[1]
    self.tabRecordShowRole[talkerPos] = plotInfo.talker_id
  end
  for k, v in pairs(plotInfo.meanwhile_ship) do
    self.tabRecordShowRole[v[2]] = v[1]
  end
  if 0 < #plotInfo.talker_next_position and talkerPos then
    if 0 < plotInfo.talker_next_position[1] then
      self.tabRecordShowRole[plotInfo.talker_next_position[1]] = self.tabRecordShowRole[talkerPos]
    end
    self.tabRecordShowRole[talkerPos] = nil
  end
  for k, v in pairs(plotInfo.other_talker_next_position) do
    if 0 < v[2] then
      self.tabRecordShowRole[v[2]] = self.tabRecordShowRole[v[1]]
    end
    self.tabRecordShowRole[v[1]] = nil
  end
end

function DialogPlot:_SetBackGround(plotInfo)
  if plotInfo.cut_bg_animation == 1 then
    self:_StopBGTweenTimers()
    self.m_tabWidgets.im_dialogBg.rectTransform.localScale = Vector3.one
    self.m_tabWidgets.im_dialogBg.rectTransform.anchoredPosition = Vector3.zero
    self.m_tabWidgets.im_dialogBg.rectTransform.localRotation = Quaternion.Euler(0, 0, 0)
  end
  if conditionCheckManager:Checkvalid(plotInfo.static_scene_res_path) then
    self.m_tabWidgets.im_dialogBgStatic.gameObject:SetActive(true)
    UIHelper.SetImage(self.m_tabWidgets.im_dialogBgStatic, plotInfo.static_scene_res_path)
  else
    self.m_tabWidgets.im_dialogBgStatic.gameObject:SetActive(false)
  end
  if conditionCheckManager:Checkvalid(plotInfo.scene_res_path) then
    if plotInfo.cut_bg_animation == 1 then
      self.m_tabWidgets.im_dialogBg.gameObject:SetActive(true)
      UIHelper.SetImage(self.m_tabWidgets.im_dialogBg, plotInfo.scene_res_path)
      self.m_tabWidgets.im_dialogBg:SetNativeSize()
    end
    if plotInfo.cut_bg_animation == 1 and plotInfo.bg_animation ~= nil and 0 < #plotInfo.bg_animation then
      local tweens = Logic.plotLogic:GetPlotTweenEffectConfig(plotInfo.bg_animation)
      self:__PlayBackgroundTweenAnima(tweens, 0)
    end
  elseif plotInfo.cut_bg_animation == 1 then
    self.m_tabWidgets.im_dialogBg.gameObject:SetActive(false)
  end
end

function DialogPlot:_InitPosData(pos)
  if pos and 0 < pos then
    self.tabWidgetInfo[pos].Root:SetActive(false)
    self.tabWidgetInfo[pos].ActionTween.enabled = false
  end
end

function DialogPlot:InitData()
  self:InitObjActive()
  self.tabRecordShowRole = {}
  self.textWidget.text = ""
end

function DialogPlot:_StopPrintTimer()
  if self.printTimer then
    self.printTimer:Stop()
    self.printTimer = nil
  end
end

function DialogPlot:_StopActionTimer(destory)
  for k, v in pairs(self.roleActionTimer) do
    for p, q in pairs(v) do
      q:Stop()
      q = nil
    end
  end
  for k, v in pairs(self.roleProcedureActionEnd) do
    if destory then
    else
      v()
    end
  end
  self.roleProcedureActionEnd = {}
  self.roleActionTimer = {}
end

function DialogPlot:_StopTweenTimers(destory)
  for k, v in pairs(self.tweenTimers) do
    self.parent:StopTimer(v)
  end
  if self.shakeDialogTimer ~= nil then
    self.shakeDialogTimer:Stop()
  end
  if self.shakeScreenTimer ~= nil then
    self.shakeScreenTimer:Stop()
  end
  self.tweenTimers = {}
end

function DialogPlot:_StopBGTweenTimers()
  for k, v in pairs(self.BGTweenTimers) do
    self.parent:StopTimer(v)
  end
  self.BGTweenTimers = {}
end

function DialogPlot:Destroy()
  self:_StopPrintTimer()
  self:_StopActionTimer(true)
  self:_StopTweenTimers(true)
  self.nextCallBack = nil
  plotManager.plotOver = true
end

function DialogPlot:_MoveRoleDispear(plotInfo)
  self:_MoveUnTalkDispear(plotInfo)
  if plotInfo.talker_id > 0 then
    self:_MoveTalkerDispear(plotInfo)
  end
  self:CheckDispearTime(plotInfo)
end

function DialogPlot:CheckDispearTime(plotInfo)
  self.dispearMaxTime = 0
  for k, v in pairs(plotInfo.Gradually_disappear) do
    self.dispearMaxTime = math.max(self.dispearMaxTime, v[2])
  end
  if plotInfo.black_scene_timing == 2 then
    if plotInfo.black_scene[2] ~= nil then
      self.dispearMaxTime = math.max(self.dispearMaxTime, plotInfo.black_scene[2])
    end
    if plotInfo.black_scene[3] ~= nil then
      self.dispearMaxTime = math.max(self.dispearMaxTime, plotInfo.black_scene[3])
    end
  end
  self.dispearMaxTime = self.dispearMaxTime + 0.1
  if self.DispearCoolTimer ~= nil then
    self.DispearCoolTimer:Stop()
  end
  self.DispearCoolTimer = Timer.New(function()
    if self.nextCallBack ~= nil then
      self.nextCallBack()
    end
    for k, v in pairs(self.outScreenRole) do
      if v ~= nil then
        v()
      end
    end
    self.outScreenRole = {}
  end, self.dispearMaxTime, 1, false)
  self.DispearCoolTimer:Start()
end

function DialogPlot:_MoveTalkerDispear(plotInfo)
  local pos = plotInfo.talker_initial_position[1]
  if pos and 0 < pos then
    if 0 < #plotInfo.talker_next_position then
      local endPos = plotInfo.talker_next_position[1]
      local moveWay = plotInfo.talker_next_position[2]
      self:_MoveTalkerImp(plotInfo, pos, endPos, moveWay)
    else
      local mask = self:_CheckNeedMask(self.curPlotInfo, pos)
      self.tabWidgetInfo[pos].Root.gameObject:SetActive(true)
    end
  end
end

function DialogPlot:_MoveUnTalkDispear(plotInfo)
  local info = plotInfo.other_talker_next_position
  if 0 < #info then
    for k, v in pairs(info) do
      if 0 < #v then
        local prePos = v[1]
        local endPos = v[2]
        local moveWay = v[3]
        self:_MoveTalkerImp(plotInfo, prePos, endPos, moveWay)
      end
    end
  else
  end
end

function DialogPlot:_MoveTalkerImp(plotInfo, prePos, endPos, moveWay)
  local fromPos, toPos, tweenObj, callBack, plotShipConf
  if self.tabRecordShowRole[prePos] == nil then
    return
  end
  if 0 < endPos then
    self.tabRecordShowRole[endPos] = self.tabRecordShowRole[prePos]
  end
  if endPos ~= prePos then
    self.tabRecordShowRole[prePos] = nil
  end
  if endPos == 0 then
    self:_PlayRoleAlpha(self.tabWidgetInfo[prePos].Alpha, prePos, plotInfo, false, function()
      self.tabWidgetInfo[prePos].Alpha:ResetToBeginning()
      self:_InitPosData(prePos)
    end)
    return
  end
  if 0 < endPos then
    local mask = self:_CheckNeedMask(self.curPlotInfo, prePos)
    self:_SetMaskEnable(endPos, mask)
    self:_InitPosData(prePos)
    self:_SetTalkerRoleMoveInfo(plotInfo, endPos, self.tabRecordShowRole[endPos])
    fromPos = self.tabRoleRootPos[prePos]
    fromPos = self:AddOffset(prePos, fromPos)
    toPos = self.tabRoleRootPos[endPos]
    tweenObj = self.tabWidgetInfo[endPos].Tween
    local tweenconfig = Logic.plotLogic:GetPlotTweensConfig(plotInfo.talker_tween, endPos)
    local delay_time = 0
    if tweenconfig ~= nil and 0 < #tweenconfig then
      delay_time = tweenconfig[1].delay_time
    end
    
    function callBack()
      if self.tabRecordShowRole[endPos] ~= self.curPlotInfo.talker_id then
        local mask = self:_CheckNeedMask(self.curPlotInfo, endPos)
        self:_SetMaskEnable(endPos, mask)
      end
      self.roleActionTimer[endPos] = {}
      self.roleActionTimer[endPos][1] = Timer.New(function()
        self:_SetRoleAction(plotInfo, endPos)
      end, delay_time, 1, false)
      self.roleActionTimer[endPos][1]:Start()
    end
  elseif endPos < 0 then
    local tempObj = UIHelper.CreateGameObject(self.tabWidgetInfo[prePos].Root, self.tabWidgetInfo[prePos].Root.transform.parent)
    tweenObj = tempObj:GetComponent(TweenPosition.GetClassType())
    fromPos = self.tabRoleRootPos[prePos]
    local posDif = tweenParam[endPos][prePos]
    toPos = Vector3.New(fromPos.x + posDif.x, fromPos.y + posDif.y, 0)
    self:_InitPosData(prePos)
    
    function callBack()
      if plotManager.plotOver == false and not IsNil(tempObj) then
        GameObject.Destroy(tempObj)
      end
    end
    
    table.insert(self.outScreenRole, callBack)
  end
  if moveWay == RoleMoveType.Easy then
    self:_FlyInTween(fromPos, toPos, tweenObj, callBack)
  else
    for k, v in ipairs(self.outScreenRole) do
      if v == callBack then
        table.remove(self.outScreenRole, k)
        break
      end
    end
    callBack()
  end
end

function DialogPlot:_SetRoleAction(plotInfo, pos)
  plotInfo = self.curPlotInfo
  local tweentable = Logic.plotLogic:GetPlotTweensConfig(plotInfo.talker_tween, pos)
  local tweenInfo
  if 0 < #tweentable then
    tweenInfo = tweentable[1]
  end
  if tweenInfo ~= nil and tweenInfo.talker_tween_type == 2 then
    local tweenObj = self.tabWidgetInfo[pos].ActionTween
    local objPos = self.tabRoleImagePos[pos].anchoredPosition
    local xFrom = objPos.x
    local xTo = objPos.x
    local yFrom = objPos.y
    local yTo = objPos.y
    if 0 < #tweenInfo.talker_action_x then
      xFrom = xFrom + tweenInfo.talker_action_x[1]
      xTo = xTo + -1 * tweenInfo.talker_action_x[2]
    end
    if 0 < #tweenInfo.talker_action_y then
      yFrom = yFrom + tweenInfo.talker_action_y[1]
      yTo = yTo + -1 * tweenInfo.talker_action_y[2]
    end
    tweenObj.from = Vector3.New(xFrom, yFrom, 0)
    tweenObj.to = Vector3.New(xTo, yTo, 0)
    tweenObj.duration = tweenInfo.talker_action_oncetime
    tweenObj.style = tweenInfo.talker_action_type - 1
    tweenObj.enabled = true
    local tempPos = objPos
    local useTimer = false
    local timerDuration = 0
    if tweenInfo.talker_action_type == RoleActionType.PingPong and 0 < tweenInfo.talker_action_number then
      useTimer = true
      timerDuration = tweenInfo.talker_action_number * 2 * tweenInfo.talker_action_oncetime
    end
    tweenObj:ResetToBeginning()
    tweenObj:Play(true)
    if useTimer then
      do
        local endAction = function()
          tweenObj.enabled = false
          self.tabRoleImagePos[pos].anchoredPosition = tempPos
        end
        if self.roleActionTimer[pos] == nil then
          self.roleActionTimer[pos] = {}
        end
        self.roleActionTimer[pos][2] = Timer.New(endAction, timerDuration, 1, false)
        self.roleActionTimer[pos][2]:Start()
        table.insert(self.roleProcedureActionEnd, endAction)
      end
    end
  end
  if 0 < #tweentable then
    self:__PlayRoleTweenAnima(tweentable, pos, 0)
  end
end

function DialogPlot:_SetTalkerRoleMoveInfo(plotInfo, pos, talkerId)
  local plotShipConf = Logic.plotLogic:GetPlotShipConfById(talkerId)
  local root_role = self.tabWidgetInfo[pos].Root
  local obj_role = self.tabWidgetInfo[pos].Obj
  local img_role = self.tabWidgetInfo[pos].Im
  local obj_name = self.tabWidgetInfo[pos].ObjName
  local obj_expresion = self.tabWidgetInfo[pos].Expression
  root_role:SetActive(true)
  obj_name:SetActive(false)
  UIHelper.SetImage(img_role, plotShipConf.ship_res_path)
  local tempPos, scale = self:_SetRoleOffest(pos, plotShipConf)
  tempPos = self:AddOffset(pos, tempPos)
  obj_role.gameObject:GetComponent(RectTransform.GetClassType()).anchoredPosition = tempPos
  local rt = img_role.gameObject:GetComponent(RectTransform.GetClassType())
  rt.localScale = scale
  rt.localRotation = Quaternion.Euler(0, 0, plotShipConf.euler) * rt.localRotation
  self:_SetRoleExpression(pos, plotInfo, talkerId)
  img_role:SetNativeSize()
end

function DialogPlot:_SetMaskEnable(pos, mask)
  if 0 < pos then
    local obj_mask = self.tabWidgetInfo[pos].Im
    local obj_expresion = self.tabWidgetInfo[pos].Expression
    obj_mask.color = mask and Color.New(0.6, 0.6, 0.6, 1) or Color.New(1, 1, 1, 1)
    obj_expresion.color = mask and Color.New(0.6, 0.6, 0.6, 1) or Color.New(1, 1, 1, 1)
    if mask == true then
    end
  end
end

function DialogPlot:AddOffset(index, pos)
  if self.offsets[index] ~= nil then
    pos.x = pos.x + self.offsets[index].x
    pos.y = pos.y + self.offsets[index].y
  end
  return pos
end

function DialogPlot:GetInitialOffset(plotinfo)
  local offsets = {}
  if plotinfo.initial_position_offset ~= nil then
    for k, v in ipairs(plotinfo.initial_position_offset) do
      if #v == 3 then
        offsets[v[1]] = {
          x = v[2],
          y = v[3]
        }
      end
    end
  end
  return offsets
end

function DialogPlot:_FlyInTween(fromPos, toPos, tweenObj, callBack)
  tweenObj.from = Vector3.New(fromPos.x, fromPos.y, 0)
  tweenObj.to = Vector3.New(toPos.x, toPos.y, 0)
  local difx = math.abs(fromPos.x - toPos.x)
  local dify = math.abs(fromPos.y - toPos.y)
  local dif = difx > dify and difx or dify
  local speed = configManager.GetDataById("config_parameter", 83).value
  local duration = dif / speed
  tweenObj.duration = duration
  tweenObj:SetOnFinished(function()
    if callBack then
      callBack()
    end
  end)
  tweenObj:ResetToBeginning()
  tweenObj:Play(true)
end

function DialogPlot:_AnotherRolesAction(plotInfo)
  local notMove = {
    [1] = 1,
    [2] = 1,
    [3] = 1
  }
  if plotInfo.talker_initial_position[1] then
    notMove[plotInfo.talker_initial_position[1]] = nil
  end
  for k, v in pairs(plotInfo.meanwhile_ship) do
    notMove[v[2]] = nil
  end
  for k, v in pairs(notMove) do
    if self.tabRecordShowRole[k] then
      self.roleActionTimer[k] = {}
      local tweenconfig = Logic.plotLogic:GetPlotTweensConfig(plotInfo.talker_tween, k)
      local delay_time = 0
      if tweenconfig ~= nil and 0 < #tweenconfig then
        delay_time = tweenconfig[1].delay_time
      end
      self.roleActionTimer[k][1] = Timer.New(function()
        self:_SetRoleAction(plotInfo, k)
      end, delay_time, 1, false)
      self.roleActionTimer[k][1]:Start()
    end
  end
end

function DialogPlot:_ShowOtherRoles(plotInfo)
  for k, v in pairs(plotInfo.meanwhile_ship) do
    local talkerId = v[1]
    local pos = v[2]
    local moveWay = v[3]
    local mask = self:_CheckNeedMask(plotInfo, pos)
    self:_SetTalkerRoleInfo(pos, moveWay, talkerId, plotInfo, mask)
  end
end

function DialogPlot:_AddEffects(plotInfo)
  if conditionCheckManager:Checkvalid(plotInfo.screen_effect) then
    local effectObj = self.parent:GetScreenEffect(plotInfo)
    effectObj.transform:SetParent(self.m_tabWidgets.front_effect_root.transform, false)
    effectObj.transform.position = Vector3.New(0, 0, 0)
    effectObj.gameObject:SetActive(true)
    local com = effectObj:GetComponent(UISortEffectComponent.GetClassType())
    if com == nil then
      com = effectObj:AddComponent(UISortEffectComponent.GetClassType())
    end
    self:SetEffectOrder(com)
    table.insert(self.playEffects, effectObj)
  end
end

function DialogPlot:SetEffectOrder(effectObj)
  self.ResetOrder = FrameTimer.New(function()
    local canvas = effectObj:GetComponentInParent(typeof(CS.UnityEngine.Canvas))
    effectObj.orderSort = 1
    local transform = effectObj:GetComponent(Transform.GetClassType())
    local renders = {}
    renders = self:GetAllEffectRender(transform, renders)
    for i = 1, #renders do
      local __render = renders[i]
      if __render.sortingOrder ~= nil then
      end
      __render.sortingOrder = canvas.sortingOrder + i
      __render.sortingLayerName = effectObj.sortLayerName
    end
  end, 0, 0)
  if effectObj.name == "eff_ui_plot_theworld_01(Clone)" then
    local msRenders = effectObj:GetComponentsInChildren(typeof(CS.UnityEngine.MeshRenderer), true)
    local radio = math.max(ResolutionHelper.real2Standard, 1)
    if msRenders.Length ~= 0 then
      for i = 0, msRenders.Length - 1 do
        local __render = msRenders[i]
        __render.transform.localScale = Vector3.New(__render.transform.localScale.x * radio, __render.transform.localScale.y, 1)
      end
    end
  end
  self.ResetOrder:Start()
end

function DialogPlot:GetAllEffectRender(transform, renderList)
  if renderList == nil then
    renderList = {}
  end
  local childCount = transform.childCount
  for i = 0, childCount - 1 do
    local child = transform:GetChild(i)
    local render = child.gameObject:GetComponent(typeof(CS.UnityEngine.Renderer))
    if IsNil(render) then
      render = child.gameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
    end
    if not IsNil(render) then
      table.insert(renderList, render)
    end
    if child.childCount > 0 then
      renderList = self:GetAllEffectRender(child, renderList)
    end
  end
  return renderList
end

function DialogPlot:_PlayMultiScreenEffects(plotInfo)
  if plotInfo.new_screen_effect == nil or type(plotInfo.new_screen_effect) ~= "table" then
    return
  end
  if self.last_effectTab == nil then
    self.last_effectTab = {}
  end
  local _effectTabTmp = {}
  if next(plotInfo.new_screen_effect) ~= nil then
    local effect_conf
    for i = 1, #plotInfo.new_screen_effect do
      effect_conf = plotInfo.new_screen_effect[i]
      if 3 <= #effect_conf then
        _effectTabTmp[effect_conf[1]] = {effect_conf, nil}
      end
    end
  end
  for k, v in pairs(self.last_effectTab) do
    if _effectTabTmp[k] == nil then
      if v[2] ~= nil then
        v[2].gameObject:SetActive(false)
      end
      self.last_effectTab[k] = nil
    elseif _effectTabTmp[k][1][3] == 1 then
      if v[2] ~= nil then
        v[2].gameObject:SetActive(false)
        v[2].gameObject:SetActive(true)
        local com = v[2]:GetComponent(UISortEffectComponent.GetClassType())
        if com == nil then
          com = v[2]:AddComponent(UISortEffectComponent.GetClassType())
        end
        self:SetEffectOrder(com)
        _effectTabTmp[k][2] = v[2]
        if _effectTabTmp[k][1][4] ~= nil then
          local animator = v[2]:GetComponentInChildren(UnityEngine_Animator.GetClassType())
          animator:SetInteger("Open", _effectTabTmp[k][1][4])
        end
      end
    else
      _effectTabTmp[k][2] = v[2]
      if _effectTabTmp[k][1][4] ~= nil then
        local animator = v[2]:GetComponentInChildren(UnityEngine_Animator.GetClassType())
        animator:SetInteger("Open", _effectTabTmp[k][1][4])
      end
    end
  end
  for k, v in pairs(_effectTabTmp) do
    if _effectTabTmp[k][2] == nil then
      local effres = Logic.plotLogic:GetPlotEffectConfById(_effectTabTmp[k][1][1])
      if conditionCheckManager:Checkvalid(effres.effect_res) then
        local effectObj = self.parent:CreateUIEffect(effres.effect_res)
        if _effectTabTmp[k][1][2] == 1 then
          effectObj.transform:SetParent(self.m_tabWidgets.front_effect_root.transform, false)
        elseif _effectTabTmp[k][1][2] == 0 then
          effectObj.transform:SetParent(self.m_tabWidgets.back_effect_root.transform, false)
        end
        local com = effectObj:GetComponent(UISortEffectComponent.GetClassType())
        if com == nil then
          com = effectObj:AddComponent(UISortEffectComponent.GetClassType())
        end
        effectObj.transform.position = Vector3.New(0, 0, 0)
        effectObj.gameObject:SetActive(true)
        self:SetEffectOrder(com)
        self.last_effectTab[_effectTabTmp[k][1][1]] = {
          _effectTabTmp[k][1],
          effectObj
        }
      end
    end
  end
end

function DialogPlot:HideEffect(plotInfo)
  if plotInfo.cut_screen_effect == nil or plotInfo.cut_screen_effect == 1 then
    for k, v in ipairs(self.playEffects) do
      v.gameObject:SetActive(false)
    end
    self.playEffects = {}
  end
end

function DialogPlot:_PlayAudio(plotInfo)
  local audioinfo = Logic.plotLogic:GetPlotAudioInfoConfigById(plotInfo.plot_episode_step_id, plotInfo.plot_episode_id)
  if audioinfo ~= nil and conditionCheckManager:Checkvalid(audioinfo.audio_effect) and not plotManager.MuteEffect then
    local effects = string.split(audioinfo.audio_effect, ",")
    if 0 < #effects then
      for _, e in ipairs(effects) do
        SoundManager.Instance:PlayAudio(e)
      end
    end
    Logic.plotMaker.audio_effect = audioinfo.audio_effect
  end
end

function DialogPlot:_ShakeScreen(plotInfo)
  if next(plotInfo.screen_animation) then
    local tweens = Logic.plotLogic:GetPlotTweenEffectConfig(plotInfo.screen_animation)
    local useTimer = false
    local timerDuration = 0
    local tweenObj
    local delay_time = 0
    if #tweens ~= 0 then
      delay_time = tweens[1].delay_time
      self.shakeScreenTimer = Timer.New(function()
        if #tweens ~= 0 then
          local style = tweens[1].talker_action_type
          local x = tweens[1].talker_action_x[1]
          local y = tweens[1].talker_action_y[1]
          local times = tweens[1].talker_action_number
          local duration = tweens[1].talker_action_oncetime
          tweenObj = self.m_tabWidgets.tween_page
          tweenObj.from = Vector3.New(x, y, 0)
          tweenObj.to = Vector3.New(-1 * x, -1 * y, 0)
          tweenObj.duration = duration
          tweenObj.style = style - 1
          tweenObj.enabled = true
          if style == RoleActionType.PingPong and 0 < times then
            useTimer = true
            timerDuration = duration * 2 * times
          end
          tweenObj:ResetToBeginning()
          tweenObj:Play(true)
        end
        if useTimer then
          self.screenTimer = self.parent:CreateTimer(function()
            tweenObj.enabled = false
            tweenObj.gameObject:GetComponent(RectTransform.GetClassType()).anchoredPosition = Vector3.New(0, 0, 0)
          end, timerDuration, 1, false)
          self.parent:StartTimer(self.screenTimer)
        end
      end, delay_time, 1, false)
      self.shakeScreenTimer:Start()
    end
  end
end

function DialogPlot:_ShakeDialog(plotInfo)
  if next(plotInfo.dialog_animation) then
    local tweens = Logic.plotLogic:GetPlotTweenEffectConfig(plotInfo.dialog_animation)
    local useTimer = false
    local timerDuration = 0
    local tweenObj, tweenObjNativePos
    local delay_time = 0
    if #tweens ~= 0 then
      delay_time = tweens[1].delay_time
      self.shakeDialogTimer = Timer.New(function()
        if 0 < #tweens then
          local style = tweens[1].talker_action_type
          local x = tweens[1].talker_action_x[1]
          local y = tweens[1].talker_action_y[1]
          local times = tweens[1].talker_action_number
          local duration = tweens[1].talker_action_oncetime
          tweenObj = self.m_tabWidgets.tween_dialog
          tweenObjNativePos = tweenObj.gameObject:GetComponent(RectTransform.GetClassType()).anchoredPosition
          tweenObj.from = Vector3.New(tweenObjNativePos.x + x, tweenObjNativePos.y + y, 0)
          tweenObj.to = Vector3.New(tweenObjNativePos.x - x, tweenObjNativePos.y - y, 0)
          tweenObj.duration = duration
          tweenObj.style = style - 1
          tweenObj.enabled = true
          if style == RoleActionType.PingPong and 0 < times then
            useTimer = true
            timerDuration = duration * 2 * times
          end
          tweenObj:ResetToBeginning()
          tweenObj:Play(true)
        end
        if useTimer then
          self.dialogTimer = self.parent:CreateTimer(function()
            tweenObj.enabled = false
            tweenObj.gameObject:GetComponent(RectTransform.GetClassType()).anchoredPosition = tweenObjNativePos
          end, timerDuration, 1, false)
          self.parent:StartTimer(self.dialogTimer)
        end
      end, delay_time, 1, false)
      self.shakeDialogTimer:Start()
    end
  end
end

function DialogPlot:__PlayRoleTweenAnima(tweenList, endPos, maxtime)
  for k, v in pairs(tweenList) do
    if v.talker_tween_type == 1 then
      self:___PlayAlpha(maxtime, v, self.tabWidgetInfo[endPos].Alpha, self.tweenTimers)
    elseif v.talker_tween_type == 3 then
      self:___PlayRotate(maxtime, v, self.tabWidgetInfo[endPos].Rotate, self.tweenTimers)
    elseif v.talker_tween_type == 4 then
      self:___PlayScale(maxtime, v, self.tabWidgetInfo[endPos].Scale, self.tweenTimers)
    end
  end
end

function DialogPlot:__PlayBackgroundTweenAnima(tweenList, maxtime)
  for k, v in pairs(tweenList) do
    if v.talker_tween_type == 1 then
      self:___PlayAlpha(maxtime, v, self.m_tabWidgets.tAlpha_dialogBg, self.BGTweenTimers)
    elseif v.talker_tween_type == 3 then
      self:___PlayRotate(maxtime, v, self.m_tabWidgets.tRotate_dialogBg, self.BGTweenTimers)
    elseif v.talker_tween_type == 4 then
      self:___PlayScale(maxtime, v, self.m_tabWidgets.tScale_dialogBg, self.BGTweenTimers)
    elseif v.talker_tween_type == 2 then
      self:___PlayMove(maxtime, v, self.m_tabWidgets.tMove_dialogBg, self.BGTweenTimers)
    end
  end
end

function DialogPlot:___PlayRotate(maxtime, tween_data, tweenObj, action, tweenTimers)
  local useTimer = false
  local timerDuration = 0
  local style = tween_data.talker_action_type
  local z_begin = tween_data.talker_action_z[1]
  local z_end = tween_data.talker_action_z[2]
  local times = tween_data.talker_action_number
  local duration = tween_data.talker_action_oncetime
  tweenObj.from = Vector3.New(0, 0, z_begin)
  tweenObj.to = Vector3.New(0, 0, z_end)
  tweenObj.duration = duration
  tweenObj.style = style - 1
  tweenObj.enabled = true
  if style == RoleActionType.PingPong and 0 < times then
    useTimer = true
    timerDuration = duration * 2 * times
  end
  tweenObj:ResetToBeginning()
  tweenObj:Play(true)
  if useTimer then
    local tweentimer = self.parent:CreateTimer(function()
      tweenObj.enabled = false
      if action ~= nil then
        action()
      end
    end, timerDuration, 1, false)
    self.parent:StartTimer(tweentimer)
    table.insert(tweenTimers, tweentimer)
  end
end

function DialogPlot:___PlayMove(maxtime, tween_data, tweenObj, action, tweenTimers)
  local useTimer = false
  local timerDuration = 0
  local style = tween_data.talker_action_type
  local x = tween_data.talker_action_x[1]
  local y = tween_data.talker_action_y[1]
  local to_x = tween_data.talker_action_x[2]
  local to_y = tween_data.talker_action_y[2]
  local times = tween_data.talker_action_number
  local duration = tween_data.talker_action_oncetime
  tweenObj.from = Vector3.New(x, y, 0)
  tweenObj.to = Vector3.New(to_x, to_y, 0)
  tweenObj.duration = duration
  tweenObj.style = style - 1
  tweenObj.enabled = true
  if style == RoleActionType.PingPong and 0 < times then
    useTimer = true
    timerDuration = duration * 2 * times
  end
  tweenObj:ResetToBeginning()
  tweenObj:Play(true)
  if useTimer then
    local tweentimer = self.parent:CreateTimer(function()
      tweenObj.enabled = false
      if action ~= nil then
        action()
      end
    end, timerDuration, 1, false)
    self.parent:StartTimer(tweentimer)
    table.insert(tweenTimers, tweentimer)
  end
end

function DialogPlot:___PlayAlpha(maxtime, tween_data, tweenObj, action, tweenTimers)
  local useTimer = false
  local timerDuration = 0
  local style = tween_data.talker_action_type
  local from = tween_data.talker_action_from
  local to = tween_data.talker_action_to
  local times = tween_data.talker_action_number
  local duration = tween_data.talker_action_oncetime
  tweenObj.from = from
  tweenObj.to = to
  tweenObj.duration = duration
  tweenObj.style = style - 1
  tweenObj.enabled = true
  if style == RoleActionType.PingPong and 0 < times then
    useTimer = true
    timerDuration = duration * 2 * times
  end
  tweenObj:ResetToBeginning()
  tweenObj:Play(true)
  if useTimer then
    local tweentimer = self.parent:CreateTimer(function()
      tweenObj.enabled = false
      if action ~= nil then
        action()
      end
    end, timerDuration, 1, false)
    self.parent:StartTimer(tweentimer)
    table.insert(tweenTimers, tweentimer)
  end
end

function DialogPlot:___PlayScale(maxtime, tween_data, tweenObj, action, tweenTimers)
  local useTimer = false
  local timerDuration = 0
  local style = tween_data.talker_action_type
  local x = tween_data.talker_action_x[1]
  local y = tween_data.talker_action_y[1]
  local to_x = tween_data.talker_action_x[2]
  local to_y = tween_data.talker_action_y[2]
  local times = tween_data.talker_action_number
  local duration = tween_data.talker_action_oncetime
  tweenObj.from = Vector3.New(x, y, 0)
  tweenObj.to = Vector3.New(to_x, to_y, 0)
  tweenObj.duration = duration
  tweenObj.style = style - 1
  tweenObj.enabled = true
  if style == RoleActionType.PingPong and 0 < times then
    useTimer = true
    timerDuration = duration * 2 * times
  end
  tweenObj:ResetToBeginning()
  tweenObj:Play(true)
  if useTimer then
    local tweentimer = self.parent:CreateTimer(function()
      tweenObj.enabled = false
      if action ~= nil then
        action()
      end
    end, timerDuration, 1, false)
    self.parent:StartTimer(tweentimer)
    table.insert(tweenTimers, tweentimer)
  end
end

function DialogPlot:_SetTalkerRoleInfo(endPos, moveWay, talkerId, plotInfo, mask)
  local prePos = moveWay
  moveWay = moveWay < 0 and 1 or moveWay
  local tempPos = self:_CheckTalkerIsInPage(talkerId)
  if tempPos ~= nil and self:_CurTalkerInPage(tempPos, endPos) then
    prePos = tempPos
  end
  self:_SetTalkerRoleImp(plotInfo, prePos, endPos, moveWay, talkerId, mask)
  self.tabRecordShowRole[endPos] = talkerId
end

function DialogPlot:SetCurTalkerRoleInfo(plotInfo)
  if #plotInfo.talker_initial_position > 0 then
    local endPos = plotInfo.talker_initial_position[1]
    self.talkerPos = endPos
    local moveWay = plotInfo.talker_initial_position[2]
    self:_SetTalkerRoleInfo(endPos, moveWay, plotInfo.talker_id, plotInfo, false)
  end
end

function DialogPlot:_SetTalkerRoleImp(plotInfo, prePos, endPos, moveWay, talkerId, mask)
  local obj_role, img_role, obj_tween, im_expression, alpha_role, root_role
  if 0 < endPos then
    root_action = self.tabWidgetInfo[endPos].ActionTween
    root_role = self.tabWidgetInfo[endPos].Root
    obj_role = self.tabWidgetInfo[endPos].Obj
    img_role = self.tabWidgetInfo[endPos].Im
    obj_tween = self.tabWidgetInfo[endPos].Tween
    im_expression = self.tabWidgetInfo[endPos].Expression
    alpha_role = self.tabWidgetInfo[endPos].Alpha
    root_role:SetActive(0 < talkerId)
    img_role.gameObject:SetActive(0 < endPos)
    root_action.enabled = false
  end
  if talkerId <= 0 then
    return
  end
  self:_PlayRoleAlpha(alpha_role, endPos, plotInfo, true, nil)
  self:_SetMaskEnable(endPos, false)
  local plotShipConf = Logic.plotLogic:GetPlotShipConfById(talkerId)
  UIHelper.SetImage(img_role, plotShipConf.ship_res_path)
  img_role.fillCenter = true
  img_role:SetNativeSize()
  local tempPos, scale = self:_SetRoleOffest(endPos, plotShipConf)
  tempPos = self:AddOffset(endPos, tempPos)
  obj_role.gameObject:GetComponent(RectTransform.GetClassType()).anchoredPosition = tempPos
  img_role.gameObject:GetComponent(RectTransform.GetClassType()).localScale = scale
  local tween_im = img_role:GetComponent(TweenPosition.GetClassType())
  local rolePos = endPos
  local rect_roleImage = img_role.gameObject:GetComponent(RectTransform.GetClassType())
  if self:_CheckNeedMirror(plotInfo, rolePos) then
    rect_roleImage.rotation = {
      x = 0,
      y = 180,
      z = 0,
      w = 1
    }
  else
    rect_roleImage.rotation = {
      x = 0,
      y = 0,
      z = 0,
      w = 1
    }
  end
  rect_roleImage.rotation = Quaternion.Euler(0, 0, plotShipConf.euler) * rect_roleImage.rotation
  self:_SetRoleExpression(endPos, plotInfo, talkerId)
  local fromPos
  local toPos = self.tabRoleRootPos[endPos]
  if prePos < 0 then
    local posDif = tweenParam[prePos][endPos]
    fromPos = Vector3.New(toPos.x + posDif.x, toPos.y + posDif.y, 0)
  else
    fromPos = self.tabRoleRootPos[prePos]
  end
  local callBack = function()
    self:_SetMaskEnable(endPos, mask)
    self.roleActionTimer[endPos] = {}
    local tweenconfig = Logic.plotLogic:GetPlotTweensConfig(plotInfo.talker_tween, endPos)
    local delay_time = 0
    if tweenconfig ~= nil and 0 < #tweenconfig then
      delay_time = tweenconfig[1].delay_time
    end
    self.roleActionTimer[endPos][1] = Timer.New(function()
      self:_SetRoleAction(plotInfo, endPos)
    end, delay_time, 1, false)
    self.roleActionTimer[endPos][1]:Start()
  end
  local tweenObj = self.tabWidgetInfo[endPos].Tween
  if moveWay == RoleMoveType.Easy then
    self:_FlyInTween(fromPos, toPos, tweenObj, callBack)
  else
    callBack()
  end
end

function DialogPlot:_PlayRoleAlpha(alpha_role, pos, plotInfo, forward, callBack)
  local info = forward and plotInfo.Gradually_appear or plotInfo.Gradually_disappear
  for k, v in pairs(info) do
    if v[1] == pos then
      local from = forward and 0 or 1
      local to = 1 - from
      alpha_role.from = from
      alpha_role.to = to
      alpha_role.duration = v[2]
      alpha_role.enabled = true
      alpha_role:SetOnFinished(function()
        alpha_role.enabled = false
        if callBack then
          callBack()
        end
      end)
      alpha_role:ResetToBeginning()
      alpha_role:Play(true)
      return
    end
  end
end

function DialogPlot:_CheckNeedMask(plotInfo, pos)
  for k, v in pairs(plotInfo.is_mask) do
    if v == pos then
      return false
    end
  end
  return true
end

function DialogPlot:_CheckNeedMirror(plotInfo, pos)
  local mirror = plotInfo.mirror
  for k, v in pairs(mirror) do
    if v == pos then
      return true
    end
  end
  return false
end

function DialogPlot:_GetExpression(plotInfo, pos)
  local expressions = plotInfo.talker_expression
  for k, v in pairs(expressions) do
    if #v == 2 and v[1] == pos then
      return Logic.plotLogic:GetPlotExpressionInfoConfigById(v[2])
    end
  end
  return nil
end

function DialogPlot:_CheckTalkerIsInPage(talkerId)
  if self.tabRecordShowRole ~= nil then
    for k, v in pairs(self.tabRecordShowRole) do
      if v == talkerId then
        return k
      end
    end
  end
  return nil
end

function DialogPlot:_CurTalkerInPage(rolePos, targetPos)
  if rolePos ~= targetPos and 0 < targetPos then
    self.tabRecordShowRole[rolePos] = nil
    self:_InitPosData(rolePos)
    return true
  end
  return false
end

function DialogPlot:_SetCurName(plotInfo)
  local pos = 1
  if plotInfo.talker_initial_position[1] ~= nil then
    pos = plotInfo.talker_initial_position[1] == 0 and 1 or plotInfo.talker_initial_position[1]
  end
  local obj_name = self.tabWidgetInfo[pos].ObjName
  local txt_name = self.tabWidgetInfo[pos].Txt
  local haveName = conditionCheckManager:Checkvalid(plotInfo.talker_name)
  obj_name:SetActive(haveName)
  if haveName then
    local nameTab = self.parent:GetContent(plotInfo.talker_name)
    if 0 > plotInfo.talker_id then
      nameTab.content = Data.userData:GetUserName()
    end
    txt_name.text = string.format(nameTab.color, nameTab.content)
  end
end

function DialogPlot:_SetRoleExpression(rolePos, plotInfo, talkerId)
  local widgetInfo = self.tabWidgetInfo[rolePos]
  local exfg = self:_GetExpression(plotInfo, rolePos)
  if conditionCheckManager:Checkvalid(exfg) then
    widgetInfo.Expression.gameObject:SetActive(true)
    UIHelper.SetImage(widgetInfo.Expression, exfg.expression_res)
    widgetInfo.Expression:SetNativeSize()
    widgetInfo.Im.fillCenter = false
    local express_pos = self:_SetRoleExpressionPos(rolePos, talkerId)
    local express_rect = widgetInfo.Expression.gameObject:GetComponent(RectTransform.GetClassType())
    express_rect.anchoredPosition = express_pos
  else
    widgetInfo.Expression.gameObject:SetActive(false)
    widgetInfo.Im.fillCenter = true
  end
end

function DialogPlot:_SetRoleExpressionPos(rolePos, talkerId)
  local pos = self.tabWidgetInfo[rolePos].Im:GetComponent(RectTransform.GetClassType()).anchoredPosition
  local plotShipConf = Logic.plotLogic:GetPlotShipConfById(talkerId)
  local expressionPoint = plotShipConf.expression_point
  local tempPos = {
    x = expressionPoint[1],
    y = expressionPoint[2]
  }
  return tempPos
end

function DialogPlot:_SetRoleOffest(pos, plotShipConf)
  local tabParam
  if pos == RolePos.Left then
    tabParam = plotShipConf.left_ship_center
  elseif pos == RolePos.Middle then
    tabParam = plotShipConf.middle_ship_center
  elseif pos == RolePos.Right then
    tabParam = plotShipConf.right_ship_center
  else
    logError("emmmm\230\178\161\230\156\137\230\173\164\229\143\130\230\149\176")
  end
  local tempPos = {
    x = self.tabRoleInitPos[pos].x + tabParam[1],
    y = self.tabRoleInitPos[pos].y + tabParam[2]
  }
  local scale = Vector3.one * tabParam[4]
  return tempPos, scale
end

function DialogPlot:_InitRoleActionInfo()
  self.tabWidgetInfo[1].ActionTween.enabled = false
  self.tabWidgetInfo[2].ActionTween.enabled = false
  self.tabWidgetInfo[3].ActionTween.enabled = false
end

return DialogPlot
