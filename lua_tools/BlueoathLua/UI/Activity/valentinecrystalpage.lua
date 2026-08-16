local ValentineCrystalPage = class("UI.Activity.ValentineCrystalPage", LuaUIPage)
local BallId = ActivityInteractionItemId.ValentineCrystalBallId
local UICrystalModelPathOri = "commonmodels/interactionitem/interactionitem_blind_box_christmas_show_001"

function ValentineCrystalPage:DoInit()
  self.m_sprayObj = nil
  self.m_crystalBall = nil
  self.m_ObjinUI = nil
  self.m_allHeroList = {}
  self.m_ownedHeroList = {}
  self.m_curshipGril = nil
  self.m_isShowList = false
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
end

function ValentineCrystalPage:RegisterAllEvent()
  UGUIEventListener.AddOnDrag(self.tab_Widgets.im_mask, self._OnDrag, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_help, self._ShowHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.mask_list, self._CloseHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_left, self._ChangePre, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.im_right, self._ChangeNext, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_shop, self._ClickBlindBoxShop, self)
  self:RegisterEvent(LuaEvent.ACShop_GetToy, self.DoOnOpen, self)
end

function ValentineCrystalPage:DoOnOpen()
  self.param = self:GetParam()
  self.ballId = self.param.BallId
  self.UICrystalModelPath = self:__GetPath()
  self.m_allHeroList = Data.activitychristmasshopData:GetCanGetToyList()
  table.sort(self.m_allHeroList, function(a, b)
    local shipInfoA = configManager.GetDataById("config_interaction_figurte", a).figure_order
    local shipInfoB = configManager.GetDataById("config_interaction_figurte", b).figure_order
    return shipInfoA < shipInfoB
  end)
  self.m_ownedHeroList = Data.activitychristmasshopData:GetToyList()
  self.m_curshipGril = Logic.interactionItemLogic:GetShowToyIdByBallId(self.ballId)
  local tmp = {}
  for _, v in pairs(self.m_allHeroList) do
    for _, u in pairs(self.m_ownedHeroList) do
      if v == u then
        table.insert(tmp, u)
      end
    end
  end
  self.m_ownedHeroList = tmp
  self.m_curIndex = self:__GetGirlIndex()
  self.m_isShowList = false
  self:OpenTopPage("ValentineCrystalPage", 1, "\231\155\178\231\155\146\229\133\172\228\187\148", self, true)
  self:ShowPage()
end

function ValentineCrystalPage:__GetPath()
  local UICrystalModelPath = configManager.GetDataById("config_interaction_item", self.ballId).interaction_item_detail
  if UICrystalModelPath == "" or UICrystalModelPath == nil then
    return UICrystalModelPathOri
  end
  return UICrystalModelPath
end

function ValentineCrystalPage:__GetGirlIndex()
  for i, v in pairs(self.m_ownedHeroList) do
    if v == self.m_curshipGril then
      return i
    end
  end
  return 0
end

function ValentineCrystalPage:ShowPage()
  local widgets = self.tab_Widgets
  local ownNum = #self.m_ownedHeroList
  local totalNum = #self.m_allHeroList
  local numText = string.format(configManager.GetDataById("config_language", 1300044).content, ownNum, totalNum)
  UIHelper.SetText(widgets.txt_num, numText)
  self.tab_Widgets.obj_list:SetActive(self.m_isShowList)
  self.tab_Widgets.mask_list.gameObject:SetActive(self.m_isShowList)
  self:_Destory3DObj()
  if self.m_curshipGril > 0 then
    widgets.obj_nameboard:SetActive(true)
    self:__CreateSnowBabyModel()
  else
    widgets.obj_nameboard:SetActive(false)
    self:__CreateCrystalModel()
  end
  self:_ShowCrystalBallInUI()
end

function ValentineCrystalPage:__CreateCrystalModel()
  self:_Destory3DObj()
  self.m_crystalBall = GR.objectPoolManager:LuaGetGameObject(self.UICrystalModelPath)
  local itemPosition = configManager.GetDataById("config_parameter", 326).arrValue
  self.m_crystalBall.transform.localPosition = Vector3.New(itemPosition[1][1], itemPosition[1][2], itemPosition[1][3])
  self.m_crystalBall.transform.localEulerAngles = Vector3.New(itemPosition[2][1], itemPosition[2][2], itemPosition[2][3])
  self.m_crystalBall.transform.localScale = Vector3.New(itemPosition[3][1], itemPosition[3][2], itemPosition[3][3])
  self.objRotation = self.m_crystalBall.transform:Find("rotation")
