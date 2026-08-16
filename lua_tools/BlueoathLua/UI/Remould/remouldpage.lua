local RemouldPage = class("UI.Remould.RemouldPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local remouldDetailPart = require("ui.page.Remould.RemouldDetailPart")
local homeRemouldState = require("Game.GameState.Home.HomeRemouldState")
local RemouldStageMax = 3

function RemouldPage:DoInit()
  self.heroId = nil
  self.shipInfoConf = nil
  self.beforeStagePart = nil
  self.beforeEffPart = nil
  self.openCollect = false
  self.remouldSerData = {}
  self.remouldUpStage = false
  self.selectStage = nil
  self.remouldedId = 0
  self.effectPart = {}
  self.lineObj = {}
  self.userId = 0
  self.timer = nil
  self.showRightEff = false
  self.showCollect = false
  self.selectEffectId = 0
  self.tab_Widgets.obj_rightEffect:SetActive(false)
  self.tab_Widgets.obj_collect:SetActive(false)
  self.timerEffect = nil
end

function RemouldPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self._ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_unselect, self._ClickUnselectEff, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_collect, self._ClickCollect, self)
  self:RegisterEvent(LuaEvent.OpenRemouldPage, self._ShowUI, self)
  self:RegisterEvent(LuaEvent.UpdateHeroRemould, self.UpdateHeroRemould, self)
end

function RemouldPage:DoOnOpen()
  self:OpenTopPage("RemouldPage", 1, UIHelper.GetString(940000001), self, true)
  local params = self:GetParam()
  self.heroId = params
  self.userId = Data.userData:GetUserUid()
  self.shipInfoConf = Logic.shipLogic:GetShipInfoByHeroId(self.heroId)
  self.remouldSerData = Logic.remouldLogic:GetHeroRemouldData(self.heroId)
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.REMOULD,
    self.remouldSerData.RemouldLV
  })
  Logic.remouldLogic:SetBeforeRemouldData(self.remouldSerData)
  Logic.remouldLogic:SetCurrStageLv(self.remouldSerData.RemouldLV)
  self:_PlayEnterSceneAnim()
  self:_ShowRemouldStage(false)
  remouldDetailPart:Init(self, self.tab_Widgets)
end

function RemouldPage:_ShowRemouldStage(isRemoulded)
  local stageTab = self.shipInfoConf.remould_template
  local selectStage = Logic.remouldLogic:GetCurrSelectStage(self.remouldSerData.RemouldLV, stageTab)
  local remouldUp = Logic.remouldLogic:CheckStageFinish(self.remouldSerData.RemouldLV)
  local currLv = self.remouldSerData.RemouldLV
  if remouldUp and self.remouldSerData.RemouldLV ~= #stageTab then
    selectStage = selectStage - 1
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_stageItem, self.tab_Widgets.trans_stage, #stageTab, function(nIndex, tabPart)
    local stageId = stageTab[nIndex]
    local stageConfig = Logic.remouldLogic:GetRemouldStageById(stageId)
    UIHelper.SetImage(tabPart.img_lock, stageConfig.lock_icon)
    UIHelper.SetImage(tabPart.im_uncomplete, stageConfig.uncomplete_icon)
    UIHelper.SetImage(tabPart.im_complete, stageConfig.complete_icon)
    UIHelper.SetImage(tabPart.im_select, stageConfig.select_icon)
    UIHelper.SetText(tabPart.tx_num, stageConfig.desc)
    tabPart.obj_line:SetActive(nIndex ~= #stageTab)
    tabPart.obj_uncomplete:SetActive(nIndex <= selectStage)
    tabPart.im_completeLine:SetActive(nIndex <= selectStage and nIndex ~= 1)
    tabPart.obj_complete:SetActive(nIndex <= currLv)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_select, self._SelectStage, self, {
      stageConfig,
      nIndex,
      isRemoulded,
      tabPart
    })
    if nIndex == selectStage then
      self:_SelectStage(nil, {
        stageConfig,
        nIndex,
        isRemoulded,
        tabPart
      })
    end
    local nextStage = selectStage + 1
    if remouldUp and nIndex == nextStage and #stageConfig.remould_item_group > 0 then
      tabPart["eff_stage" .. nextStage]:SetActive(true)
      local timer = self:CreateTimer(function()
        tabPart.obj_uncomplete:SetActive(nIndex == nextStage)
        tabPart.im_completeLine:SetActive(nIndex == nextStage)
      end, 1.22, 1, false)
      self:StartTimer(timer)
    end
  end)
