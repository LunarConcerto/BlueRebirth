SettlementPage = class("UI.Settlement.SettlementPage", LuaUIPage)
SettlementItem = require("ui.page.Settlement.SettlementItem")
CommonRewardItem = require("ui.page.CommonItem")
local HintText = {
  [1] = {
    UIHelper.GetString(100037),
    "uipic_ui_settings_im_heidi",
    UIHelper.GetString(210020),
    "#3A92FF"
  },
  [2] = {
    UIHelper.GetString(100038),
    "uipic_ui_settings_im_heidi",
    UIHelper.GetString(210020),
    "#717983"
  },
  [3] = {
    UIHelper.GetString(100039),
    "uipic_ui_settings_im_heidi",
    UIHelper.GetString(210020),
    "#33FF24"
  },
  [4] = {
    UIHelper.GetString(100040),
    "uipic_ui_settings_im_heidi",
    UIHelper.GetString(210020),
    "#FF9C00"
  },
  [5] = {
    UIHelper.GetString(100041),
    "uipic_ui_settings_im_heidi",
    UIHelper.GetString(210020),
    "#FF9C00"
  }
}
local FriendState = {
  NONE = 0,
  RequestFriend = 1,
  HadReauest = 2,
  Self = 3,
  Friend = 4,
  OthenServerFriend = 5
}

function SettlementPage:DoInit()
  UIHelper.AdapteShipRT(self.tab_Widgets.trans_rawGirl)
  self.m_next = false
end

function SettlementPage:DoOnOpen()
  RetentionHelper.Retention(PlatformDotType.uilog, {info = "settlement"})
  local widgets = self:GetWidgets()
  local param = self.param
  self.m_exitAction = param.exitFunc
  self.otherUsertab = {}
  local userNewLv = param.userNewLv
  local copyInfo = param.copyInfo
  self.m_myItemList = {}
  self.m_myDataList = param.myShipList
  self.m_enemyItemList = {}
  self.m_enemyDataList = param.enemyShipList
  self.m_enemyFleetList = param.enemyFleetInfo
  self.m_enemyFleetShipList = param.enemyFleetShipsInfo
  self.m_rewardDataList = param.rewards
  self.m_rewardItemList = {}
  self.m_matchPlayerInfoList = param.matchPlayerInfos
  self.m_matchPlayShipList = param.matchPlayShipList
  local myFleetList = param.myFleetList
  local myDataList = self.m_myDataList
  local myItemList = self.m_myItemList
  local enemyDataList = self.m_enemyDataList
  local enemyItemList = self.m_enemyItemList
  local enemyFleetList = self.m_enemyFleetList
  local enemyFleetShipList = self.m_enemyFleetShipList
  self.matchMode = false
  if #self.m_matchPlayerInfoList > 1 then
    self.matchMode = true
    self.otherUsertab = Data.battleAutoChatData:GetMatchUserInfoData()
  end
  self:_SetTitle(copyInfo.name)
  self:_SetMyFleetInfo(param.userName, param.myFleetName, userNewLv, myDataList.percent, param.userAddExp)
  self:_SetEnemyFleetInfo(UIHelper.GetString(920000285), enemyDataList.percent)
  if 1 < #myFleetList and not self.matchMode then
    myFleetList = self:RestructFleetList(myFleetList)
    widgets.obj_weteam:SetActive(false)
    widgets.obj_wefleet:SetActive(true)
    local obj_FleetItem = widgets.obj_multiFleet
    local trans_FleetRoot = widgets.trans_multiFleets
    self:_SetPlayerFleetItems(obj_FleetItem, trans_FleetRoot, myFleetList, myItemList, SettlementItem, SettlementItemType.HERO)
  elseif self.matchMode then
    widgets.obj_weteam:SetActive(false)
    widgets.obj_wefleet:SetActive(true)
    local obj_FleetItem = widgets.obj_multiFleet
    local trans_FleetRoot = widgets.trans_multiFleets
    local matchPlayShipList = self:CombinMatchPlayerFleetItems()
    self:_SetMatchPlayerFleetItems(obj_FleetItem, trans_FleetRoot, matchPlayShipList, myItemList)
  else
    widgets.obj_weteam:SetActive(true)
    widgets.obj_wefleet:SetActive(false)
    local obj_myFleetItem = widgets.obj_myFleetItem
    local trans_myFleetRoot = widgets.trans_myFleetRoot
    self:_SetItems(obj_myFleetItem, trans_myFleetRoot, myDataList, myItemList, SettlementItem, SettlementItemType.HERO, false)
  end
  self:RestructMyFleet()
  if 1 < #enemyFleetList then
    self.multiMode = 1
    widgets.obj_enemyTeam:SetActive(false)
    widgets.obj_enemyFleet:SetActive(true)
    local obj_enemyFleetItem1 = widgets.obj_enemyFleetItem1
    local trans_enemyFleetRoot1 = widgets.trans_enemyFleetRoot1
    self:_SetEnemyFleetItems(obj_enemyFleetItem1, trans_enemyFleetRoot1, enemyFleetList, enemyFleetShipList, enemyItemList, SettlementItem, SettlementItemType.HERO)
  else
    self.multiMode = 0
    widgets.obj_enemyTeam:SetActive(true)
    widgets.obj_enemyFleet:SetActive(false)
    local obj_enemyFleetItem = widgets.obj_enemyFleetItem
    local trans_enemyFleetRoot = widgets.trans_enemyFleetRoot
    self:_SetItems(obj_enemyFleetItem, trans_enemyFleetRoot, enemyDataList, enemyItemList, SettlementItem, SettlementItemType.HERO, false)
  end
  self:_CollectAnimators(widgets.obj_root)
  local mvpInfo = Logic.settlementLogic.GetMVPShipInfo(myDataList)
  if mvpInfo then
    self:_CreateShowGirl(mvpInfo)
  else
    widgets.raw_girl.gameObject:SetActive(false)
  end
  self:_SetTopInfo(param.myFleetName, param.grade, param.userNewLv, param.userAddExp, param.userOldLv, param.userOldExp)
  eventManager:SendEvent("hideBattleAutoChatBtn")
