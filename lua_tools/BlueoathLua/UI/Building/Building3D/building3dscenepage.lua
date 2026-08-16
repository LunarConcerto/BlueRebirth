local Building3DScenePage = class("UI.Building.Building3D.Building3DScenePage", LuaUIPage)

function Building3DScenePage:DoOnOpen()
  local buildingId = self:GetParam().buildingId
  self.buildingData = Data.buildingData:GetBuildingById(buildingId)
  self.buildingCfg = configManager.GetDataById("config_buildinginfo", self.buildingData.Tid)
  local name = Logic.buildingLogic:GetBuildName(self.buildingData.Tid)
  self:OpenTopPage("Building3DScenePage", 1, name, self, true)
  SoundManager.Instance:PreLoad("CV_role_sd_bank")
  self:InitUI()
  self:LoadScene()
  eventManager:SendEvent(LuaEvent.Build3DLoadOk)
end

function Building3DScenePage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_reset, self._OnResetCamera, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_detail, self._OnBtnDetail, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_hide_ui, self._OnHideUI, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_share, self._OnShare, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_info, self._OnBtnInfo, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_receive_item, self._OnBtnReceiveItem, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_receive, self._OnBtnReceive, self)
  self:RegisterEvent(LuaEvent.PlotEnd, self._OnPlotEnd, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
  self:RegisterEvent(LuaEvent.BuildingReceiveResult, self._OnReceiveResult, self)
end

function Building3DScenePage:ResetBubbleScale()
  local chatBubbleMgr = GameObject.Find("ChatBubbleManager(Clone)") or GameObject.Find("ChatBubbleManager")
  local transform = chatBubbleMgr:GetComponent(Transform.GetClassType())
  local childCount = transform.childCount
  for i = 0, childCount - 1 do
    local child = transform:GetChild(i)
    if child.name == "ChatBubble(Clone)" or child.name == "ChatBubble" then
      local transform = child:GetComponent(RectTransform.GetClassType())
      transform.localScale = Vector3.one
    end
  end
end

function Building3DScenePage:PlayVideo(applyToMaterial, key)
  local path = Logic.buildingLogic:RandomVideo(self.path, key)
  self.path = path
  if not self.videoPlayProcess then
    self.videoPlayProcess = UIHelper.InitAndPlayVideoOnMat(self.path, applyToMaterial, function()
      self:PlayVideo(applyToMaterial, key)
    end, nil, self.tab_Widgets.displayUGUI)
  else
    UIHelper.PlayNewVideo(self.videoPlayProcess, self.path)
  end
end

function Building3DScenePage:StartPlayVideo()
  local videoEffectObj = GameObject.Find("TVVideoEffect")
  local videoEffectComp = videoEffectObj:GetComponent(typeof(CS.BaseBuilding3DVedioEffect))
  videoEffectComp.enabled = false
  local key = videoEffectComp.VedioTableKey
  local renderer = videoEffectObj:GetComponent(typeof(CS.UnityEngine.MeshRenderer))
  renderer.enabled = true
  local applyToMaterial = videoEffectObj:GetComponent(typeof(CS.RenderHeads.Media.AVProVideo.ApplyToMaterial))
  self:PlayVideo(applyToMaterial, key)
end

function Building3DScenePage:StopVideo()
  if self.videoPlayProcess then
    UIHelper.DestroyVideoProcess(self.videoPlayProcess)
    self.videoPlayProcess = nil
    self.path = nil
  end
end

function Building3DScenePage:LoadScene()
  local buildingId = self.buildingData.Id
  local btype = self.buildingCfg.type
  local modelDatas = Logic.buildingLogic:GetBuildingPlots(buildingId)
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.INFRASTRUCTURE,
    {
      buildingId = buildingId,
      btype = btype,
      models = modelDatas
    }
  })
  SoundManager.Instance:PlayMusic(self.buildingCfg.building_scene_bgm)
  self:ResetBubbleScale()
  if self.buildingCfg.type == MBuildingType.DormRoom then
    self:StartPlayVideo()
  end
