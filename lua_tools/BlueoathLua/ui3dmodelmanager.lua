UI3DModelManager = class("util.UI3DModelManager")
UI3DModelBase = require("ui.framework.UI3DModelBase")
local ShipUI3DModel = require("ui.framework.ShipUI3DModel")
local OtherUI3DModel = require("ui.framework.OtherUI3DModel")

function UI3DModelManager.Create3DModel(modelType, createParam, rawImg, cameraParam, renderDirectly, renderToGlobal, commonCameraParam)
  local model
  if modelType == UI3DModelType.ShipGirl then
    model = ShipUI3DModel:new(rawImg, renderDirectly, renderToGlobal, GameCameraType.UI3DModel)
  else
    local cameraType = cameraParam.cameraType == nil and GameCameraType.UI3DModel or cameraParam.cameraType
    model = OtherUI3DModel:new(rawImg, renderDirectly, renderToGlobal, cameraType)
  end
  if createParam then
    model:CreateObj(createParam)
    model:Show()
    if cameraParam ~= nil then
      model:ApplyCameraParam(cameraParam, commonCameraParam)
    end
  end
  return model
end

function UI3DModelManager.Close3DModel(model)
  model:Destroy()
end

return UI3DModelManager