end

function SettlementPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  local btn_next = widgets.btn_next
  UGUIEventListener.AddButtonOnClick(btn_next.gameObject, self._OnClickNext, self, {})
  UGUIEventListener.AddButtonOnClick(widgets.btn_member_skip, self._MemberOnSkipClick, self)
  self:RegisterEvent("SETTLEMENT_ShowExp", function(self, ...)
    self:_SetTrigger("Next")
  end)
  self:RegisterEvent("AnimNext", function(self, ...)
    self:_SetTrigger("Next")
  end)
  self:RegisterEvent("PlayMVPAnim", function(self, ...)
    if self.m_showGirl then
      self:_PlayMVPAnim(self.m_showGirl:Get3dObj())
    end
    if self.m_petObject then
      self.m_petObject:PlayMVPAnim()
    end
  end)
  self:RegisterEvent(LuaEvent.FinishSettlementHeroTween, function()
    if not IsNil(self.m_heroTwn) then
      self.m_heroTwn:ResetToEnd()
      self.m_heroTwn:Destroy()
      self.m_heroTwn = nil
    end
  end)
  self:RegisterEvent(LuaCSharpEvent.SettlementShowNextButton, function(self)
    self:_ShowAddExpTween()
  end)
  self:RegisterEvent(LuaCSharpEvent.SettlementEvaluationClose, function(self)
    self:_PlayAudio("Effect_pingjia")
  end)
  self:RegisterEvent(LuaCSharpEvent.SettlementExpTweenBegin, function(self, ...)
    self:_PlayItemExp(...)
    self:_PlayAudio("Effect_jiesuanmianbanyidong")
  end)
  self:RegisterEvent(LuaCSharpEvent.SettlementSlider, function(self)
    self:_PlayPercentAnim()
  end)
  self:RegisterEvent(LuaEvent.SettlementEvaluation, function(self)
    if not self.m_next then
      Logic.settlementLogic:ShowEvaluation()
    end
  end)
  self:RegisterEvent(LuaCSharpEvent.ShowSubtitle, function(self, notification)
    self:_ShowSubtitle(notification)
  end)
  self:RegisterEvent(LuaCSharpEvent.CloseSubtitle, function(self, notification)
    self:_CloseSubtitle()
  end)
  self:RegisterEvent(LuaEvent.GetOtherUserInfoByUid, self._GetOtherUserInfoCallBack, self)
  self.tab_Widgets.group_selectfleet:RegisterToggle(self.tab_Widgets.tog_mainfleet)
  self.tab_Widgets.group_selectfleet:RegisterToggle(self.tab_Widgets.tog_attachedfleet)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.group_selectfleet, self, "", self.SwitchFleetTogs)
