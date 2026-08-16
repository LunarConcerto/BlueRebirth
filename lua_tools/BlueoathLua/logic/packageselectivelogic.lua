local PackageSelectiveLogic = class("logic.PackageSelectiveLogic")

function PackageSelectiveLogic:initialize()
  self:ResetData()
end

function PackageSelectiveLogic:ResetData()
  self.SelectedPackage = {}
end

function PackageSelectiveLogic:SetSelectPackage(packageInfo)
  self.SelectedPackage[packageInfo.id] = packageInfo.reward
end

function PackageSelectiveLogic:GetSelectPackage()
  local packageInfo = {}
  for _, v in ipairs(self.SelectedPackage) do
    table.insert(packageInfo, v)
  end
  return packageInfo
end

function PackageSelectiveLogic:GetSelectPackageById(packageId)
  local info = self.SelectedPackage[packageId] and self.SelectedPackage[packageId] or {}
  return info
end

function PackageSelectiveLogic:GetCanSelectInfo(id)
  local packageInfo = configManager.GetDataById("config_recharge_selective", id)
  local canSelectInfo = {}
  for i = 1, 4 do
    if #packageInfo["selective_reward_" .. i] > 0 then
      table.insert(canSelectInfo, packageInfo["selective_reward_" .. i])
    end
  end
  return canSelectInfo
end

return PackageSelectiveLogic