end

function RemouldPage:_SelectStage(go, params)
  self:_ClickUnselectEff()
  local stageConfig = params[1]
  local index = params[2]
  local isRemoulded = params[3]
  local tabPart = params[4]
  local isOpen = #stageConfig.remould_item_group > 0
  local stageLock = true
  if self.remouldSerData.RemouldLV ~= 0 and index <= self.remouldSerData.RemouldLV + 1 or self.remouldSerData.RemouldLV == 0 and index == 1 then
    stageLock = false
  end
  if isOpen and not stageLock then
    self:_CreateStageFormation(stageConfig, isRemoulded)
  elseif isOpen and stageLock then
    noticeManager:OpenTipPage(self, UIHelper.GetString(940000004))
    return
  elseif not isOpen then
    noticeManager:OpenTipPage(self, UIHelper.GetString(940000005))
    return
  end
  self:StopShowTimer()
  if self.openCollect then
    self:PlayCollectCloseTween()
  else
    self.tab_Widgets.obj_collect:SetActive(false)
  end
  if self.beforeStagePart ~= nil then
    self.beforeStagePart.obj_select:SetActive(false)
  end
  tabPart.obj_select:SetActive(true)
  self.beforeStagePart = tabPart
  self.selectStage = stageConfig
end

function RemouldPage:_CreateStageFormation(stageConfig, isRemoulded)
  self.effectPart = {}
  self:_DestroyLineObj()
  local LineObjTab = {
    {
      self.tab_Widgets.obj_line1,
      self.tab_Widgets.obj_lineComplete1
    },
    {
      self.tab_Widgets.obj_line2,
      self.tab_Widgets.obj_lineComplete2
    }
  }
  local LineEffObjTab = {
    self.tab_Widgets.obj_eff_line,
    self.tab_Widgets.obj_eff_line2
  }
  local remouldEffectGroup = stageConfig.remould_item_group
  local oldRemouldInfo = Logic.remouldLogic:GetBeforeRemouldData()
  UIHelper.CreateSubPart(self.tab_Widgets.obj_effect, self.tab_Widgets.trans_effect, #remouldEffectGroup, function(nIndex, tabPart)
    local effectId = remouldEffectGroup[nIndex]
    local effectData = Logic.remouldLogic:GetRemouldEffectData(effectId, self.remouldSerData.ArrRemouldEffect)
    local effectInfo = effectData.config
    tabPart.obj_self.transform.localPosition = Vector3.NewFromTab(effectInfo.position)
    local icon = effectData.isCompleted and effectInfo.icon or effectInfo.lock_icon
    UIHelper.SetImage(tabPart.im_icon, icon)
    tabPart.obj_complete:SetActive(effectData.isCompleted)
    tabPart.obj_lock:SetActive(effectData.isLock)
    tabPart.obj_eff_complete:SetActive(effectData.isCompleted and self.remouldedId == effectId)
    local showEffEnable = true
    for i, endEffId in ipairs(effectInfo.remould_prev) do
      local soucePos = effectInfo.position
      local endEffPos = Logic.remouldLogic:GetRemouldEffectById(endEffId).position
      local roation = effectInfo.connect_rotation
      local lineType = LineObjTab[effectInfo.connect_type[i]][1]
      local obj_line = UIHelper.CreateGameObject(lineType, self.tab_Widgets.trans_line)
      local rectTrans = obj_line:GetComponent(RectTransform.GetClassType())
      obj_line.transform.localPosition = Vector3.NewFromTab(endEffPos)
      obj_line:SetActive(true)
      local length = rectTrans.sizeDelta.x
      local height = rectTrans.sizeDelta.y
      if effectInfo.connect_type[i] == 1 then
        length = math.sqrt((soucePos[1] - endEffPos[1]) ^ 2 + (soucePos[2] - endEffPos[2]) ^ 2)
      end
      rectTrans.sizeDelta = Vector2.New(length, height)
      if #roation ~= 0 then
        rectTrans.eulerAngles = Vector3.NewFromTab(roation[i])
      end
      local obj_line2
      local oldEffectData = Logic.remouldLogic:GetRemouldEffectData(effectId, oldRemouldInfo.ArrRemouldEffect)
      if self.remouldSerData.ArrRemouldEffect[endEffId] ~= nil then
        local lineType2 = LineObjTab[effectInfo.connect_type[i]][2]
        obj_line2 = UIHelper.CreateGameObject(lineType2, self.tab_Widgets.trans_line)
        local rectTrans2 = obj_line2:GetComponent(RectTransform.GetClassType())
        obj_line2.transform.localPosition = Vector3.NewFromTab(endEffPos)
        obj_line2:SetActive(true)
        rectTrans2.sizeDelta = Vector2.New(length, rectTrans2.sizeDelta.y)
        if #roation ~= 0 then
          rectTrans2.eulerAngles = Vector3.NewFromTab(roation[i])
        end
      end
      if isRemoulded and self.remouldSerData.ArrRemouldEffect[endEffId] ~= nil and self.remouldedId == endEffId then
        if obj_line2 ~= nil then
          obj_line2:SetActive(false)
          table.insert(self.lineObj, obj_line2)
        end
        if oldEffectData.isLock then
          table.insert(self.effectPart, tabPart)
        end
        local effType = LineEffObjTab[effectInfo.connect_type[i]]
        local obj_eff = UIHelper.CreateGameObject(effType, self.tab_Widgets.trans_lineEff)
        local effRect = obj_eff:GetComponent(RectTransform.GetClassType())
        obj_eff.transform.localPosition = Vector3.NewFromTab(endEffPos)
        obj_eff:SetActive(true)
        if effectInfo.connect_type[i] == 1 then
          local line1 = UIHelper.TryFindChildTransform(obj_eff.transform, "line")
          line1.sizeDelta = Vector2.New(length, line1.sizeDelta.y)
          local line2 = UIHelper.TryFindChildTransform(obj_eff.transform, "line01")
          line2.sizeDelta = Vector2.New(length, line2.sizeDelta.y)
        end
        if #roation ~= 0 then
          effRect.eulerAngles = Vector3.NewFromTab(roation[i])
        end
      end
      if self.remouldedId == endEffId and oldEffectData.isLock then
        showEffEnable = false
      end
    end
    if not effectData.isLock then
      tabPart.obj_lock:SetActive(not effectData.isLock and not showEffEnable and self.remouldedId ~= 0)
    end
    tabPart.obj_eff_enable:SetActive(not effectData.isCompleted and not effectData.isLock and showEffEnable)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_remouldItem, self._SelectEffect, self, {
      effectData,
      nIndex,
      tabPart
    })
    if self.remouldedId ~= 0 and self.remouldedId == effectId then
      self:_SelectEffect(nil, {
        effectData,
        nIndex,
        tabPart
      })
    end
  end)
  if self.remouldedId ~= 0 then
    UIHelper.SetUILock(true)
    local timer = self:CreateTimer(function()
      self:_LineEffectCall(self.remouldedId)
    end, 1, 1, false)
    self:StartTimer(timer)
  end
  self.remouldedId = 0