end

function SettlementPage:_GetOtherUserInfoCallBack(param)
  local uid = param.Uid
  self.otherUsertab[uid] = param
end

function SettlementPage:DoOnHide()
end

function SettlementPage:DoOnClose()
  local dotinfo = Logic.settlementLogic:DOTSettlementInfo(self.m_myDataList)
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  local dotMood = Logic.settlementLogic:DOTSettlementMood(self.m_myDataList)
  RetentionHelper.Retention(PlatformDotType.uilog, dotMood)
  local dotLove = Logic.settlementLogic:DOTSettlementLove(self.m_myDataList)
  RetentionHelper.Retention(PlatformDotType.uilog, dotLove)
  for _, sItem in pairs(self.m_myItemList) do
    sItem:DoOnClose()
  end
  self.m_myItemList = {}
  for _, sItem in pairs(self.m_enemyItemList) do
    sItem:DoOnClose()
  end
  self.m_myItemList = {}
  self.m_enemyItemList = {}
  self:_DestroyShowGirl()
  settlementSkillItemManager:ForceEndAllItemAnim()
  settlementSkillItemManager:Dispose()
  if self.m_teXiao then
    local name = Logic.settlementLogic:GetBattleGradeConfig(self.param.grade).name
    if name == "SSS" then
      name = "SS"
    end
    local im_teXiao = self.m_teXiao.transform:Find(name).gameObject
    im_teXiao:SetActive(false)
    self:DestroyEffect(self.m_teXiao)
  end
  self:_SetUsrLvUpTween(nil)
end

function SettlementPage:_ShowSubtitle(textContent)
  local widgets = self:GetWidgets()
  widgets.txt_talk.text = textContent
  widgets.obj_talk:SetActive(true)
end

function SettlementPage:_CloseSubtitle()
  local widgets = self:GetWidgets()
  widgets.txt_talk.text = ""
  widgets.obj_talk:SetActive(false)
end

function SettlementPage:_SetTitle(name)
  local widgets = self:GetWidgets()
  local txt_title = widgets.txt_title
  txt_title.text = name
end

function SettlementPage:_SetMyFleetInfo(username, fleetName, lv, blood, exp)
  local widgets = self:GetWidgets()
  local txt_myFleetName = widgets.txt_myFleetName
  local txt_lv = widgets.txt_lv
  local sld_myBlood = widgets.sld_myBlood
  txt_myFleetName.text = fleetName
  txt_lv.text = lv
end

function SettlementPage:_SetTopInfo(fleetName, grade, newLv, addExp, oldLv, oldExp)
  local widgets = self:GetWidgets()
  local teXiaoPath = "effects/prefabs/ui/eff_ui_battleresult"
  local teXiaoObj = self:CreateUIEffect(teXiaoPath, widgets.obj_top.transform)
  local name = Logic.settlementLogic:GetBattleGradeConfig(grade).name
  if name == "SSS" then
    name = "SS"
  end
  local im_teXiao = teXiaoObj.transform:Find(name).gameObject
  self.m_teXiao = teXiaoObj
  im_teXiao:SetActive(true)
  UIHelper.SetText(widgets.txt_topMyFleetName, fleetName)
  local showUser = 0 < addExp
  widgets.obj_usr:SetActive(showUser)
  if showUser then
    UIHelper.SetText(widgets.txt_topLv, oldLv)
    UIHelper.SetText(widgets.txt_topExp, addExp)
    widgets.sld_topMyBlood.value = Logic.settlementLogic:GetUserExpProgress(oldLv, oldExp)
    self:_GenUsrUpTween()
  end
