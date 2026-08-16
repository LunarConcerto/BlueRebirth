local ModuleLogic = class("logic.ModuleLogic")

function ModuleLogic:initialize()
  self:ResetData()
end

function ModuleLogic:ResetData()
  self.loginOk = false
  self.tabNoOpenModule = {}
  self.newOpenModule = nil
  self.openPageOpenModule = nil
end

function ModuleLogic:SetCheckFlg(data)
  self.loginOk = data
end

function ModuleLogic:GetCheckFlg()
  return self.loginOk
end

function ModuleLogic:SetNoOpenModule(data)
  self.tabNoOpenModule = data
end

function ModuleLogic:GetNoOpenModule()
  return self.tabNoOpenModule
end

function ModuleLogic:SetNewOpenModule(data)
  self.newOpenModule = data
end

function ModuleLogic:GetNewOpenModule()
  return self.newOpenModule
end

function ModuleLogic:SetOpenPageOpenModule(data)
  self.openPageOpenModule = data
end

function ModuleLogic:GetOpenPageOpenModule()
  return self.openPageOpenModule
end

return ModuleLogic