end

function RemouldPage:_LineEffectCall(remouldedId)
  for _, tabpart in pairs(self.effectPart) do
    if tabpart ~= nil then
      tabpart.obj_eff_unlock:SetActive(true)
      tabpart.obj_eff_enable:SetActive(true)
      tabpart.obj_lock:SetActive(false)
    end
  end
  for i = 0, self.tab_Widgets.trans_lineEff.childCount - 1 do
    local child = self.tab_Widgets.trans_lineEff:GetChild(i).gameObject
    GameObject.Destroy(child)
  end
  for _, lineObj in ipairs(self.lineObj) do
    lineObj:SetActive(true)
  end
  self.lineObj = {}
  UIHelper.SetUILock(false)
  self.remouldUpStage = Logic.remouldLogic:CheckStageFinish(self.remouldSerData.RemouldLV)
  if self.remouldUpStage then
    self.tab_Widgets.effect_stage:SetActive(true)
    local timer = self:CreateTimer(function()
      self.tab_Widgets.effect_stage:SetActive(false)
      self:_PlaySceneAnim(self.remouldSerData.RemouldLV)
    end, 1, 1, false)
    self:StartTimer(timer)
    homeRemouldState:CreateCoreModel(self.remouldSerData.RemouldLV)
    Logic.remouldLogic:SetCurrStageLv(self.remouldSerData.RemouldLV)
  end