end

function SettlementPage:_SetUsrLvUpTween(tween)
  self.m_usrUpTwn = tween
end

function SettlementPage:_GetUsrLvUpTween()
  return self.m_usrUpTwn
end

function SettlementPage:_GenUsrUpTween()
  local widgets = self:GetWidgets()
  local param = self:GetParam()
  if param.userAddExp <= 0 then
    self:_SetUsrLvUpTween(nil)
    return
  end
  local oldLv = param.userOldLv
  local oldExp = param.userOldExp
  local newLv = param.userNewLv
  local oldProgress = Logic.settlementLogic:GetUserExpProgress(oldLv, oldExp)
  local newProgress = Logic.settlementLogic:GetUserExpProgress()
  local delta = newLv - oldLv
  
  local function getTime(total, from, to)
    return (to - from) * total
  end
  
  local totalTime = 3
  if delta == 0 then
    local seq = UISequence.NewSequence(widgets.sld_topMyBlood.gameObject)
    seq:Append(widgets.sld_topMyBlood:TweenValue(oldProgress, newProgress, getTime(totalTime, oldProgress, newProgress)))
    self:_SetUsrLvUpTween(seq)
  elseif 0 < delta then
    local seq = UISequence.NewSequence(widgets.sld_topMyBlood.gameObject)
    for i = 0, delta do
      if i == 0 then
        seq:Append(widgets.sld_topMyBlood:TweenValue(oldProgress, 1, getTime(totalTime, oldProgress, 1)))
        seq:AppendCallback(function()
          UIHelper.SetText(widgets.txt_topLv, oldLv + i + 1)
        end)
      elseif i == delta then
        seq:Append(widgets.sld_topMyBlood:TweenValue(0, newProgress, getTime(totalTime, 0, newProgress)))
      else
        seq:Append(widgets.sld_topMyBlood:TweenValue(0, 1, totalTime))
        seq:AppendCallback(function()
          UIHelper.SetText(widgets.txt_topLv, oldLv + i + 1)
        end)
      end
    end
    self:_SetUsrLvUpTween(seq)
  else
    logError("Logic Error:settlement user old lv greater then new lv,oldlv:" .. oldLv .. " newlv:" .. newLv)
    return
  end
end

function SettlementPage:_SetEnemyFleetInfo(fleetName1, blood)
  local widgets = self:GetWidgets()
  local txt_enemyFleetName1 = widgets.txt_enemyFleetName1
  local sld_enemyBlood = widgets.sld_enemyBlood
  txt_enemyFleetName1.text = fleetName1
end

function SettlementPage:_SetItems(objSource, transRoot, dataList, itemList, cls, type, isAdd)
  local shipList = itemList
  if not isAdd then
    shipList = clone(shipList)
  end
  local totalNum = #dataList
  for i = #shipList, totalNum, -1 do
    if table.containV(shipList, i) then
      table.remove(shipList, i)
    end
  end
  UIHelper.CreateSubPart(objSource, transRoot, totalNum, function(nIndex, tabPart)
    shipList[nIndex] = shipList[nIndex] or cls:new()
    local item = shipList[nIndex]
    item:Init(nIndex, dataList[nIndex], tabPart, type)
  end)
end

function SettlementPage:_SetEnemyFleetItems(objSource, transRoot, dataList, childDataList, itemList, cls, type)
  local totalNum = #dataList
  for i = #itemList, totalNum, -1 do
    table.remove(itemList, i)
  end
  UIHelper.CreateSubPart(objSource, transRoot, totalNum, function(nIndex, tabPart)
    local shipItemList = {}
    local shipDataList = childDataList[nIndex].shipList
    local dictId = childDataList[nIndex].dictId
    local shipTotalNum = #shipDataList
    local fleetConfig = configManager.GetDataById("config_fleet", dictId)
    tabPart.fleet_name.text = fleetConfig.display_name
    tabPart.fleet_num.text = nIndex
    local shipObjSource = tabPart.ship_item
    local shipTransRoot = tabPart.ship_root
    UIHelper.CreateSubPart(shipObjSource, shipTransRoot, shipTotalNum, function(_index, _part)
      shipItemList[_index] = shipItemList[_index] or cls:new()
      local item = shipItemList[_index]
      item:Init(_index, shipDataList[_index], _part, type)
    end)
  end)