end

function Building3DScenePage:InitUI()
  self.showFuncBtns = true
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.txt_girl_num, string.format("%s/%s", #self.buildingData.HeroList, self.buildingCfg.heronumber))
  widgets.obj_line1.gameObject:SetActive(false)
  widgets.obj_line2.gameObject:SetActive(false)
  widgets.obj_line3.gameObject:SetActive(false)
  widgets.btn_Renovation.gameObject:SetActive(false)
  self:SetMoodState()
  self:SetDetailInfo()
  self:StartCountDownTimer()
end

function Building3DScenePage:UpdateUI()
  self.buildingData = Data.buildingData:GetBuildingById(self.buildingData.Id)
  self:SetDetailInfo()
end

function Building3DScenePage:SetMoodState()
  self.showMoodState = false
  local widgets = self:GetWidgets()
  local btype = self.buildingCfg.type
  local moodLimit = configManager.GetDataById("config_parameter", 142).arrValue
  if btype == MBuildingType.DormRoom then
    local moodFull = false
    for i, heroId in ipairs(self.buildingData.HeroList) do
      local _, curMood = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
      if curMood >= moodLimit[2] then
        moodFull = true
        break
      end
    end
    if moodFull then
      self.showMoodState = true
      widgets.obj_high:SetActive(true)
      widgets.obj_low:SetActive(false)
    end
  else
    local moodEmpty = false
    for i, heroId in ipairs(self.buildingData.HeroList) do
      local _, curMood = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Mood)
      if curMood <= 0 then
        moodEmpty = true
        break
      end
    end
    if moodEmpty then
      self.showMoodState = true
      widgets.obj_low:SetActive(true)
      widgets.obj_high:SetActive(false)
    end
  end
  widgets.obj_state:SetActive(self.showMoodState)
end

function Building3DScenePage:SetDetailInfo()
  local widgets = self:GetWidgets()
  local btype = self.buildingCfg.type
  if btype == MBuildingType.DormRoom then
    widgets.obj_dorm:SetActive(true)
    widgets.obj_produce:SetActive(false)
    widgets.obj_other:SetActive(false)
    widgets.btn_Renovation.gameObject:SetActive(true)
    self:SetDormInfo()
  elseif btype == MBuildingType.ItemFactory then
    widgets.obj_dorm:SetActive(false)
    widgets.obj_produce:SetActive(true)
    widgets.obj_other:SetActive(false)
    self:SetItemFactoryInfo()
  else
    widgets.obj_dorm:SetActive(false)
    widgets.obj_produce:SetActive(false)
    widgets.obj_other:SetActive(true)
    self:SetOtherInfo()
  end
end

function Building3DScenePage:SetDormInfo()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.txt_state, "")
  widgets.obj_dot:SetActive(false)
  local cfg = configManager.GetDataById("config_building_config", 6)
  UIHelper.SetText(widgets.txt_comfort, cfg.data)
  local _, moodRecoverStr = Logic.buildingLogic:GetMoodRecoverStr(self.buildingData)
  UIHelper.SetText(widgets.txt_mood, moodRecoverStr)
  local working = #self.buildingData.HeroList > 0
  if working then
    self:StartLineAnim(widgets.obj_line2)
  end
  self:RegisterEvent(LuaEvent.PlotEnd, self._OnPlotEnd, self)
end