end

function RemouldPage:_DestroyLineObj()
  for i = 0, self.tab_Widgets.trans_line.childCount - 1 do
    local child = self.tab_Widgets.trans_line:GetChild(i).gameObject
    GameObject.Destroy(child)
  end
end

function RemouldPage:_SelectEffect(go, params)
  self.tab_Widgets.sv_effectAttr.verticalNormalizedPosition = 1
  local effectData = params[1]
  local index = params[2]
  local tabPart = params[3]
  if self.selectEffectId ~= 0 and self.selectEffectId == effectData.config.id then
    return
  end
  if self.beforeEffPart ~= nil then
    self.beforeEffPart.obj_select:SetActive(false)
  end
  tabPart.obj_select:SetActive(true)
  self.beforeEffPart = tabPart
  self.openCollect = false
  if self.showRightEff == true and self.remouldedId == 0 and self.selectEffectId == 0 then
    self.tab_Widgets.tween_effectAlpha:Stop()
    self.tab_Widgets.tween_effectScale:Stop()
    self.tab_Widgets.tween_effectAlpha:ResetToBeginning()
    self.tab_Widgets.tween_effectScale:ResetToBeginning()
    self.tab_Widgets.tween_effectPos:ResetToBeginning()
  end
  self:StopShowTimer()
  self:PlayCollectCloseTween()
  self:_ShowEffectDetails(effectData)
end