end

function SettlementPage:_SetPlayerFleetItems(objSource, transRoot, dataList, itemList, cls, type)
  local totalNum = #dataList
  for i = #itemList, 0, -1 do
    table.remove(itemList, i)
  end
  UIHelper.CreateSubPart(objSource, transRoot, totalNum, function(nIndex, tabPart)
    local shipItemList = {}
    local shipDataList = dataList[nIndex]
    local shipTotalNum = #shipDataList
    tabPart.fleet_name.text = self.param.myFleetName
    tabPart.fleet_num.text = nIndex
    local shipObjSource = tabPart.ship_item
    local shipTransRoot = tabPart.ship_root
    UIHelper.CreateSubPart(shipObjSource, shipTransRoot, shipTotalNum, function(_index, _part)
      shipItemList[_index] = shipItemList[_index] or cls:new()
      local item = shipItemList[_index]
      item:Init(_index, shipDataList[_index], _part, type)
    end)
  end)
end

function SettlementPage:CombinMatchPlayerFleetItems()
  local matchPlayerInfoList = {}
  local submarineTab = {}
  for _, fleetInfo in pairs(self.m_matchPlayShipList) do
    local isSubmarine = false
    for _, shipInfo in pairs(fleetInfo) do
      local shipShowConfig = Logic.shipLogic:GetShipShowByFashionId(shipInfo.fashionId)
      if shipShowConfig.ship_type == 8 then
        isSubmarine = true
        table.insert(submarineTab, shipInfo)
        break
      end
    end
    if not isSubmarine then
      table.insert(matchPlayerInfoList, fleetInfo)
    end
  end
  if next(submarineTab) ~= nil then
    table.insert(matchPlayerInfoList, submarineTab)
  end
  return matchPlayerInfoList
end

function SettlementPage:_SetMatchPlayerFleetItems(objSource, transRoot, dataList, itemList)
  local totalNum = #dataList
  for i = #itemList, 0, -1 do
    table.remove(itemList, i)
  end
  UIHelper.CreateSubPart(objSource, transRoot, totalNum, function(nIndex, tabPart)
    local shipItemList = {}
    local userDataList = dataList[nIndex]
    local shipTotalNum = #userDataList
    tabPart.fleet_name.text = Logic.settlementLogic:GetMatchPlayerUserName(userDataList[1].ownerPlayerUID)
    tabPart.fleet_num.text = nIndex
    local shipObjSource = tabPart.ship_item
    local shipTransRoot = tabPart.ship_root
    UIHelper.CreateSubPart(shipObjSource, shipTransRoot, #userDataList, function(_index, _part)
      local data = userDataList[_index]
      local widgets = _part
      local txt_lv = widgets.txt_lv
      local txt_name = widgets.txt_name
      local img_status = widgets.img_status
      local sld_hp = widgets.sld_hp
      sld_hp.value = data.hp / data.maxHp
      widgets.sld_add.value = data.hp / data.maxHp
      data.status = Logic.shipLogic:GetHeroHpStatus(data.hp, data.maxHp)
      if data.status == HeroHpState.NONE then
        img_status.gameObject:SetActive(false)
      else
        img_status.gameObject:SetActive(true)
        UIHelper.SetImage(img_status, ShipBattleHpState[data.status])
      end
      widgets.grayGroup.Gray = data.status == HeroHpState.JiChen
      local shipShowConfig = Logic.shipLogic:GetShipShowByFashionId(data.fashionId)
      txt_name.text = shipShowConfig.ship_name
      txt_lv.text = data.level
      tabPart = widgets.childpart:GetLuaTableParts()
      UIHelper.SetImage(tabPart.im_type, NewCardShipTypeImg[shipShowConfig.ship_type])
      if shipShowConfig.ship_icon7 ~= "1" and shipShowConfig.ship_icon7_po ~= "1" then
        if data.status < DamageLevel.MiddleDamage then
          UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon7))
        else
          UIHelper.SetImage(tabPart.im_girl, tostring(shipShowConfig.ship_icon7_po))
        end
      end
    end)
  end)
