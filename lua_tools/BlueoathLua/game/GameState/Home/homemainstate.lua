local HomeMainState = class("Game.GameState.Home.HomeMainState", require("Game.GameState.GameState"))
local json = require("cjson")
local super = HomeMainState.super
local DEFAULT_ANIM_NAME = "stand_loop"
local INTERRUPT = 1
local oldRoomConfig = require("config/ClientConfig/NewRoomSceceCameraConfig")
local newRoomConfig = require("config/ClientConfig/NewRoomSceceCameraConfig")
local angleConfig = require("config/ClientConfig/RoomSceneAngleConfig")
local cameraPosManager = require("game.CameraPosition.CameraPosManager")
local cameraDir
local playAnimType = {playSpecial = 1, playNormal = 2}
local maxRate = 10000
local action_interrupt = {
  click1 = 1,
  click2 = 1,
  click3 = 1,
  turn = 0,
  turn_l = 0,
  stand_loop = 1
}
local moveMode = 1
local zoomRadio = 1
local maxRadio = 1.3
local minRadio = 0.7
local nFov = 45
local objCam, transCam
local totalAngle = 0
local orignalModelForward
local config = {
  [1] = oldRoomConfig,
  [2] = newRoomConfig
}
local roomConfig = oldRoomConfig
local default = json.encode(Vector3.New(0, 0, 0))
local homeSceneObj

function HomeMainState:initialize()
  super.initialize(self)
  self:__clearObj()
  self.transLight = nil
  self.m_vecLightEur = nil
  self.m_vecDelta = Vector3.New(0, 0, 0)
  self.clickPos = Vector3.New(0, 0, 0)
  self.vec3ModelForward = orignalModelForward
  self.vec3ModelOldForward = nil
  self.cameraPosMgr = nil
  self.m_pagePos = false
  self.m_animPos = false
  self.m_modelAnimName = nil
  self.bCanLogin = true
  self.bCanDrag = false
  self.changeScene = false
  self.IsMarry = false
  self.ModelAnim = {}
  self.objScene = nil
  self.tblGift = {}
  self.fireworksObj = nil
end

function HomeMainState:onStart(param)
  platformManager:sendUserInfo(SendUserInfoType.EnterHome)
  super.onStart(self)
  GR.cameraManager:showCamera(GameCameraType.RoomSceneCamera)
  self.objScene = homeEnvManager:ChangeScene(SceneType.HOME, true)
  homeSceneObj = self.objScene
  self:__registerInput()
  self:__changeMainScene(false)
  self:__addGift()
end

function HomeMainState:__addGift()
  local myItems = Logic.interactionItemLogic:GetRemindItem()
  for i, v in pairs(self.tblGift) do
    self:__DelIntreactionItem(i)
  end
  for i, v in pairs(myItems) do
    self:__AddIntreactionItem(v)
  end
end

function HomeMainState:__CreateSnowGlobalBaby(ballId)
  local snowBabyId = Logic.interactionItemLogic:GetShowToyIdByBallId(ballId)
  local _, ballToDoll = Logic.interactionItemLogic:GetBallAndToyPositionId()
  local ToyId = ballToDoll[ballId]
  if snowBabyId == 0 then
    return
  end
  local shipGirlConfig = configManager.GetDataById("config_interaction_figurte", snowBabyId)
  local shipGrilModelPath = shipGirlConfig.figure_name
  local babyItemPath = "modelsq/" .. shipGrilModelPath .. "/" .. shipGrilModelPath
  local itemPosition = configManager.GetDataById("config_interaction_item", ToyId).item_location_coordinate
  local babyObjGift = GR.objectPoolManager:LuaGetGameObject(babyItemPath, self.objScene.transform)
  CS.UnityTools.SetLayer(18, babyObjGift.transform)
  babyObjGift.transform.localPosition = Vector3.New(itemPosition[1][1], itemPosition[1][2], itemPosition[1][3])
  babyObjGift.transform.localEulerAngles = Vector3.New(itemPosition[2][1], itemPosition[2][2], itemPosition[2][3])
  babyObjGift.transform.localScale = Vector3.New(itemPosition[3][1], itemPosition[3][2], itemPosition[3][3])
  self.tblGift[ToyId] = babyObjGift