function RemouldPage:_ShowEffectDetails(effectData)
  local effInfo = effectData.config
  self.tab_Widgets.obj_rightEffect:SetActive(true)
  self.tab_Widgets.tween_effectPos:Play(true)
  self.showRightEff = true
  self.tab_Widgets.obj_rComplete:SetActive(false)
  local icon = effectData.isCompleted and effInfo.icon or effInfo.lock_icon
  if self.remouldedId == effInfo.id then
    UIHelper.SetUILock(true)
    self.tab_Widgets.obj_effectBg:SetActive(effectData.isCompleted)
    self.tab_Widgets.obj_effectIcon:SetActive(effectData.isCompleted)
    icon = effInfo.lock_icon
    local timer = self:CreateTimer(function()
      UIHelper.SetUILock(false)
      UIHelper.SetImage(self.tab_Widgets.im_effIcon, effInfo.icon)
      self.tab_Widgets.obj_effectBg:SetActive(false)
      self.tab_Widgets.obj_effectIcon:SetActive(false)
    end, 1.33, 1, false)
    self:StartTimer(timer)
  end
  UIHelper.SetImage(self.tab_Widgets.im_effIcon, icon)
  UIHelper.SetText(self.tab_Widgets.tx_effName, effInfo.name)
  local remouldEffTab = Logic.remouldLogic:DisposeAttrEff(effInfo.remould_effect_type)
  self.tab_Widgets.obj_rare:SetActive(false)
  self.tab_Widgets.obj_attrs:SetActive(false)
  self.tab_Widgets.obj_fashion:SetActive(false)
  self.tab_Widgets.obj_newSkill:SetActive(false)
  self.tab_Widgets.obj_skillUp:SetActive(false)
  for effType, v in pairs(remouldEffTab) do
    self.tab_Widgets.obj_newSkill:SetActive(effType == RemouldEffectType.Skill)
    self.tab_Widgets.obj_skillUp:SetActive(effType == RemouldEffectType.SkillUpgrade)
    if effType == RemouldEffectType.Rare then
      self.tab_Widgets.obj_rare:SetActive(true)
      local oldSIId, newSIId = v[2], v[3]
      remouldDetailPart:SetRemouldRare(oldSIId, newSIId, self.tab_Widgets.tx_rare, self.tab_Widgets.tx_rareup)
    elseif effType == RemouldEffectType.Attr then
      local showAttrTab = {}
      for _, attrTab in ipairs(v) do
        local attrId = attrTab[2]
        local attributeInfo = configManager.GetDataById("config_attribute", attrId)
        if attributeInfo.remould_if_show == 1 then
          table.insert(showAttrTab, attrTab)
        end
      end
      if #showAttrTab ~= 0 then
        remouldDetailPart:SetRemouldAttr(self.tab_Widgets.obj_attrItem, self.tab_Widgets.trans_attr, showAttrTab)
        self.tab_Widgets.obj_attrs:SetActive(true)
      end
    elseif effType == RemouldEffectType.Fashion then
      self.tab_Widgets.obj_fashion:SetActive(true)
      local fashionId = v[2]
      self.fashionId = fashionId
      remouldDetailPart:SetRemouldFashion(fashionId, self.tab_Widgets.tx_fashionName, self.tab_Widgets.btn_fashion)
    elseif effType == RemouldEffectType.Skill then
      self.tab_Widgets.obj_newSkill:SetActive(true)
      local skillId = v[2]
      remouldDetailPart:SetRemouldSkill(skillId, self.tab_Widgets.im_skillIcon, self.tab_Widgets.tx_skillName, self.tab_Widgets.tx_skillContent)
    elseif effType == RemouldEffectType.SkillUpgrade then
      self.tab_Widgets.obj_skillUp:SetActive(true)
      local oldSkillId, newSkillId = v[2], v[3]
      remouldDetailPart:SetRemouldSkillUpgrade(oldSkillId, newSkillId, self.tab_Widgets.im_oldSkillIcon, self.tab_Widgets.tx_oldSkillName, self.tab_Widgets.im_newSkillIcon, self.tab_Widgets.tx_newSkillName, self.tab_Widgets.btn_oldSkillIcon, self.tab_Widgets.btn_newSkillIcon)
    end
  end
  self.tab_Widgets.obj_levelItem:SetActive(effInfo.limit_level ~= 0)
  local level = Data.heroData:GetHeroById(self.heroId).Lvl
  local levelLimit = level >= effInfo.limit_level and level .. "/" .. effInfo.limit_level or "<color=#FF1E1E>" .. level .. "</color>/" .. effInfo.limit_level
  UIHelper.SetText(self.tab_Widgets.tx_levelValue, levelLimit)
  self.tab_Widgets.obj_starItem:SetActive(effInfo.limit_star ~= 0)
  local star = Data.heroData:GetHeroById(self.heroId).Advance
  local starNum = effInfo.limit_star
  UIHelper.CreateSubPart(self.tab_Widgets.obj_star, self.tab_Widgets.trans_star, starNum, function(nIndex, tabPart)
    tabPart.img_star.color = Color.New(1.0, 1.0, 1.0, 1.0)
    tabPart.im_full:SetActive(nIndex <= star)
  end)
  local costTab = effInfo.cost
  self.tab_Widgets.obj_consume:SetActive(#costTab ~= 0)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_costItem, self.tab_Widgets.rect_consume, #costTab, function(nIndex, tabPart)
    local cost = costTab[nIndex]
    local costInfo = Logic.activityLogic:GetRewardInfo(cost[1], cost[2])
    UIHelper.SetImage(tabPart.img_quality, QualityIcon[costInfo.quality])
    UIHelper.SetImage(tabPart.img_icon, costInfo.icon)
    if self.remouldedId == effInfo.id then
      tabPart.obj_effectItemConsume:SetActive(true)
    else
      tabPart.obj_effectItemConsume:SetActive(false)
    end
    local ownNum = Logic.rewardLogic:GetPossessNum(cost[1], cost[2])
    local limitNum = ""
    if effectData.isCompleted then
      limitNum = cost[3]
    elseif cost[1] == GoodsType.CURRENCY then
      limitNum = ownNum >= cost[3] and cost[3] or "<color=#FF1E1E>" .. cost[3] .. "</color>"
    else
      limitNum = ownNum >= cost[3] and ownNum .. "/" .. cost[3] or "<color=#FF1E1E>" .. ownNum .. "</color>/" .. cost[3]
    end
    UIHelper.SetText(tabPart.tx_num, limitNum)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_reward, self._ClickItem, self, cost)
  end)
  self.tab_Widgets.txt_remouldTips.gameObject:SetActive(effectData.isCompleted)
  self.tab_Widgets.txt_remouldTips.text = UIHelper.GetString(940000006)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_remould, self._ClickRemould, self, effectData)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_lock, self._ClickLock, self)
  self.tab_Widgets.btn_remould.gameObject:SetActive(not effectData.isLock and not effectData.isCompleted)
  self.tab_Widgets.btn_lock.gameObject:SetActive(effectData.isLock)
  if self.selectEffectId ~= 0 then
    self.timerEffect = self:CreateTimer(function()
      self.tab_Widgets.obj_rightEffect:SetActive(false)
      self.tab_Widgets.obj_rightEffect:SetActive(true)
      self.tab_Widgets.tween_effectPos:Play(true)
    end, 0, 3)
    self:StartTimer(self.timerEffect)
  end
  self:_SetGameObjectAlpha(self.tab_Widgets.rect_consume.gameObject.transform)
  self:_SetGameObjectAlpha(self.tab_Widgets.obj_stars.transform)
  self.selectEffectId = effectData.config.id