end

function ValentineCrystalPage:__CreateSnowBabyModel()
  local widgets = self.tab_Widgets
  if not self.m_crystalBall then
    self:__CreateCrystalModel()
  end
  local shipGirlConfig = configManager.GetDataById("config_interaction_figurte", self.m_curshipGril)
  local shipGrilName = shipGirlConfig.ship_name
  UIHelper.SetText(widgets.txt_name, shipGrilName)
  local shipGrilModelPath = shipGirlConfig.figure_name
  local ModelPathELISA = "modelsq/" .. shipGrilModelPath .. "/" .. shipGrilModelPath
  self.objRotation = self.m_crystalBall.transform:Find("rotation")
  self.m_sprayObj = GR.objectPoolManager:LuaGetGameObject(ModelPathELISA, self.objRotation)
  local itemPosition = configManager.GetDataById("config_parameter", 328).arrValue
  self.m_sprayObj.transform.localPosition = Vector3.New(itemPosition[1][1], itemPosition[1][2], itemPosition[1][3])
  self.m_sprayObj.transform.localEulerAngles = Vector3.New(itemPosition[2][1], itemPosition[2][2], itemPosition[2][3])
  local itemFigure = shipGirlConfig.figure_scale
  self.m_sprayObj.transform.localScale = Vector3.New(itemFigure[1], itemFigure[2], itemFigure[3])
end

function ValentineCrystalPage:_ShowCrystalBallInUI()
  local createParam = {
    targetObject = self.m_crystalBall
  }
  local cameraParam = self:_GetCrystalCameraParam()
  local commonCamParam = {depth = 1.5, clearFlags = 3}
  self.m_ObjinUI = UIHelper.CreateOther3DModelNoRT(createParam, cameraParam, false, nil, nil, nil, commonCamParam)
end

function ValentineCrystalPage:_OnDrag(go, eventData)
  local delta = eventData.delta
  if self.objRotation then
    local targetTran1 = self.objRotation.transform
    local angles = targetTran1.localEulerAngles
    angles.y = angles.y - delta.x
    targetTran1.localEulerAngles = angles
  end
end

function ValentineCrystalPage:_ShowHelp()
  if self.m_isShowList == false then
    self.m_isShowList = true
    self.tab_Widgets.obj_list:SetActive(self.m_isShowList)
    self.tab_Widgets.mask_list.gameObject:SetActive(self.m_isShowList)
  end
  self:ShowGrilList()
end

function ValentineCrystalPage:_CloseHelp()
  if self.m_isShowList == true then
    self.m_isShowList = false
    self.tab_Widgets.obj_list:SetActive(self.m_isShowList)
    self.tab_Widgets.mask_list.gameObject:SetActive(self.m_isShowList)
  end
end

function ValentineCrystalPage:ShowGrilList()
  local allHeroList = self.m_allHeroList
  local ownedHeroList = self.m_ownedHeroList
  UIHelper.CreateSubPart(self.tab_Widgets.item_ship, self.tab_Widgets.rect_content, #allHeroList, function(index, tabPart)
    if allHeroList[index] ~= nil then
      local shipFigure = configManager.GetDataById("config_interaction_figurte", allHeroList[index])
      tabPart.im_choose:SetActive(false)
      tabPart.im_no.gameObject:SetActive(true)
      UIHelper.SetImage(tabPart.im_no, tostring(shipFigure.figure_icon))
      tabPart.im_girl.gameObject:SetActive(false)
      if allHeroList[index] == self.m_curshipGril then
        tabPart.im_choose:SetActive(true)
      end
      for i, v in pairs(ownedHeroList) do
        if v == allHeroList[index] then
          tabPart.im_no.gameObject:SetActive(false)
          tabPart.im_girl.gameObject:SetActive(true)
          UIHelper.SetImage(tabPart.im_girl, tostring(shipFigure.figure_icon))
          UGUIEventListener.AddButtonOnClick(tabPart.item_ship, self._ChangeClickIcon, self, {
            id = allHeroList[index]
          })
        end
      end
      UIHelper.SetImage(tabPart.im_pinzhi, UserHeadQualityImg[shipFigure.figure_quality])
    end
  end)