end

function HomeMainState:setCanPlayLogin(bCanLogin)
  self.bCanLogin = bCanLogin
end

function HomeMainState:__initLight()
  local light = GR.sceneManager.curSceneInfo.controlLight
  self.transLight = light.transform
  self.m_vecLightEur = self.transLight.localEulerAngles
end

function HomeMainState:onEnd()
  super.onEnd(self)
  GR.cameraManager:hideCamera(GameCameraType.RoomSceneCamera, false)
  inputManager:UnregisterAllInput(self)
  if self.shipGirlObj then
    GR.shipGirlManager:destroyShipGirl(self.shipGirlObj)
    self.shipGirlObj = nil
  end
  for _, v in pairs(self.tblGift) do
    GR.objectPoolManager:LuaUnspawnAndDestory(v)
  end
  self.tblGift = {}
  self:__clearObj()
  self.transLight = nil
  if self.co ~= nil then
    coroutine.stop(self.co)
  end
  self.bCanDrag = false
  self.changeScene = false
  self.shipName = nil
  self.ModelAnim = {}
  self:__destroyFireworksEff()
end

function HomeMainState:registerAllEvents()
  self:registerEvent(LuaEvent.HomeChangeShipGirl, self.__changeShipGirl)
  self:registerEvent(LuaEvent.HomePlayTween, self.__playTween)
  self:registerEvent(LuaEvent.HomeResetModel, self.__resetModel)
  self:registerEvent(LuaEvent.PlayWaitAnim, self.__playWaitAnim)
  self:registerEvent(LuaEvent.HomeResetShip, self.__resetShip)
  self:registerEvent(LuaEvent.HideGirlMech, self.__hideGirlMech)
  self:registerEvent(LuaEvent.HomePauseBehavior, self.__pauseBehavior)
  self:registerEvent(LuaEvent.IsCloseHomeGirl, self.__homeMainInput)
  self:registerEvent(LuaEvent.ChangeMainScene, self.__changeMainScene, self)
  self:registerEvent(LuaEvent.PlayLoginAnim, self.__playLoginAnim, self)
  self:registerEvent(LuaEvent.IsMarry, self.__IsMarry)
  self:registerEvent(LuaEvent.HomeCameraChange, self.__AnimChangeCamera)
  self:registerEvent(LuaEvent.RefreshAllInteractionItem, self.__addGift)
  self:registerEvent(LuaEvent.PlayNewYearEff, self.__palyFireworksEff)
  self:registerEvent(LuaEvent.StopNewYearEff, self.__destroyFireworksEff)
  self:registerEvent(LuaEvent.FreshPaperCutShow, self.__RefreshPaperCutShow)
end

function HomeMainState:__DelIntreactionItem(itemId)
  if self.tblGift[itemId] then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.tblGift[itemId])
    self.tblGift[itemId] = nil
  else
  end
end