end

function RemouldPage:_ClickLock(go)
  noticeManager:OpenTipPage(self, UIHelper.GetString(940000007))
end

function RemouldPage:_ClickRemould(go, effectData)
  local effInfo = effectData.config
  local isNeedCost = true
  for k, v in pairs(effInfo.cost) do
    local ownNum = Logic.rewardLogic:GetPossessNum(v[1], v[2])
    if ownNum < v[3] then
      isNeedCost = false
      break
    end
  end
  local str
  local heroData = Data.heroData:GetHeroById(self.heroId)
  local name = Logic.shipLogic:GetRealName(self.heroId)
  if heroData.Lvl < effInfo.limit_level then
    str = string.format(UIHelper.GetString(940000008), name, effInfo.limit_level)
    noticeManager:OpenTipPage(self, str)
  elseif heroData.Advance < effInfo.limit_star then
    str = string.format(UIHelper.GetString(940000009), name, effInfo.limit_star)
    noticeManager:OpenTipPage(self, str)
  elseif not isNeedCost then
    noticeManager:OpenTipPage(self, UIHelper.GetString(940000010))
  else
    self.remouldedId = effInfo.id
    local args = {
      HeroId = self.heroId,
      EffectId = effInfo.id
    }
    Service.heroService:_SendHeroRemould(args)
  end
end

function RemouldPage:_ClickItem(go, item)
  local typ = item[1]
  local id = item[2]
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(typ, id, true))
end

function RemouldPage:_ClickUnselectEff()
  self.selectEffectId = 0
  if self.beforeEffPart ~= nil then
    self.beforeEffPart.obj_select:SetActive(false)
  end
  if self.showRightEff and self.remouldedId == 0 then
    self:PlayEffectCloseTween()
  end
  if self.openCollect then
    self.openCollect = not self.openCollect
    self:StopShowTimer()
    self:PlayCollectCloseTween()
  end
  self.beforeEffPart = nil
end

function RemouldPage:_OpenFasion()
  moduleManager:JumpToFunc(FunctionID.Fashion, {
    heroId = self.heroId,
    fashionId = self.fashionId,
    isPreview = true
  })
end

function RemouldPage:_ClickCollect()
  self.openCollect = not self.openCollect
  self.selectEffectId = 0
  self:PlayEffectCloseTween()
  self:StopShowTimer()
  if self.openCollect then
    self:_ShowCollectDetails()
  else
    self:PlayCollectCloseTween()
  end
end