end

function SettlementPage:_CreateShowGirl(mvp)
  local widgets = self:GetWidgets()
  local show = Logic.shipLogic:GetShipShowByHeroId(mvp.heroId)
  local dressup = Logic.shipLogic:GetDressupId(show.model_id, mvp.hp, mvp.maxHp)
  local param = {
    showID = show.ss_id,
    dressID = dressup,
    girlType = GirlType.MVP
  }
  self.m_showGirl = UIHelper.Create3DModelNoRT(param, CamDataType.Settle, true)
  self.m_showGirl.m_camera.enabled = false
  widgets.raw_girl.gameObject:SetActive(false)
end

function SettlementPage:_HideShowGirl()
end

function SettlementPage:_DestroyShowGirl()
  if self.m_petObject then
    self.m_petObject:DestroyModel()
    self.m_petObject = nil
  end
  if self.m_showGirl then
    local widgets = self:GetWidgets()
    UIHelper.Close3DModel(self.m_showGirl)
    widgets.raw_girl.gameObject:SetActive(false)
    self.m_showGirl = nil
  end
end

function SettlementPage:_OnClickNext()
  if self.matchMode then
    self:_SetTrigger("Next2")
    self:_OpenMember_Info()
    return
  end
  self.m_next = true
  Logic.settlementLogic.m_flowCtrl(Logic.settlementLogic.Input.Next)
end

function SettlementPage:_MemberOnSkipClick()
  local widgets = self:GetWidgets()
  self.m_next = true
  widgets.obj_member_info:SetActive(false)
  Logic.settlementLogic.m_flowCtrl(Logic.settlementLogic.Input.Next)
end

function SettlementPage:_OpenMember_Info()
  local userId = Data.userData:GetUserUid()
  local widgets = self:GetWidgets()
  widgets.obj_Next:SetActive(false)
  widgets.obj_member_info:SetActive(true)
  local userServerId = self.otherUsertab[userId].ServerId
  local combinPlayerInfoList = self:CombinPlayerInfoList()
  UIHelper.CreateSubPart(widgets.obj_member, widgets.trans_member, #combinPlayerInfoList, function(index, tabPart)
    local userBattleInfo = combinPlayerInfoList[index]
    local uid = userBattleInfo.ownerPlayerUID
    local uidInfo = self.otherUsertab[uid]
    if uidInfo == nil then
      logError("uidInfo is nil")
    else
      local icon, qualityIcon = Data.userData:GetUserHeadIcon(uidInfo)
      tabPart.mvp:SetActive(userBattleInfo.mvp)
      UIHelper.SetText(tabPart.tx_rankNum, index)
      UIHelper.SetImage(tabPart.im_girl, icon)
      UIHelper.SetText(tabPart.tx_level, uidInfo.Level)
      UIHelper.SetText(tabPart.tx_name, uidInfo.Uname)
      local _, headFrameInfo = Logic.playerHeadFrameLogic:GetOtherHeadFrame(uidInfo)
      UIHelper.SetImage(tabPart.im_frame, headFrameInfo.icon)
      local frinedState = FriendState.NONE
      if userId == uid then
        frinedState = FriendState.Self
      else
        local isMyFriend = Logic.friendLogic:IsMyFriend(uid)
        if isMyFriend then
          frinedState = FriendState.Friend
        elseif uidInfo.ServerId ~= userServerId then
          frinedState = FriendState.OthenServerFriend
        else
          local checkResule = Logic.friendLogic:CheckApplyReq(uid)
          if checkResule then
            frinedState = FriendState.HadReauest
          else
            frinedState = FriendState.RequestFriend
          end
        end
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_Request, function()
        if frinedState == FriendState.RequestFriend then
          Logic.friendLogic:ClickApplyLogic(uid, self)
          frinedState = FriendState.HadReauest
          UIHelper.SetText(tabPart.tx_desc, string.format("<color=%s>%s</color>", HintText[frinedState][4], HintText[frinedState][1]))
          UIHelper.SetImage(tabPart.img_friendRequest, HintText[frinedState][2])
        elseif frinedState == FriendState.Friend then
          noticeManager:OpenTipPage(self, UIHelper.GetString(100042))
        end
      end, self)
      tabPart.sld_damage.value = userBattleInfo.userTotalDamage / userBattleInfo.teamMvpDamage
      UIHelper.SetText(tabPart.tx_desc, string.format("<color=%s>%s</color>", HintText[frinedState][4], HintText[frinedState][1]))
      UIHelper.SetImage(tabPart.img_friendRequest, HintText[frinedState][2])
    end
  end)