end

function ValentineCrystalPage:_GetCrystalCameraParam()
  local cameraRelativePos = configManager.GetDataById("config_parameter", 323).arrValue
  local cameraRelativeRot = configManager.GetDataById("config_parameter", 324).arrValue
  local fieldOfView = configManager.GetDataById("config_parameter", 327).value
  local size = configManager.GetDataById("config_parameter", 325).value
  local tabCameraParam = {
    cameraRelativePos = cameraRelativePos,
    cameraRelativeRot = cameraRelativeRot,
    fieldOfView = fieldOfView,
    size = size,
    usePerspective = true
  }
  return tabCameraParam
end

function ValentineCrystalPage:_ChangePre()
  self.m_curIndex = self:__GetGirlIndex()
  if self.m_curIndex == 1 then
    self.m_curIndex = #self.m_ownedHeroList
  else
    self.m_curIndex = self.m_curIndex - 1
  end
  if self.m_ownedHeroList[self.m_curIndex] then
    self.m_curshipGril = self.m_ownedHeroList[self.m_curIndex]
  end
  self:__RefreshChangeView()
end

function ValentineCrystalPage:_ChangeNext()
  self.m_curIndex = self:__GetGirlIndex()
  if self.m_curIndex == #self.m_ownedHeroList then
    self.m_curIndex = 1
  else
    self.m_curIndex = self.m_curIndex + 1
  end
  if self.m_ownedHeroList[self.m_curIndex] then
    self.m_curshipGril = self.m_ownedHeroList[self.m_curIndex]
  end
  self:__RefreshChangeView()
end

function ValentineCrystalPage:_ChangeClickIcon(go, param)
  self.m_curshipGril = param.id
  self.m_curIndex = self:__GetGirlIndex()
  self:__RefreshChangeView()
end

function ValentineCrystalPage:_ClickBlindBoxShop()
  UIHelper.OpenPage("BlindBoxShopPage")
end

function ValentineCrystalPage:__RefreshChangeView()
  local widgets = self.tab_Widgets
  local ownNum = #self.m_ownedHeroList
  local totalNum = #self.m_allHeroList
  local numText = string.format(configManager.GetDataById("config_language", 1300044).content, ownNum, totalNum)
  UIHelper.SetText(widgets.txt_num, numText)
  self.tab_Widgets.obj_list:SetActive(self.m_isShowList)
  self.tab_Widgets.mask_list.gameObject:SetActive(self.m_isShowList)
  self:_Destory3DObj()
  if self.m_curshipGril > 0 then
    widgets.obj_nameboard:SetActive(true)
    self:__CreateSnowBabyModel()
  else
    widgets.obj_nameboard:SetActive(false)
    self:__CreateCrystalModel()
  end
  self:_ShowCrystalBallInUI()
  if self.m_isShowList == true then
    self:ShowGrilList()
  end
end

function ValentineCrystalPage:_ClickClose()
  UIHelper.ClosePage("ValentineCrystalPage")
end

function ValentineCrystalPage:DoOnHide()
end

function ValentineCrystalPage:DoOnClose()
  self:_Destory3DObj()
  if self.m_curshipGril ~= 0 then
    if self.ballId == ActivityInteractionItemId.ChristmasCrystalBallId then
      local arg = {
        ToyId = self.m_curshipGril
      }
      Service.activitychristmasshopService:SendSetToy(arg)
    else
      local interactionItemTab = {
        ballId = self.ballId,
        ToyId = self.m_curshipGril
      }
      Service.interactionItemService:SetCrystalBallToyState(interactionItemTab)
    end
  end
end

function ValentineCrystalPage:_Destory3DObj()
  if not IsNil(self.m_sprayObj) then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_sprayObj)
  end
  if not IsNil(self.m_crystalBall) then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_crystalBall)
  end
  if self.m_ObjinUI then
    UIHelper.Close3DModel(self.m_ObjinUI)
  end
  self.m_crystalBall = nil
  self.m_sprayObj = nil
  self.m_ObjinUI = nil
end

return ValentineCrystalPage