function RemouldPage:_ShowCollectDetails()
  local stageDetailsInfo = Logic.remouldLogic:GetStageAllInfo(self.heroId)
  self.tab_Widgets.obj_cRare:SetActive(false)
  self.tab_Widgets.obj_cAttrs:SetActive(false)
  self.tab_Widgets.obj_cFashion:SetActive(false)
  self.tab_Widgets.obj_cNewSkill:SetActive(false)
  self.tab_Widgets.obj_cSkillUp:SetActive(false)
  self.tab_Widgets.sub_effect:SetActive(next(stageDetailsInfo) ~= nil)
  self.tab_Widgets.tx_noEff.gameObject:SetActive(next(stageDetailsInfo) == nil)
  for effType, v in pairs(stageDetailsInfo) do
    if effType == RemouldEffectType.Rare then
      self.tab_Widgets.obj_cRare:SetActive(true)
      local oldSIId, newSIId = v[2], v[3]
      remouldDetailPart:SetRemouldRare(oldSIId, newSIId, self.tab_Widgets.tx_cRare, self.tab_Widgets.tx_cRareup)
    elseif effType == RemouldEffectType.Attr then
      local showAttrTab = {}
      for _, attrTab in ipairs(v) do
        local attrId = attrTab[2]
        local attributeInfo = configManager.GetDataById("config_attribute", attrId)
        if attributeInfo.remould_if_show == 1 then
          table.insert(showAttrTab, attrTab)
        end
      end
      if #showAttrTab ~= 0 then
        local displayAttr = Logic.remouldLogic:GetDisplayAttr(showAttrTab)
        remouldDetailPart:SetRemouldAttr(self.tab_Widgets.obj_cAttrItem, self.tab_Widgets.trans_cAttr, displayAttr)
        self.tab_Widgets.obj_cAttrs:SetActive(true)
      end
    elseif effType == RemouldEffectType.Fashion then
      self.tab_Widgets.obj_cFashion:SetActive(true)
      local fashionId = v[2]
      self.fashionId = fashionId
      remouldDetailPart:SetRemouldFashion(fashionId, self.tab_Widgets.tx_cFashionName, self.tab_Widgets.btn_cFashion)
    elseif effType == RemouldEffectType.Skill then
      self.tab_Widgets.obj_cNewSkill:SetActive(true)
      local skillId = v[2]
      remouldDetailPart:SetRemouldSkill(skillId, self.tab_Widgets.im_cIcon, self.tab_Widgets.tx_cSkillName, self.tab_Widgets.tx_cContent)
    elseif effType == RemouldEffectType.SkillUpgrade then
      self.tab_Widgets.obj_cSkillUp:SetActive(true)
      local oldSkillId, newSkillId = v[2], v[3]
      remouldDetailPart:SetRemouldSkillUpgrade(oldSkillId, newSkillId, self.tab_Widgets.im_cOSkillIcon, self.tab_Widgets.tx_cOSkillName, self.tab_Widgets.im_cNSkillIcon, self.tab_Widgets.tx_cNSkillName, self.tab_Widgets.btn_cOSkillIcon, self.tab_Widgets.btn_cNSkillIcon)
    end
  end
  self.timer = self:CreateTimer(function()
    if self.showCollect == true then
      self.tab_Widgets.tween_collectAlpha:Stop()
      self.tab_Widgets.tween_collectScale:Stop()
      self.tab_Widgets.tween_collectAlpha:ResetToBeginning()
      self.tab_Widgets.tween_collectScale:ResetToBeginning()
      self.tab_Widgets.tween_collectPos:ResetToBeginning()
    end
    self.tab_Widgets.obj_collect:SetActive(false)
    self.tab_Widgets.obj_collect:SetActive(true)
    self.showCollect = true
    self.tab_Widgets.tween_collectPos:Play(true)
    self:_SetGameObjectAlpha(self.tab_Widgets.trans_cAttr.gameObject.transform)
  end, 0, 3)
  self:StartTimer(self.timer)
end

function RemouldPage:_ClickHelp()
  UIHelper.OpenPage("HelpPage", {content = 940000012})
end

function RemouldPage:_ShowUI()
  self.tab_Widgets.obj_root:SetActive(true)
  self:_ShowRemouldStage(true)
end

function RemouldPage:UpdateHeroRemould(ret)
  self.remouldSerData = Logic.remouldLogic:GetHeroRemouldData(self.heroId)
  self:_ShowRemouldStage(true)
  self:_ShowNewFashion(ret)
  Logic.remouldLogic:SetBeforeRemouldData(self.remouldSerData)
end

function RemouldPage:_ClickSkill(go, params)
  local oldSkillId = params[1]
  local showSkillId = params[2]
  local heroData = Data.heroData:GetHeroById(self.heroId)
  local level = Logic.shipLogic:GetHeroPSkillLv(self.heroId, oldSkillId)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenMaxPSkillData(showSkillId, heroData.TemplateId, level))