function Building3DScenePage:SetItemFactoryInfo()
  local widgets = self:GetWidgets()
  local statusStr = Logic.buildingLogic:GetStatusStr(self.buildingData.Status)
  UIHelper.SetText(widgets.txt_state, statusStr)
  local hasRecipe = self.buildingData.RecipeId > 0
  widgets.txt_add_item.gameObject:SetActive(not hasRecipe)
  widgets.bg_num:SetActive(hasRecipe)
  widgets.img_icon.gameObject:SetActive(hasRecipe)
  widgets.obj_countdown:SetActive(hasRecipe)
  local _, count = Logic.buildingLogic:ProduceItem(self.buildingData)
  widgets.btn_receive_item.gameObject:SetActive(0 < count)
  self:StartDotAnim()
  if self.buildingData.Status == BuildingStatus.Working then
    self:StartLineAnim(widgets.obj_line1)
  end
  if not hasRecipe then
    UIHelper.SetText(widgets.txt_name, "")
    UIHelper.SetText(widgets.txt_count, "")
    UIHelper.SetImage(widgets.img_quality, QualityIcon[1])
  else
    local recipeCfg = configManager.GetDataById("config_recipe", self.buildingData.RecipeId)
    local tableIndex = configManager.GetDataById("config_table_index", recipeCfg.item[1])
    local produceItem = configManager.GetDataById(tableIndex.file_name, recipeCfg.item[2])
    UIHelper.SetImage(widgets.img_quality, QualityIcon[produceItem.quality])
    UIHelper.SetImage(widgets.img_icon, produceItem.icon)
    UIHelper.SetText(widgets.txt_name, produceItem.name)
    UIHelper.SetText(widgets.txt_time, "00:00:00")
    UIHelper.SetText(widgets.txt_count, string.format("%s/%s", count, self.buildingData.ItemCount))
  end
end

function Building3DScenePage:SetOtherInfo()
  local widgets = self:GetWidgets()
  local count = Logic.buildingLogic:Produce(self.buildingData)
  local resouceIcons = configManager.GetDataById("config_parameter", 216).arrValue
  local cfg = self.buildingCfg
  widgets.btn_receive.gameObject:SetActive(0 < count)
  if cfg.type == MBuildingType.OilFactory then
    UIHelper.SetImage(widgets.img_res, resouceIcons[1], true)
  elseif cfg.type == MBuildingType.ResourceFactory then
    UIHelper.SetImage(widgets.img_res, resouceIcons[2], true)
  end
  if self.buildingCfg.type ~= MBuildingType.OilFactory and self.buildingCfg.type ~= MBuildingType.ResourceFactory and self.buildingCfg.type ~= MBuildingType.ItemFactory then
    UIHelper.SetText(widgets.txt_state, "")
    widgets.obj_dot:SetActive(false)
  else
    widgets.obj_dot:SetActive(true)
    local statusStr = Logic.buildingLogic:GetStatusStr(self.buildingData.Status)
    UIHelper.SetText(widgets.txt_state, statusStr)
  end
  local working = self.buildingData.Status == BuildingStatus.Working
  if working then
    self:StartLineAnim(widgets.obj_line3)
  end
  local attrs = Logic.buildingLogic:GetBuilding3DAttrs(self.buildingCfg.type, self.buildingData)
  local bec = #attrs.BuildingEffects
  local attrCount = bec + #attrs.HeroEffects
  UIHelper.CreateSubPart(widgets.obj_property, widgets.trans_property, attrCount, function(index, tabPart)
    if index <= bec then
      local effectFunc = attrs.BuildingEffects[index]
      local key, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, self.buildingData)
      UIHelper.SetText(tabPart.txt_key, key .. "\239\188\154")
      UIHelper.SetText(tabPart.txt_value, value)
    else
      index = index - bec
      local effectFunc = attrs.HeroEffects[index]
      local key, valueStr, value = Logic.buildingLogic[effectFunc](Logic.buildingLogic, self.buildingData)
      UIHelper.SetText(tabPart.txt_key, key .. "\239\188\154")
      UIHelper.SetText(tabPart.txt_value, valueStr)
    end
  end)
end

function Building3DScenePage:StartCountDownTimer()
  self.countDownTimer = self:CreateTimer(function()
    self:DoCountDown()
  end, 1, -1, false)
  self:StartTimer(self.countDownTimer)
  self:DoCountDown()
