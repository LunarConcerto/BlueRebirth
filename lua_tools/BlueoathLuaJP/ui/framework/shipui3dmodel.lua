local ShipUI3DModel = class("ui.framework.ShipUI3DModel", UI3DModelBase)
local typeName = {
  [CamDataType.Settle] = "set",
  [CamDataType.Display] = "get",
  [CamDataType.Detaile] = "details",
  [CamDataType.Study] = "school"
}

function ShipUI3DModel:ApplyCameraParam(type, commonCameraParam)
  local modelName = self.m_3dObj.resName
  local mData = configManager.GetDataById("config_model_camera_config", modelName)
  local cameraData = mData
  local cameraRelativePos = mData[typeName[type] .. "CameraRelativePos"]
  local cameraRelativeRot = mData[typeName[type] .. "CameraRelativeRot"]
  local size = mData[typeName[type] .. "Size"]
  local tabCameraParam = {
    cameraRelativePos = cameraRelativePos,
    cameraRelativeRot = cameraRelativeRot,
    fieldOfView = cameraData.fieldOfView,
    size = size
  }
  self:SetCamerParam(tabCameraParam)
  if commonCameraParam ~= nil then
    self:SetCommonCamParam(commonCameraParam)
  end
end

function ShipUI3DModel:CreateObj(objParam)
  objParam.isAffectByEnv = false
  objParam.camera = self.gameCamera:getShot()
  local parentTrans
  if self.m_objRoot then
    parentTrans = self.m_objRoot.transform
  end
  self.m_3dObj = GR.shipGirlManager:createShipGirl(objParam, LayerMask.NameToLayer("UI3DObject"), parentTrans)
end

function ShipUI3DModel:DestroyObj()
  if self.m_3dObj ~= nil then
    GR.shipGirlManager:destroyShipGirl(self.m_3dObj)
  end
  self.m_3dObj = nil
end

function ShipUI3DModel:DressUp(dressUpId)
  self:Get3dObj():DressUp(dressUpId)
end

function ShipUI3DModel:ObjShow()
  self.m_3dObj:show()
end

function ShipUI3DModel:ObjHide()
  self.m_3dObj:hide()
end

function ShipUI3DModel:HideMech(enable)
  if self.m_3dObj then
    self.m_3dObj:changeSpecifyPartState(enable)
  end
end

return ShipUI3DModel
