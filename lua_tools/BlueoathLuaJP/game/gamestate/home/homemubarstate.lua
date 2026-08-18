local HomeMubarState = class("Game.GameState.Home.HomeMubarState", require("Game.GameState.GameState"))
local super = HomeMubarState.super
local cameraCtrl
local mubarCameraCtrl = require("game.CameraPosition.MubarCameraCtrl")
local mubarScene

function HomeMubarState:initialize()
  super.initialize(self)
end

function HomeMubarState:registerAllEvents()
  self:registerEvent(LuaEvent.SkipRemouldScene, self._SkipFinish)
end

function HomeMubarState:onStart(param)
  super.onStart(self)
  self.gameCamera = GR.cameraManager:showCamera(GameCameraType.MubarSceneCamera)
  mubarScene = homeEnvManager:ChangeScene(SceneType.Mubar)
  self.m_camera = self.gameCamera:GetCam()
  CS.PostProcessHud.Instance:ChangePostProcessProfile("bloom_cj_mb_01")
  cameraCtrl = mubarCameraCtrl:new()
  self:_initCamPos()
end

function HomeMubarState:onEnd()
  super.onEnd(self)
  mubarScene = nil
  self.gameCamera = nil
  self.m_camera = nil
  self:StopAutoMove()
end

function HomeMubarState:_initCamPos()
  cameraCtrl:InitCamPos()
end

function HomeMubarState:ChangeCamera(currPos, targetPos, duration, clickChapter)
  cameraCtrl:CameraPosChange(currPos, targetPos, duration, clickChapter)
end

function HomeMubarState:GetSceneObj()
  return mubarScene
end

function HomeMubarState:StopAutoMove()
  cameraCtrl:StopAutoMove()
end

function HomeMubarState:PlaySceneAnim()
  local objFlow1 = mubarScene.transform:Find("CJ_MB_FlowDisslve_01")
  local flowAnim1 = objFlow1.gameObject:GetComponent(UnityEngine_Animator.GetClassType())
  flowAnim1.enabled = true
  local objFlow2 = mubarScene.transform:Find("CJ_MB_FlowDisslve_02")
  local flowAnim2 = objFlow2.gameObject:GetComponent(UnityEngine_Animator.GetClassType())
  flowAnim2.enabled = true
  local objFlow3 = mubarScene.transform:Find("CJ_MB_FlowDisslve_03")
  local flowAnim3 = objFlow3.gameObject:GetComponent(UnityEngine_Animator.GetClassType())
  flowAnim3.enabled = true
end

return HomeMubarState