end

function RemouldPage:_PlaySceneAnim(remouldLV)
  local scenePath = Logic.remouldLogic:GetRemouldModelById(tostring(remouldLV)).animation
  if scenePath == "" then
    return
  end
  self.tab_Widgets.obj_root:SetActive(fasle)
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.REMOULD,
    remouldLV
  })
  Logic.remouldLogic:RecordSceneAnim(self.userId, remouldLV)
end

function RemouldPage:_PlayEnterSceneAnim()
  local scenePath = Logic.remouldLogic:GetRemouldModelById(tostring(0)).animation
  if scenePath == "" then
    return
  end
  local recorded = Logic.remouldLogic:CheckFirstEnterRecord(self.heroId, self.userId)
  if not recorded then
    self:_PlaySceneAnim(0)
    PlayerPrefs.SetBool("RemouldFirstSceneAnim" .. self.userId .. self.heroId, true)
  end
end

function RemouldPage:DoOnClose()
  self:StopShowTimer()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN,
    HomeStateID.REMOULD
  })
end

function RemouldPage:DoOnHide()
  self:StopShowTimer()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN,
    HomeStateID.REMOULD
  })
end

function RemouldPage:StopShowTimer()
  if self.timer ~= nil then
    self:StopTimer(self.timer)
    self.timer = nil
  end
end

function RemouldPage:PlayCollectCloseTween()
  if not self.showCollect then
    return
  end
  self.tab_Widgets.tween_collectAlpha:Play(true)
  self.tab_Widgets.tween_collectScale:Play(true)
  self.tab_Widgets.tween_collectScale:SetOnFinished(function()
    self.showCollect = false
    self.tab_Widgets.obj_collect:SetActive(false)
    self.tab_Widgets.tween_collectAlpha:ResetToBeginning()
    self.tab_Widgets.tween_collectScale:ResetToBeginning()
    self.tab_Widgets.tween_collectPos:ResetToBeginning()
  end)
end

function RemouldPage:PlayEffectCloseTween(remouldedId)
  if not self.showRightEff or self.remouldedId ~= 0 then
    return
  end
  self.tab_Widgets.tween_effectAlpha:Play(true)
  self.tab_Widgets.tween_effectScale:Play(true)
  self.tab_Widgets.tween_effectScale:SetOnFinished(function()
    self.showRightEff = false
    self.tab_Widgets.obj_rightEffect:SetActive(false)
    self.tab_Widgets.tween_effectAlpha:ResetToBeginning()
    self.tab_Widgets.tween_effectScale:ResetToBeginning()
    self.tab_Widgets.tween_effectPos:ResetToBeginning()
  end)
end

function RemouldPage:_ShowNewFashion(effectId)
  local heroData = Data.heroData:GetHeroById(self.heroId)
  local effInfoTab = Logic.remouldLogic:GetRemouldEffectById(effectId).remould_effect_type
  for _, effInfo in ipairs(effInfoTab) do
    if effInfo[1] == RemouldEffectType.Fashion then
      Service.fashionService:EquipFashion(effInfo[2], 1, self.heroId)
      local timer = self:CreateTimer(function()
        local ss_id = configManager.GetDataById("config_fashion", effInfo[2]).ship_show_id
        local param = {
          girlId = {ss_id},
          showType = ShowGirlType.Fashion,
          fashionTab = {
            effInfo[2]
          }
        }
        UIHelper.OpenPage("ShowGirlPage", param)
      end, 1.33, 1, false)
      self:StartTimer(timer)
      return
    end
  end
end

function RemouldPage:_SetGameObjectAlpha(objTrans)
  for i = 0, objTrans.childCount - 1 do
    local child = objTrans:GetChild(i).gameObject
    local graph = child:GetComponent(typeof(CS.UnityEngine.UI.Graphic))
    if graph ~= nil and graph.color.a ~= 1 then
      graph.color = Color.New(graph.color.r, graph.color.g, graph.color.b, 1)
    end
    if objTrans:GetChild(i).childCount ~= 0 then
      self:_SetGameObjectAlpha(objTrans:GetChild(i))
    end
  end
end

return RemouldPage