end

function Building3DScenePage:DoCountDown()
  local buildingDatas = Data.buildingData:GetBuildingData()
  local data = self.buildingData
  local cfg = self.buildingCfg
  if data.Status == BuildingStatus.Working and cfg.type == MBuildingType.ItemFactory then
    self:ProduceItem(data)
  end
end

function Building3DScenePage:StopCountDownTimer()
  if self.countDownTimer then
    self:StopTimer(self.countDownTimer)
    self.countDownTimer = nil
  end
end

function Building3DScenePage:ProduceItem(buildingData)
  local widgets = self:GetWidgets()
  local remainTime, count = Logic.buildingLogic:ProduceItem(buildingData)
  local timeStr = time.getHoursString(remainTime)
  UIHelper.SetText(widgets.txt_time, timeStr)
  UIHelper.SetText(widgets.txt_count, string.format("%s/%s", count, buildingData.ItemCount))
  if remainTime <= 0 then
    self:StopCountDownTimer()
    self:StopLineAnim(true, widgets.obj_line2)
    local statusStr = Logic.buildingLogic:GetStatusStr(self.buildingData.Status)
    UIHelper.SetText(widgets.txt_state, statusStr)
  end
  widgets.btn_receive_item.gameObject:SetActive(0 < count)
end

function Building3DScenePage:StartLineAnim(objLine)
  if self.buildingCfg.type ~= MBuildingType.OilFactory and self.buildingCfg.type ~= MBuildingType.ResourceFactory and self.buildingCfg.type ~= MBuildingType.ItemFactory and self.buildingCfg.type ~= MBuildingType.DormRoom then
    return
  end
  objLine.gameObject:SetActive(true)
  local luapart = UIHelper.GetTabPart(objLine)
  self.lineIndex = 1
  self:StopLineAnim(false, objLine)
  self.lineAnimTimer = self:CreateTimer(function()
    self:DoLineAnim(luapart)
  end, 1, -1, false)
  self:StartTimer(self.lineAnimTimer)
  self:DoLineAnim(luapart)
end

function Building3DScenePage:DoLineAnim(luapart)
  local buildingDatas = Data.buildingData:GetBuildingData()
  for i = 1, 4 do
    luapart["line" .. i]:SetActive(i == self.lineIndex)
  end
  self.lineIndex = self.lineIndex + 1
  if self.lineIndex == 5 then
    self.lineIndex = 1
  end
end

function Building3DScenePage:StopLineAnim(hide, objLine)
  local widgets = self:GetWidgets()
  if self.lineAnimTimer then
    self:StopTimer(self.lineAnimTimer)
    self.lineAnimTimer = nil
    if hide then
      objLine.gameObject:SetActive(false)
    end
  end
end

function Building3DScenePage:StartDotAnim()
  if self.buildingCfg.type ~= MBuildingType.OilFactory and self.buildingCfg.type ~= MBuildingType.ResourceFactory and self.buildingCfg.type ~= MBuildingType.ItemFactory then
    return
  end
  self.dotIndex = 1
  self:StopDotAnim()
  self.dotAnimTimer = self:CreateTimer(function()
    self:DoDotAnim()
  end, 1, -1, false)
  self:StartTimer(self.dotAnimTimer)
  self:DoDotAnim()
end

function Building3DScenePage:DoDotAnim()
  local widgets = self:GetWidgets()
  local buildingDatas = Data.buildingData:GetBuildingData()
  for i = 1, 3 do
    widgets["dot" .. i]:SetActive(i == self.dotIndex)
  end
  self.dotIndex = self.dotIndex + 1
  if self.dotIndex == 4 then
    self.dotIndex = 1
  end
end

function Building3DScenePage:StopDotAnim()
  if self.dotAnimTimer then
    self:StopTimer(self.dotAnimTimer)
    self.dotAnimTimer = nil
  end
