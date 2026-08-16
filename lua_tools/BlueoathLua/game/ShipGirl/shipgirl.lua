local ShipGirl = class("game.ShipGirl.ShipGirl")
local BehaviourRetention = require("util.BehaviourRetention")

function ShipGirl:initialize(param, layer, parentTrans)
  self.UID = param.UID
  self.showID = param.showID
  self.dressID = param.dressID
  self.camera = param.camera
  self.girlType = param.girlType and param.girlType or 0
  local isAffectByEnv = true
  if param.isAffectByEnv ~= nil then
    isAffectByEnv = param.isAffectByEnv
  end
  local isSelfShadow = false
  if param.isSelfShadow ~= nil then
    isSelfShadow = param.isSelfShadow
  end
  self.objBoxCollider = nil
  self.objChestCollider = nil
  self:__createModel(isAffectByEnv, isSelfShadow, param.enableHeadLook and true or false, layer, parentTrans)
end

function ShipGirl:destroy()
  self.gameObject = nil
  self.transform = nil
  self.shipView:Destroy()
  self.shipView = nil
  RetentionHelper.SkipGirl(self)
end

function ShipGirl:DressUp(dressID)
  self.dressID = dressID
  self.shipView:DressUp(dressID)
end

function ShipGirl:__createModel(isAffectByEnv, isSelfShadow, enableHeadLook, layer, parentTrans)
  local shipInfo = configManager.GetDataById("config_ship_show", self.showID)
  local shipModel = configManager.GetDataById("config_ship_model", shipInfo.model_id)
  self.resName = shipModel.model
  if layer == nil then
    layer = 0
  end
  self.shipView = UIShipProxy()
  local param = {
    showID = tostring(self.showID),
    dressID = self.dressID,
    affectByEnv = isAffectByEnv,
    headLook = enableHeadLook,
    layer = layer,
    parent = parentTrans,
    girlType = self.girlType,
    isSelfShadow = isSelfShadow
  }
  self.gameObject = self.shipView:LoadModel(param)
  local objModelInterface = self.gameObject:GetComponent(ModelInterface.GetClassType())
  if not IsNil(objModelInterface) then
    self.objBoxCollider = objModelInterface.bodyCollider
    self.objChestCollider = objModelInterface.chestCollider
  end
  local tran = self.gameObject.transform
  self.transform = tran
end

function ShipGirl:resetTurn()
  self.shipView:ResetTurn()
end

function ShipGirl:isAnimPlayingExcept(name)
  return self.shipView:IsAnimPlayingExcept(name)
end

function ShipGirl:changeSpecifyPartState(isShow)
  self.shipView:ChangeSpecifyPartState(isShow)
end

function ShipGirl:resetCollider()
  if not IsNil(self.objBoxCollider) then
    self.objBoxCollider.enabled = false
    self.objBoxCollider.enabled = true
  end
  if not IsNil(self.objChestCollider) then
    self.objChestCollider.enabled = false
    self.objChestCollider.enabled = true
  end
end

function ShipGirl:playBehaviour(behaviourName, isloop, onComplete)
  local handler = BehaviourRetention.CreateHandler(self, behaviourName)
  if not handler then
    local paramTab = {
      isLoop = isloop,
      onComplete = onComplete,
      playTurn = false,
      playDefault = true,
      cameraShot = self.camera
    }
    self.shipView:PlayBehaviour(behaviourName, paramTab)
  else
    local paramTab = {
      isLoop = isloop,
      onComplete = function(...)
        handler:Complete()
        if onComplete then
          onComplete(...)
        end
      end,
      playTurn = false,
      playDefault = true,
      cameraShot = self.camera
    }
    self.shipView:PlayBehaviour(behaviourName, paramTab)
  end
  local sf_id = configManager.GetDataById("config_ship_show", self.showID).sf_id
  local args = {
    [sf_id] = {behaviourName}
  }
  Logic.illustrateLogic:FilterAndSendBehaviour(args)
end

function ShipGirl:setModelScale(scale)
  self.shipView:SetModelScale(scale)
end

function ShipGirl:setModelPosition(pos)
  self.shipView:SetModelPosition(pos)
end

function ShipGirl:interruptTurn()
  self.shipView:InterruptTurn()
end

function ShipGirl:playTurn(nAngle, onComplete)
  local strAnimName = "turn"
  if nAngle < 0 then
    strAnimName = "turn_l"
  end
  local handler = BehaviourRetention.CreateHandler(self, "turn")
  if not handler then
    self.shipView:PlayTurn(strAnimName, nAngle, onComplete)
  else
    self.shipView:PlayTurn(strAnimName, nAngle, function(...)
      handler:Complete()
      if onComplete then
        onComplete(...)
      end
    end)
  end
end

function ShipGirl:getCurBehaviourLength()
  return self.shipView:GetCurBehaviourLength()
end

function ShipGirl:checkClickCollider(pos)
  return self.shipView:CheckCollider(pos)
end

function ShipGirl:setMaterialShader(shaderPath)
  self.shipView:SetMaterialShader(shaderPath)
end

function ShipGirl:show()
  self.gameObject:SetActive(true)
end

function ShipGirl:hide()
  if self.gameObject then
    self.gameObject:SetActive(false)
  end
end

function ShipGirl:GetBehaviourName()
  return self.shipView:GetCurBehaviourName()
end

function ShipGirl:PauseBehaviour()
  self.shipView:PauseBehaviour()
end

function ShipGirl:ContinueBehaviour()
  self.shipView:ContinueBehaviour()
end

function ShipGirl:SetHeadLookTarget(transTarget, bForce)
  self.shipView:SetHeadLookTarget(transTarget, bForce)
end

return ShipGirl