function HomeMainState:__AddIntreactionItem(itemId)
  local itemConfig = configManager.GetDataById("config_interaction_item", itemId)
  if itemConfig.interaction_item_type == InteractionItemType.SnowGlobe then
    self:__RefreshSnowGlobeShow(itemId)
  end
  if self.tblGift[itemId] ~= nil then
    return
  end
  local sceneNow = configManager.GetDataById("config_home_scene_envir", homeEnvManager:GetSceneId())
  local sceneREsource = sceneNow.envir_resource
  local itemPath = itemConfig.item_name
  if sceneREsource == "scenes/cj_tds_002" then
    itemPath = itemConfig.item_name_dawn
  elseif sceneREsource == "scenes/cj_tds_003" then
    itemPath = itemConfig.item_name_night
  end
  if itemConfig.interaction_item_type == InteractionItemType.PaperCut then
    local clickedPaperCutting = Data.interactionItemData:GetClickedSpringPaperFlower()
    if not clickedPaperCutting[itemId] then
      itemPath = configManager.GetDataById("config_interaction_item", ActivityInteractionItemId.PaperCutEffectId).item_name
    end
  end
  if itemConfig.interaction_item_type == InteractionItemType.Posters then
    local posterId = Logic.interactionItemLogic:GetPosterByPoint(itemId)
    if posterId ~= 0 then
      local posterConfig = configManager.GetDataById("config_interaction_item_bag", posterId)
      itemPath = posterConfig.item_name
      if sceneREsource == "scenes/cj_tds_002" then
        itemPath = posterConfig.item_name_dawn
      elseif sceneREsource == "scenes/cj_tds_003" then
        itemPath = posterConfig.item_name_night
      end
    else
      local canRedDot = Logic.interactionItemLogic:GetCanShowPosterEffect(itemId)
      if canRedDot then
        local effectPath = itemConfig.effect_item_name
        itemPath = effectPath
      end
    end
  end
  local itemPosition = itemConfig.item_location_coordinate
  local objGift = GR.objectPoolManager:LuaGetGameObject(itemPath, self.objScene.transform)
  objGift.transform.localPosition = Vector3.New(itemPosition[1][1], itemPosition[1][2], itemPosition[1][3])
  objGift.transform.localEulerAngles = Vector3.New(itemPosition[2][1], itemPosition[2][2], itemPosition[2][3])
  objGift.transform.localScale = Vector3.New(itemPosition[3][1], itemPosition[3][2], itemPosition[3][3])
  self.tblGift[itemId] = objGift
end

function HomeMainState:__RefreshSnowGlobeShow(ballId)
  if ballId == nil or ballId == 0 then
    return
  end
  local _, ballToDoll = Logic.interactionItemLogic:GetBallAndToyPositionId()
  local ToyId = ballToDoll[ballId]
  self:__DelIntreactionItem(ToyId)
  self:__CreateSnowGlobalBaby(ballId)
end

function HomeMainState:__RefreshPaperCutShow(state)
  self:__DelIntreactionItem(state)
  self:__AddIntreactionItem(state)
end

function HomeMainState:__changeMainScene(isManually)
  self:__initLight()
  self.cameraPosMgr = cameraPosManager:new()
  local mSceneType = Logic.homeLogic:GetDefaultScene()
  roomConfig = config[mSceneType]
  self.changeScene = isManually
end

function HomeMainState:__homeMainInput(param)
  if param then
    inputManager:UnregisterAllInput(self)
  else
    self:__registerInput()
  end
end

function HomeMainState:__clearObj()
  self.rotateAngle = 0
  self.orignalLocalPos = nil
  self.orignalLocalEur = nil
  self.beforeAnim = nil
  self.gameCamera = nil
  self.shipGirlObj = nil
  self.nDressupId = nil
  self.modelName = nil
  self.shipGirlTrans = nil
  self.tweenPos = nil
  self.tweenRot = nil
  self.nModelForward = 0
  self.bSendShowPageEvent = false
  self.cameraPosMgr = nil
  self.m_pagePos = false
  self.m_animPos = false
  self.m_modelAnimName = nil
  self.shipName = nil
end