end

function SettlementPage:CombinPlayerInfoList()
  local userTab = {}
  for _, info in pairs(self.m_matchPlayerInfoList) do
    local uid = info.ownerPlayerUID
    if userTab[uid] then
      if info.mvp then
        userTab[uid].mvp = info.mvp
      end
      userTab[uid].userTotalDamage = userTab[uid].userTotalDamage + info.userTotalDamage
    else
      userTab[uid] = info
    end
  end
  local matchPlayerInfoList = {}
  for _, info in pairs(userTab) do
    table.insert(matchPlayerInfoList, info)
  end
  table.sort(matchPlayerInfoList, function(l, r)
    return l.userTotalDamage > r.userTotalDamage
  end)
  return matchPlayerInfoList
end

function SettlementPage:GetOtherUserInfo(uid)
  Service.userService:SendGetOtherInfo(uid)
end

function SettlementPage:_CollectAnimators(obj_root)
  local widgets = self:GetWidgets()
  local obj_root = widgets.obj_root
  local animatorArr = obj_root:GetComponentsInChildren(UnityEngine_Animator.GetClassType())
  self.m_animList = {}
  for i = 0, animatorArr.Length - 1 do
    table.insert(self.m_animList, animatorArr[i])
  end
end

function SettlementPage:_SetTrigger(trigger)
  if self.m_animList == nil then
    return
  end
  for _, animator in ipairs(self.m_animList) do
    animator:SetTrigger(trigger)
  end
end

function SettlementPage:_PlayItemExp()
  for _, item in ipairs(self.m_myItemList) do
    item:BeginExpSlider()
  end
end

function SettlementPage:_ShowAddExpTween()
  for _, item in ipairs(self.m_myItemList) do
    item:BeginExpSlider()
  end
end

function SettlementPage:_PlayItemAnimation()
  local count = 1
  return function()
    local item = self.m_myItemList[count]
    if item then
      item:AnimBegin()
      item:BeginHpSlider(3)
    end
    local item = self.m_enemyItemList[count]
    if item then
      item:AnimBegin()
      item:BeginHpSlider(3)
    end
    count = count + 1
    SoundManager.Instance:PlayAudio("UI_mianbanyidong")
  end
end

function SettlementPage:_PlayAudio(audio)
  SoundManager.Instance:PlayAudio(audio)
end

function SettlementPage:_PlayMVPAnim(girl3DObj)
  local widgets = self:GetWidgets()
  local strAnim
  local grade = self.param.grade
  if grade ~= EvaGradeType.F then
    strAnim = "mvp"
    girl3DObj:playBehaviour(strAnim, false, function()
      girl3DObj:playBehaviour("mvp_loop", true)
    end)
  else
    girl3DObj:playBehaviour("defeat", false, function()
      girl3DObj:playBehaviour("defeat_loop", true)
    end)
  end
  local actionLen = girl3DObj:getCurBehaviourLength()
  local camera = self.m_showGirl.m_camera
  camera.enabled = true
  local wu = UIManager:GetUIWidth() / 2
  local hu = UIManager:GetUIHeight() / 2
  local fromPos = wu + 2000
  local toPos = (widgets.tfLeft.localPosition.x + widgets.tfRight.localPosition.x) / 2
  local from = -camera.orthographicSize / hu * fromPos
  local to = -camera.orthographicSize / hu * toPos
  local seq = UISequence.NewSequence(girl3DObj.gameObject, false)
  seq:Join(girl3DObj.transform:TweenLocalMoveX(from, to, 1.5))
  seq:Play(true)
  self.m_heroTwn = seq