end

function Building3DScenePage:_OnReceiveResult(result)
  local tabReward = {}
  if result and result.ItemInfo and next(result.ItemInfo) ~= nil then
    Logic.rewardLogic:ShowCommonReward(result.ItemInfo, "Building3DScenePage")
    for k, v in pairs(result.ItemInfo) do
      table.insert(tabReward, {
        currencyId = v.ConfigId,
        Num = v.Num
      })
    end
  end
  local dotinfo = {
    info = "all_resource_get",
    item_num = tabReward
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  self:UpdateUI()
end

function Building3DScenePage:_OnBtnReceiveItem()
  Service.buildingService:ReceiveItem(self.buildingData.Id)
end

function Building3DScenePage:_OnBtnReceive()
  local checkResource, errMsg = Logic.buildingLogic:CheckReceiveResource(self.buildingData)
  if errMsg ~= nil then
    noticeManager:ShowTip(errMsg)
    return
  end
  local count = Logic.buildingLogic:Produce(self.buildingData)
  if count <= 0 then
    return
  end
  Service.buildingService:ReceiveBuilding(self.buildingData.Id)
end

function Building3DScenePage:_OnBtnInfo()
  UIHelper.OpenPage("Building2DDetailPage", {
    data = self.buildingData,
    showItem = true
  })
end

function Building3DScenePage:_OnResetCamera()
  GR.baseBuilding3DManager:ResetCamera()
end

function Building3DScenePage:_OnBtnDetail()
  UIHelper.OpenPage("Building2DDetailPage", {
    data = self.buildingData
  })
end

function Building3DScenePage:_OnHideUI()
  local widgets = self:GetWidgets()
  widgets.tween_hide:Play(self.showFuncBtns)
  widgets.btn_share.gameObject:SetActive(self.showFuncBtns)
  widgets.obj_details.gameObject:SetActive(not self.showFuncBtns)
  widgets.obj_info.gameObject:SetActive(not self.showFuncBtns)
  widgets.btn_reset.gameObject:SetActive(not self.showFuncBtns)
  if self.buildingCfg.type == MBuildingType.DormRoom then
    widgets.btn_Renovation.gameObject:SetActive(not self.showFuncBtns)
  end
  if self.showMoodState then
    widgets.obj_state.gameObject:SetActive(not self.showFuncBtns)
  end
  self.showFuncBtns = not self.showFuncBtns
end

function Building3DScenePage:_OnPlotEnd(triggerId)
  local heroAffection = Logic.buildingLogic:GetHeroAffection()
  if heroAffection then
    UIHelper.OpenPage("AffectionAddPage", heroAffection)
  else
    self:ShowNewEmoji()
  end
  self:LoadScene()
end

function Building3DScenePage:ShowNewEmoji()
  local newUnlockEmoji = Logic.chatLogic:GetNewUnlockEmoji()
  if 0 < #newUnlockEmoji then
    Logic.chatLogic:InitLockedEmoji(true)
    local rewards = {}
    for i, eid in ipairs(newUnlockEmoji) do
      local emojiCfg = configManager.GetDataById("config_emoji", eid)
      table.insert(rewards, {
        ConfigId = emojiCfg.item_id,
        Type = 1,
        Num = 1
      })
    end
    UIHelper.OpenPage("GetRewardsPage", {Rewards = rewards})
  end
end

function Building3DScenePage:_OnShare()
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName())
end

function Building3DScenePage:_ShareOver()
  if UIPageManager:IsExistPage("GetRewardsPage") then
    return
  end
  self:ShareComponentShow(true)
end

function Building3DScenePage:DoOnHide()
  self:StopVideo()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN
  })
end

function Building3DScenePage:DoOnClose()
  GR.objectPoolManager:Release()
  SoundManager.Instance:UnLoad("CV_role_sd_bank")
end

return Building3DScenePage