function HomeMainState:__registerInput()
  local tabParam = {
    dragMove = function(param)
      self:__onDragMove(param)
    end,
    dragEnd = function(param)
      self:__onDragEnd(param)
    end,
    click = function(param)
      self:__onClick(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function HomeMainState:__onDragMove(delta)
  local angle = delta.x * roomConfig.rotateSpeed
  self.rotateAngle = (self.rotateAngle + angle) % 360
  self:__setLightByAngle()
  self:__sendHomeTimerStart()
  if self.bCanDrag ~= false then
    self.cameraPosMgr:DragCamera(self.shipGirlTrans.localPosition, self.rotateAngle)
  end
end

function HomeMainState:__resetModel()
  if self.shipGirlObj ~= nil then
    self.shipGirlObj:playBehaviour("stand_loop", true)
  end
end

function HomeMainState:__resetShip()
  if self.shipGirlObj ~= nil then
  end
end

function HomeMainState:__setLightByAngle()
  self.m_vecDelta:Set(0, self.rotateAngle, 0)
  self.transLight.localEulerAngles = self.m_vecLightEur + self.m_vecDelta
end

function HomeMainState:__onClick(pos)
  if self.shipGirlObj == nil then
    return
  end
  self.clickPos = pos
  local dir = self.cameraPosMgr:GetCameraPos() - self.shipGirlTrans.localPosition
  dir.y = 0
  local orignal = self:__getOrignalDir()
  local angle = Vector3.AngleAroundAxis(dir.normalized, orignal, Vector3.up)
  self:__playAnim(math.floor(angle))
  self.bSendShowPageEvent = true
  local colliderType = self.shipGirlObj:checkClickCollider(self.clickPos)
  if colliderType ~= AnimColliderType.BodyCollder and colliderType ~= AnimColliderType.ChestCollider then
    self:__checkGift(pos)
  end
end

function HomeMainState:__checkGift(pos)
  local cam = GR.cameraManager:getGameCamera(GameCameraType.RoomSceneCamera)
  local ray = cam:ScreenPointToRay(pos, 2)
  local nLayerMask = LayerMask.GetMask("Scene_Interactive")
  local res = Physics.RaycastAll(ray.origin, ray.direction * 10000, 1000, nLayerMask)
  local length = res.Length - 1
  local itemId = 0
  local itemIdList = {}
  for i = 0, length do
    for j, k in pairs(self.tblGift) do
      if self.tblGift[j] == res[i].collider.gameObject then
        table.insert(itemIdList, j)
      end
    end
  end
  if #itemIdList ~= 0 then
    itemId = itemIdList[1]
  end
  if itemId ~= 0 then
    Logic.interactionItemLogic:ClickInteractionItemRet(itemId)
  end
end

function HomeMainState:__getOrignalDir()
  return self.vec3ModelForward
end

function HomeMainState:__resetLightRot(tblConfig)
  local tblLightRot = roomConfig.lightDefaultRot
  if tblConfig.lightRot ~= nil then
    tblLightRot = tblConfig.lightRot
  end
  local vecTarget = Vector3.New(tblLightRot[1], tblLightRot[2], tblLightRot[3])
  self.m_vecLightEur = vecTarget
end

function HomeMainState:__playAnim(angle)
  if not self:__checkCanInterrupt() then
    return
  end
  local absAngle = angle < 0 and angle + 360 or angle
  local colliderType = self.shipGirlObj:checkClickCollider(self.clickPos)
  if colliderType == AnimColliderType.None then
    return
  elseif colliderType == AnimColliderType.BodyCollder then
    self:_playNormalAnim(absAngle)
  else
    local playType = self:_GetRandomNum()
    if playType == playAnimType.playSpecial then
      self:_playSpecialAnim(absAngle, colliderType)
    else
      self:_playNormalAnim(absAngle)
    end
  end
  eventManager:SendEvent(LuaEvent.HomeTimerStop)
  Service.taskService:SendTaskTrigger(TaskKind.HITSHIP)
  Logic.homeLogic:SetModelClick()
end

function HomeMainState:_GetRandomNum()
  local playType = playAnimType.playSpecial
  local rate = configManager.GetDataById("config_parameter", 91).value
  local randomNum = math.random(1, maxRate)
  if rate >= randomNum then
    playType = playAnimType.playSpecial
  else
    playType = playAnimType.playNormal
  end
  return playType
end

function HomeMainState:_playSpecialAnim(angle, colliderType)
  self:__resetCollider()
  local config = angleConfig.modelSpecialAnimConfig[colliderType]
  for i = 1, #config.AngleRange do
    local angleRange = config.AngleRange[i]
    if angle >= angleRange.startAngle and angle <= angleRange.endAngle then
      eventManager:SendEvent(LuaEvent.HomeClickShip, config.animName)
      eventManager:SendEvent(LuaEvent.ShowHomePageBtn, true)
      eventManager:SendEvent(LuaEvent.HomeShowName, true)
      self:__AnimChangeCamera(false)
      self.shipGirlObj:playBehaviour(config.animName, false, function()
        self:__sendHomeTimerStart()
        self.shipGirlObj:playBehaviour("stand_loop", true)
        if self.bSendShowPageEvent then
          self:__AnimChangeCamera(true)
          eventManager:SendEvent(LuaEvent.HomeShowName, false)
          eventManager:SendEvent(LuaEvent.ShowHomePageBtn, false)
          self.bSendShowPageEvent = false
          Logic.homeLogic:SetModelAnimEnd()
        end
      end)
      return
    end
  end
  self:_playNormalAnim(angle)
end

function HomeMainState:_playNormalAnim(absAngle)
  self:__resetCollider()
  local haveAnims = self:__getAnimNames(absAngle)
  if #haveAnims ~= 1 and self.beforeAnim ~= nil then
    for k, v in ipairs(haveAnims) do
      if v == self.beforeAnim then
        table.remove(haveAnims, k)
        break
      end
    end
  end
  if 0 < #haveAnims then
    local index = math.random(1, #haveAnims)
    local name = haveAnims[index]
    eventManager:SendEvent(LuaEvent.ShowHomePageBtn, true)
    local funcAnimCom = function(animName)
      eventManager:SendEvent(LuaEvent.HomeShowName, false)
      self:__AnimChangeCamera(true)
      self:__sendHomeTimerStart()
      self.shipGirlObj:playBehaviour("stand_loop", true)
      if self.bSendShowPageEvent then
        eventManager:SendEvent(LuaEvent.ShowHomePageBtn, false)
        self.bSendShowPageEvent = false
        Logic.homeLogic:SetModelAnimEnd()
      end
    end
    if name == "turn" then
      local nAngle = self:__getTurnAngle()
      if nAngle < 0 then
        local bHaveTurnL = self:__modelHaveAnim("turn_l")
        if not bHaveTurnL then
          nAngle = nAngle + 360
        end
      end
      self.shipGirlObj:playTurn(nAngle, funcAnimCom)
      if name == "turn" or name == "turn_l" then
        self.vec3ModelOldForward = self.vec3ModelForward
        self.vec3ModelForward = cameraDir
        local firstCamera = GR.cameraManager:getGameCamera(GameCameraType.RoomSceneCamera):GetTransByPriority(0, index)
        local dotInfo = {
          info = "scene_girl_orientation",
          ship_name = self.shipName,
          rotation_y = firstCamera.localEulerAngles.y
        }
        RetentionHelper.Retention(PlatformDotType.sceneLog, dotInfo)
        self:__SetHeadLookTarget()
      end
    else
      self.shipGirlObj:playBehaviour(name, false, funcAnimCom)
    end
    eventManager:SendEvent(LuaEvent.HomeShowName, true)
    self:__AnimChangeCamera(false)
    eventManager:SendEvent(LuaEvent.HomeClickShip, name)
    self.beforeAnim = name
  else
    logError(string.format("\232\167\146\229\186\166 %d \230\156\170\233\133\141\231\189\174\229\138\168\228\189\156", absAngle))
  end
end

function HomeMainState:__getTurnAngle()
  cameraDir = self.cameraPosMgr:GetCameraPos() - self.shipGirlTrans.localPosition
  local angle = Vector3.AngleAroundAxis(self.vec3ModelForward, cameraDir, Vector3.up)
  totalAngle = totalAngle + angle
  PlayerPrefs.SetFloat("turnAngle", totalAngle)
  PlayerPrefs.SetFloat("rotateAngle", self.rotateAngle)
  PlayerPrefs.Save()
  return angle
end

function HomeMainState:__AnimChangeCamera(isToHome)
  if not isToHome then
    if not self.m_pagePos and not self.m_animPos then
      self.m_animPos = true
      self.cameraPosMgr:CameraPosChange(CameraSwitchType.HomeToAnim)
    end
  elseif not self.m_pagePos and self.m_animPos then
    self.m_animPos = false
    self.cameraPosMgr:CameraPosChange(CameraSwitchType.AnimToHome)
  end
end

function HomeMainState:__ResetCamera()
  if self.shipGirlObj == nil then
    return
  end
  self.m_animPos = false
  self.rotateAngle = 0
  self.vec3ModelForward = orignalModelForward
  self:__setLightByAngle()
  if not self.m_pagePos then
    self.cameraPosMgr:ResetCameraPos(self.shipGirlTrans.localPosition, CameraSwitchType.AnimToHome)
  else
    self.cameraPosMgr:ResetCameraPos(self.shipGirlTrans.localPosition, CameraSwitchType.HomeToPage)
  end
end

function HomeMainState:__playWaitAnim()
  if self.shipGirlObj == nil then
    self:__sendHomeTimerStart()
    return
  end
  self.shipGirlObj:playBehaviour("wait", false, function()
    self:__sendHomeTimerStart()
    self.shipGirlObj:playBehaviour("stand_loop", true)
  end)
end

function HomeMainState:__setTurnAngle(nAngle)
  self.shipGirlTrans.localEulerAngles = self.shipGirlTrans.localEulerAngles + Vector3.New(0, nAngle, 0)
  self.vec3ModelForward = self.shipGirlTrans.forward
end

function HomeMainState:__sendHomeTimerStart()
  eventManager:SendEvent(LuaEvent.HomeTimerStart)
end

function HomeMainState:__checkCanInterrupt()
  if self.shipGirlObj == nil then
    return true
  end
  local strCurBehaviourName = self.shipGirlObj:GetBehaviourName()
  local nInterruptParam = action_interrupt[strCurBehaviourName]
  if nInterruptParam == nil then
    return true
  end
  return nInterruptParam == INTERRUPT
end

function HomeMainState:__modelHaveAnim(strAnimName)
  local shipAnimNames = self.m_modelAnimName
  if table.containValue(shipAnimNames, strAnimName) then
    return true
  end
  return false
end

function HomeMainState:__getAnimNames(angle)
  local anims = {}
  for _, v in ipairs(self.ModelAnim) do
    if self:__angleOnConfig(v, angle) then
      local animNames = v.animNames
      local shipAnimNames = self.m_modelAnimName
      for k, name in ipairs(animNames) do
        if table.containValue(shipAnimNames, name) then
          table.insert(anims, name)
        end
      end
      break
    end
  end
  return anims
end

function HomeMainState:__angleOnConfig(animConfig, angle)
  if animConfig.startAngle > animConfig.endAngle then
    local startAngle1 = animConfig.startAngle
    local endAngle1 = 360
    local startAngle2 = 0
    local endAngle2 = animConfig.endAngle
    if self:__angleInLimit(startAngle1, endAngle1, angle) then
      return true
    end
    if self:__angleInLimit(startAngle2, endAngle2, angle) then
      return true
    end
    return false
  end
  return self:__angleInLimit(animConfig.startAngle, animConfig.endAngle, angle)
end

function HomeMainState:__angleInLimit(startAngle, endAngle, angle)
  return startAngle <= angle and angle <= endAngle
end

function HomeMainState:__hideGirlMech(param)
  if self.shipGirlObj then
    self.shipGirlObj:changeSpecifyPartState(param)
  end
end

function HomeMainState:__IsMarry(param)
  self.IsMarry = param
end

function HomeMainState:__changeShipGirl(param)
  local createParam = param[1]
  local bInitToStartPos = param[2]
  local playLogin = param[3]
  local changeSecretary = param[4]
  local showID = createParam.showID
  local dressID = createParam.dressID
  self.heroID = createParam.heroID
  if self.shipGirlObj and showID == self.shipGirlObj.showID and dressID == self.shipGirlObj.dressID and not self.changeScene then
    return
  end
  if self.shipGirlObj ~= nil then
    GR.shipGirlManager:destroyShipGirl(self.shipGirlObj)
    self.shipGirlObj = nil
    self.bCanDrag = false
  end
  createParam.enableHeadLook = true
  createParam.camera = self.gameCamera
  createParam.isSelfShadow = true
  self.shipGirlObj = GR.shipGirlManager:createShipGirl(createParam, LayerMask.NameToLayer("MainSceneShip"))
  self.bCanDrag = true
  self.changeScene = false
  self.modelName = self.shipGirlObj.resName
  self.shipName = configManager.GetDataById("config_ship_show", self.shipGirlObj.showID).ship_name
  self.shipGirlTrans = self.shipGirlObj.transform
  self:__getModelAnim()
  self.shipGirlTrans.localEulerAngles = Vector3.NewFromTab(roomConfig.orignalEuler)
  orignalModelForward = self.shipGirlTrans.forward
  self.vec3ModelForward = orignalModelForward
  local tblConfig = roomConfig.modleConfigList[self.modelName]
  self.shipGirlTrans.localPosition = Vector3.NewFromTab(tblConfig.modelPos)
  self.shipGirlObj:setModelScale(Vector3.NewFromTab(tblConfig.modelScale))
  self.cameraPosMgr:Init(roomConfig, tblConfig)
  self.shipGirlObj.shipView:SetChestCollider()
  eventManager:FireEventToCSharp(LuaCSharpEvent.MainSceneCharacterShadowFocus, self.shipGirlTrans)
  if not bInitToStartPos then
    self.cameraPosMgr:ModelChange(self.shipGirlTrans.localPosition, CameraSwitchType.PageToHome)
  else
    self.cameraPosMgr:ModelChange(self.shipGirlTrans.localPosition, CameraSwitchType.HomeToPage)
  end
  self:__SetHeadLookTarget()
  if changeSecretary then
    self:__playLoginAnim(playLogin, changeSecretary)
  end
  self.rotateAngle = PlayerPrefs.GetFloat("rotateAngle", 0)
  totalAngle = PlayerPrefs.GetFloat("turnAngle", 0)
  self:__setTurnAngle(totalAngle)
  self:__resetLightRot(tblConfig)
  self:__setLightByAngle()
  self.m_modelAnimName = ScrProfileHub.GetModelAnimName(self.modelName)
  if changeSecretary then
    local firstCamera = GR.cameraManager:getGameCamera(GameCameraType.RoomSceneCamera):GetTransByPriority(0, index)
    local dotInfo = {
      info = "scene_girl_orientation",
      ship_name = self.shipName,
      rotation_y = firstCamera.localEulerAngles.y
    }
    RetentionHelper.Retention(PlatformDotType.sceneLog, dotInfo)
  end
end

function HomeMainState:__SetHeadLookTarget()
  local objCam = GR.cameraManager:getGameCamera(GameCameraType.RoomSceneCamera)
  local transCam = objCam:getCamTrans()
  self.shipGirlObj:SetHeadLookTarget(transCam, true)
end

function HomeMainState:__playLoginAnim(login, changeSec)
  self:__resetCollider()
  local loginName = "login"
  if self.IsMarry then
    loginName = "login_m"
  end
  if self.bCanLogin then
    self.shipGirlObj:playBehaviour(loginName, false, function()
      self:__sendHomeTimerStart()
      self.shipGirlObj:playBehaviour("stand_loop", true)
    end)
  else
    self:__sendHomeTimerStart()
  end
end

function HomeMainState:__playTween(forward)
  if forward and not self.m_pagePos then
    self.m_pagePos = true
    self.m_animPos = false
    self.cameraPosMgr:CameraPosChange(CameraSwitchType.HomeToPage)
  elseif not forward then
    self.cameraPosMgr:CameraPosChange(CameraSwitchType.PageToHome)
    self.m_pagePos = false
  end
end

function HomeMainState:__onMoveModeChange()
  if moveMode == 1 then
    moveMode = 2
    self:__registerModeBInput()
    objCam = GR.csharpCameraManager.MainCamera
    transCam = objCam.transform
  else
    moveMode = 1
    self:__registerInput()
  end
end

function HomeMainState:__registerModeBInput()
  local tabParam = {
    dragMove = function(param)
      self:__onModeBDrag(param)
    end,
    click = function(param)
      self:__onClick(param)
    end,
    zoom = function(param)
      self:__onModeBZoom(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function HomeMainState:__onModeBDrag(delta)
  local deltaX = delta.x
  local deltaY = delta.y
  deltaX = deltaX / 3
  deltaY = deltaY / 3
  local tarPos = self.shipGirlTrans.localPosition + self:__getTargetPos()
  transCam:RotateAround(tarPos, Vector3.up, deltaX)
  transCam:RotateAround(tarPos, Vector3.right, -deltaY)
  transCam:LookAt(tarPos)
end

function HomeMainState:__onModeBZoom(delta)
  local curRadio = zoomRadio
  zoomRadio = zoomRadio + delta * 0.01
  zoomRadio = math.max(zoomRadio, minRadio)
  zoomRadio = math.min(zoomRadio, maxRadio)
  local cam = objCam:GetComponent(UnityEngine_Camera.GetClassType())
  cam.fieldOfView = -zoomRadio * nFov
end

function HomeMainState:__getTargetPos()
  local angle = self.orignalLocalEur.x
  local length = math.sqrt(self.orignalLocalPos.x * self.orignalLocalPos.x + self.orignalLocalPos.z * self.orignalLocalPos.z)
  local yLenth = math.tan(math.rad(angle)) * length
  return Vector3.New(0, self.orignalLocalPos.y - yLenth, 0)
end

function HomeMainState:__onDragEnd(param)
  Logic.homeLogic:SetDragCamEnd()
end

function HomeMainState:__pauseBehavior(enable)
  if enable then
    self.shipGirlObj:PauseBehaviour()
  else
    self.shipGirlObj:ContinueBehaviour()
  end
end

function HomeMainState:__getModelAnim()
  self.ModelAnim = clone(angleConfig.modelAnimConfig)
  local shipSfId = configManager.GetDataById("config_ship_show", self.shipGirlObj.showID).sf_id
  if self.heroID then
    local curfashion = Logic.fashionLogic:GetCurFashionData(self.heroID)
    if curfashion then
      local fashionAction = curfashion.unlock_action
      for _, name in ipairs(fashionAction) do
        table.insert(self.ModelAnim[1].animNames, name)
        table.insert(self.ModelAnim[3].animNames, name)
      end
    end
  end
end

function HomeMainState:__resetCollider()
  if self.shipGirlObj ~= nil then
    self.shipGirlObj:resetCollider()
  end
end

function HomeMainState:__palyFireworksEff()
  local sceneNow = homeEnvManager:GetCurrScene()
  if sceneNow ~= "scenes/cj_tds_003" then
    return
  end
  local effName = Logic.activityLogic:GetSignEffName()
  if not effName then
    return
  end
  self:__destroyFireworksEff()
  local effPath = "effects/prefabs/" .. effName
  self.fireworksObj = GR.objectPoolManager:LuaGetGameObject(effPath)
  self.fireworksObj.transform:SetParent(self.objScene.transform, false)
end

function HomeMainState:__destroyFireworksEff()
  if self.fireworksObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.fireworksObj)
    self.fireworksObj = nil
  end
end

function HomeMainState:GetSceneObj()
  return homeSceneObj
end

return HomeMainState