end

function SettlementPage:_PlayPercentAnim()
  local param = self.param
  local widgets = self:GetWidgets()
  local total = 2
  local myPercent = param.myFleetList[1].percent
  local enemyPercent = param.enemyShipList.percent
  if myPercent == nil then
    myPercent = 0
  end
  if enemyPercent == nil then
    myPercent = 0
  end
  if 0 < myPercent or 0 < enemyPercent then
    local seq = UISequence.NewSequence(widgets.obj_root, true)
    seq:AppendCallback(function()
      SoundManager.Instance:PlayAudio("UI_jingyanzengzhang")
    end)
    if #param.myFleetList > 1 then
      seq:Append(widgets.sld_myTopFleetBlood:TweenValue(0, myPercent, total))
    else
      seq:Append(widgets.sld_myBlood:TweenValue(0, myPercent, total))
    end
    if self.multiMode == 0 then
      seq:Join(widgets.sld_enemyBlood:TweenValue(0, enemyPercent, total))
    else
      seq:Join(widgets.sld_fleetsDamage:TweenValue(0, enemyPercent, total))
    end
    seq:AppendCallback(function()
      SoundManager.Instance:StopAudio("UI_jingyanzengzhang")
    end)
    seq:Play(true)
  end
end

function SettlementPage:RestructFleetList(myfleetList)
  local fleetList = clone(myfleetList)
  if fleetList[1].fleetId == nil or fleetList[1].fleetId == 0 then
    return fleetList
  else
    local fleetMember = {}
    for i = 1, #fleetList do
      local member = fleetMember[fleetList[i].fleetId]
      if member == nil then
        member = {}
      end
      table.insert(member, i)
    end
    local reFleetList = {}
    for _, fleetData in pairs(fleetMember) do
      if 1 < #fleetData then
        for i = 1, #fleetData do
          local isExHero = self:CheckIsExHero(fleetData[i][1].sm_id)
          if isExHero then
            if i ~= #fleetData then
              local data = fleetData[i]
              fleetData[i] = fleetData[#fleetData]
              fleetData[#fleetData] = data
            end
            break
          end
        end
        for i = 1, #fleetData do
          reFleetList[#reFleetList + 1] = fleetData[i]
        end
      else
        reFleetList[#reFleetList + 1] = fleetList[fleetData[1]]
      end
    end
    return reFleetList
  end
end

function SettlementPage:CheckIsExHero(sm_id)
  local shipType = Logic.shipLogic:GetHeroTypeBySMId(sm_id)
  if shipType == 8 then
    return true
  else
    return false
  end
end

function SettlementPage:RestructMyFleet()
  local myDataList = clone(self.m_myDataList)
  self.myDetailFleetList = {}
  local mvpIndex = 1
  for i = 1, #myDataList do
    local shipType = Logic.shipLogic:GetHeroTypeBySMId(myDataList[i].sm_id)
    if shipType == 8 then
      if self.myDetailFleetList[2] == nil then
        self.myDetailFleetList[2] = {}
      end
      table.insert(self.myDetailFleetList[2], myDataList[i])
      if myDataList[i].mvp then
        mvpIndex = 2
      end
    else
      if self.myDetailFleetList[1] == nil then
        self.myDetailFleetList[1] = {}
      end
      table.insert(self.myDetailFleetList[1], myDataList[i])
    end
  end
  self.tab_Widgets.tog_attachedfleet.gameObject:SetActive(#self.myDetailFleetList > 1)
  self.tab_Widgets.group_selectfleet:SetActiveToggleIndex(mvpIndex - 1)
end

function SettlementPage:SwitchFleetTogs(togIndex)
  local index = togIndex + 1
  self:SetMyFleetDetailInfo(index)
end

function SettlementPage:SetMyFleetDetailInfo(index)
  self:_SetItems(self.tab_Widgets.obj_myFleetDetail, self.tab_Widgets.trans_myFleetDetail, self.myDetailFleetList[index], self.m_myItemList, SettlementItem, SettlementItemType.DETIAL, true)
end

return SettlementPage
