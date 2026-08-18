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

function PackageSelectiveLogic:CheckFreeGift(actId)
  local isOpen = Logic.activityLogic:CheckActivityOpenById(actId)
  if not isOpen then
    return false
  end
  local packageIdTab = configManager.GetDataById("config_activity", actId).p1
  local serSelectiveInfo = {}
  local serData = Data.rechargeData:GetSelectiveInfo()
  for _, v in pairs(serData) do
    serSelectiveInfo[v.RechargeId] = v.BuyTimes
  end
  for i, packageId in ipairs(packageIdTab) do
    local packageInfo = configManager.GetDataById("config_recharge_selective", packageId)
    local buyTimes = serSelectiveInfo[packageId] and serSelectiveInfo[packageId] or 0
    local repertory = packageInfo.limit - buyTimes
    if packageInfo.limit ~= -1 and 0 < repertory and packageInfo.refresh_id ~= 0 then
      return true
    end
  end
  return false
end

return PackageSelectiveLogic
