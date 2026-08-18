local InputManager = class("util.InputManager")

function InputManager:initialize()
  local tabParam = {
    dragBegin = function(fIndex, fPos)
      self:_OnInputHandler("dragBegin", fPos)
    end,
    dragMove = function(fIndex, fPos, delta)
      self:_OnInputHandler("dragMove", delta)
    end,
    dragEnd = function(fIndex, fPos)
      self:_OnInputHandler("dragEnd", fPos)
    end,
    zoom = function(fIndex, fPos, delta)
      self:_OnInputHandler("zoom", delta)
    end,
    clickDown = function(fIndex, fPos)
      self:_OnInputHandler("clickDown", fPos)
    end,
    clickUp = function(fIndex, fPos)
      self:_OnInputHandler("clickUp", fPos)
    end,
    click = function(fIndex, fPos)
      self:_OnInputHandler("click", fPos)
    end,
    freeClickUp = function(fIndex, fPos, onUI)
      self:_OnInputHandler("freeClickUp", fPos)
    end,
    freeClickDown = function(fIndex, fPos)
      self:_OnInputHandler("freeClickDown", fPos)
    end,
    freeDragBegin = function(fIndex, fPos, onUI)
      self:_OnInputHandler("freeDragBegin", fPos)
    end,
    freeDragMove = function(fIndex, fPos, delta, onUI)
      self:_OnInputHandler("freeDragMove", fPos)
    end,
    freeDragEnd = function(fIndex, fPos, onUI)
      self:_OnInputHandler("freeDragEnd", fPos)
    end
  }
  LuaInputHelper.RegisterInput(tabParam)
  self.handlerMap = {}
end

function InputManager:_OnInputHandler(inputType, param)
  for k, v in pairs(self.handlerMap) do
    if v[inputType] then
      v[inputType](param)
    end
  end
end

function InputManager:RegisterInput(handler, param)
  local temp = self.handlerMap[handler]
  temp = temp or {}
  for k, v in pairs(param) do
    temp[k] = v
  end
  self.handlerMap[handler] = temp
end

function InputManager:UnRegisterInput(handler, inputType)
  if self.handlerMap[handler] and self.handlerMap[handler][inputTyp] then
    self.handlerMap[handler][inputTyp] = nil
  end
end

function InputManager:UnregisterAllInput(handler)
  if self.handlerMap[handler] then
    self.handlerMap[handler] = nil
  end
end

return InputManager
