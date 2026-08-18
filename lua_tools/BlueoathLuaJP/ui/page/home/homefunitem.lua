local HomeFunItem = class("UI.Home.HomeFunItem")

function HomeFunItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.index = nil
  self.info = nil
end

function HomeFunItem:Init(obj, tabPart, index, info)
  self.page = obj
  self.tabPart = tabPart
  self.index = index
  self.info = info
  self:_SetFunInfo()
end

function HomeFunItem:_SetFunInfo()
  if type(self.info) == "table" then
    self:_SetFunDisplay(self.info[1], self.tabPart)
    UGUIEventListener.AddButtonOnClick(self.tabPart.btn_fun.gameObject, function()
      self.page:_ShowModuleSelect(nil, true)
    end)
    local widgets = self.page:GetWidgets()
    UIHelper.CreateSubPart(widgets.obj_module, widgets.trans_module, #self.info[2], function(childIndex, childTabPart)
      self:_SetModuleFunDisplay(self.info[2][childIndex], childTabPart)
      self:_SetModuleClickFun(childIndex, self.info[2][childIndex], childTabPart)
    end)
  else
    self:_SetFunDisplay(self.info, self.tabPart)
    self:_SetClickFun(self.index, self.info, self.tabPart)
  end
  self.tabPart.trans_child.gameObject:SetActive(false)
end

function HomeFunItem:_SetFunDisplay(funId, part)
  local funConfig = configManager.GetDataById("config_function_info", tostring(funId))
  UIHelper.SetImage(part.image_fun, funConfig.icon, true)
  local redDotIdList = funConfig.focus
  if redDotIdList and 0 < #redDotIdList then
    self.page:RegisterRedDotById(part.redDot, redDotIdList)
  end
  part.txt_iconName.text = funConfig.name
  if not moduleManager:CheckFunc(funId, false) then
    part.obj_lock:SetActive(funConfig.icon_Lock == 1)
  else
    part.obj_lock:SetActive(false)
  end
end

function HomeFunItem:_SetClickFun(index, funId, part)
  UGUIEventListener.AddButtonOnClick(part.btn_fun.gameObject, function()
    self.page:_OnClickBtn(index, funId, part)
  end)
end

function HomeFunItem:_SetModuleClickFun(index, funId, part)
  UGUIEventListener.AddButtonOnClick(part.btn_fun.gameObject, function()
    self.page:_OnClickBtn(index, funId)
  end)
end

function HomeFunItem:_SetModuleFunDisplay(funId, part)
  local funConfig = configManager.GetDataById("config_function_info", tostring(funId))
  UIHelper.SetImage(part.im_icon, funConfig.icon, true)
  local redDotIdList = funConfig.focus
  if redDotIdList and 0 < #redDotIdList then
    self.page:RegisterRedDotById(part.redDot, redDotIdList)
  end
  UIHelper.SetText(part.tx_name, funConfig.name)
  if not moduleManager:CheckFunc(funId, false) then
    part.obj_lock:SetActive(funConfig.icon_Lock == 1)
  else
    part.obj_lock:SetActive(false)
  end
end

return HomeFunItem
