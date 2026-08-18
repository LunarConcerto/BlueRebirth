local DropPath = class("UI.Common.DropPath")

function DropPath:_DisplayDrop(widgets, drop_path, page, itemData)
  self.page = page
  if drop_path == nil then
    widgets.drop:SetActive(false)
    return
  end
  drop_path = self:handleDropPath(drop_path)
  if #drop_path <= 0 then
    widgets.drop:SetActive(true)
    widgets.objDrop:SetActive(true)
    widgets.objUnOpen:SetActive(false)
    return
  end
  widgets.drop:SetActive(0 < #drop_path)
  UIHelper.CreateSubPart(widgets.objDrop, widgets.contentDrop, #drop_path, function(index, part)
    local accessId = drop_path[index]
    local config = configManager.GetDataById("config_access", accessId)
    local dropInfo = config.drop_path
    local functionId = dropInfo[1]
    part.textName.gameObject:SetActive(true)
    part.textCopyId.gameObject:SetActive(false)
    part.textCopyName.gameObject:SetActive(false)
    if functionId == FunctionID.Shop then
      self:_DisplayDropShop(config, part)
    elseif functionId == FunctionID.SeaCopy then
      self:_DisplayDropSeaCopy(config, part)
    elseif functionId == FunctionID.ActSeaCopy then
      self:_DisplayDropActSeaCopy(config, part)
    elseif functionId == FunctionID.BuildShip then
      self:_DisplayDropBuildShip(config, part)
    elseif functionId == FunctionID.DailyCopy then
      self:_DisplayDropDailyCopy(config, part)
    elseif functionId == FunctionID.BuildShipGirl then
      self:_DisplayDropFunc(config, part)
    elseif functionId == FunctionID.Activity or functionId == FunctionID.VocationActivity then
      self:_DisplayDropActivityFunc(config, part)
    elseif functionId == FunctionID.Recharge then
      self:_DisplayDropRechargeFunc(config, part)
    elseif functionId == FunctionID.MubarOutpost then
      self:_DisplayDropMubarOutpostFunc(config, part)
    elseif functionId == FunctionID.Alchemy then
      self:_DisplayDropAlchemyFunc(config, part, itemData)
    elseif functionId == FunctionID.PVECopyPage then
      self:_DisplayDropPVERoomCopy(config, part)
    elseif functionId == FunctionID.ActFoodCompose then
      self:_DisplayDropFoodComposeFunc(config, part)
    else
      self:_DisplayDropFunc(config, part)
    end
  end)
end

function DropPath:handleDropPath(drop_path)
  local result = {}
  for index, accessId in ipairs(drop_path) do
    local config = configManager.GetDataById("config_access", accessId)
    if self:_IsAccessOpen(config) then
      table.insert(result, accessId)
    end
  end
  return result
end

function DropPath:_DisplayDropShop(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local shopId = dropInfo[2]
  local shopConfig = configManager.GetDataById("config_shop", shopId)
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local isShopOpen = Logic.shopLogic:IsOpenByShopId(shopId, false)
  local activityId = shopConfig.activity_id
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen and isShopOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen or not isShopOpen)
  part.imgArrow.gameObject:SetActive(isOpen and isShopOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen and isShopOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    if moduleManager:CheckFunc(functionId, true) and Logic.shopLogic:IsOpenByShopId(shopId, true) then
      local itemParam = self.page:GetParam()
      UIHelper.ClosePage(self.page:GetName())
      local itemId
      if itemParam.type == GoodsType.ITEM then
        local itemConfig = configManager.GetDataById("config_item_info", itemParam.id)
        itemId = itemConfig.show_in_shop == 1 and itemParam.id or nil
      end
      UIHelper.OpenPage("ShopPage", {shopId = shopId, showItemId = itemId})
    end
  end)
end

function DropPath:_DisplayDropSeaCopy(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local copyId = dropInfo[3] or 0
  local isFirstPass = dropInfo[4]
  local funcConfig = configManager.GetDataById("config_function_info", tostring(functionId))
  local chapterName = funcConfig.name
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  if 0 < copyId then
    local isCopyOpen = Logic.copyLogic:IsCopyOpenById(copyId)
    isOpen = isOpen and isCopyOpen
    local copyDisplayConfig = configManager.GetDataById("config_copy_display", copyId)
    if not copyDisplayConfig then
      logError("config_copy_display can't find copyid:", copyId)
    end
    local str = chapterName .. copyDisplayConfig.str_index .. " " .. copyDisplayConfig.name
    if isFirstPass == 1 then
      str = UIHelper.GetString(130008) .. str
    end
  else
  end
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen)
  part.imgArrow.gameObject:SetActive(isOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    if moduleManager:CheckFunc(functionId, true) then
      UIHelper.ClosePage(self.page:GetName())
      if 0 < copyId then
        self:_OpenLevelDetailsPage(copyId)
      else
        UIHelper.OpenPage("CopyPage", {
          selectCopy = Logic.copyLogic.SelectCopyType.SeaCopy
        })
      end
    end
  end)
end

function DropPath:_DisplayDropActSeaCopy(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local activityId = dropInfo[2]
  local copyId = dropInfo[3] or 0
  local activityConfig = configManager.GetDataById("config_activity", activityId)
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local isActivityOpen = Logic.activityLogic:CheckActivityOpenById(activityId)
  local isCopyOpen = true
  if 0 < copyId then
    isCopyOpen = Logic.copyLogic:IsCopyOpenById(copyId)
  else
    local seaCopyType = activityConfig.seacopy_type
    isCopyOpen = Logic.copyChapterLogic:IsOpenByChapterType(seaCopyType)
  end
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen and isActivityOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen or not isActivityOpen or not isCopyOpen)
  part.imgArrow.gameObject:SetActive(isOpen and isActivityOpen and isCopyOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen and isActivityOpen and isCopyOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    if not moduleManager:CheckFunc(FunctionID.ActPlotCopy, true) then
      return
    end
    if not moduleManager:CheckFunc(FunctionID.ActSeaCopy, true) then
      return
    end
    UIHelper.ClosePage(self.page:GetName())
    if 0 < copyId then
      self:_OpenLevelDetailsPage(copyId)
    else
      UIHelper.OpenPage("ActivityCopyPage", {index = 1})
    end
  end)
end

function DropPath:_DisplayDropBuildShip(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local extractShipId = dropInfo[2]
  local extractShipConfig = configManager.GetDataById("config_extract_ship", extractShipId)
  local activityId = extractShipConfig.activity_id
  if activityId and 0 < activityId then
    local isActivityOpen = Logic.activityLogic:CheckActivityOpenById(activityId)
    UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen and isActivityOpen)
    part.textUnOpen.gameObject:SetActive(not isOpen or not isActivityOpen)
    part.imgArrow.gameObject:SetActive(isOpen and isActivityOpen)
    part.imgOpenBG.gameObject:SetActive(isOpen and isActivityOpen)
    UGUIEventListener.AddButtonOnClick(part.btn, function()
      if not isActivityOpen then
        noticeManager:ShowTipById(270022)
        return
      end
      UIHelper.ClosePage(self.page:GetName())
      moduleManager:JumpToFunc(functionId)
    end)
  else
    self:_DisplayDropFunc(config, part)
  end
end

function DropPath:_DisplayDropDailyCopy(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local dailyGroupId = dropInfo[2]
  if dailyGroupId then
    local dailyGroupInfo = configManager.GetDataById("config_daily_group", dailyGroupId)
    local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
    UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
    part.textUnOpen.gameObject:SetActive(not isOpen)
    part.imgArrow.gameObject:SetActive(isOpen)
    part.imgOpenBG.gameObject:SetActive(isOpen)
    UGUIEventListener.AddButtonOnClick(part.btn, function()
      if moduleManager:CheckFunc(functionId, true) then
        UIHelper.ClosePage(self.page:GetName())
        if not Logic.dailyCopyLogic:CheckDailyCopyPeriod(dailyGroupInfo, true) then
          return
        end
        UIHelper.OpenPage("DailyCopyDetailPage", {dailyGroupId = dailyGroupId})
      end
    end)
  else
    local isOpen = moduleManager:CheckFunc(functionId, false)
    UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
    part.textUnOpen.gameObject:SetActive(not isOpen)
    part.imgArrow.gameObject:SetActive(isOpen)
    part.imgOpenBG.gameObject:SetActive(isOpen)
    UGUIEventListener.AddButtonOnClick(part.btn, function()
      if moduleManager:CheckFunc(functionId, true) then
        UIHelper.ClosePage(self.page:GetName())
        UIHelper.OpenPage("CopyPage", {
          selectCopy = Logic.copyLogic.SelectCopyType.DailyCopy
        })
      end
    end)
  end
end

function DropPath:_DisplayDropActivityFunc(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local activityId = dropInfo[2]
  local custom = dropInfo[3]
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  isOpen = isOpen and Logic.activityLogic:CheckActivityOpenById(activityId)
  local funcConfig = configManager.GetDataById("config_function_info", tostring(functionId))
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen)
  part.imgArrow.gameObject:SetActive(isOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    UIHelper.ClosePage(self.page:GetName())
    moduleManager:JumpToFunc(functionId, activityId, custom)
  end)
end

function DropPath:_DisplayDropRechargeFunc(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local rechargeId = dropInfo[2]
  local shopId = dropInfo[3]
  local isAvailable, isSoldOut = Logic.rechargeLogic:CheckRechargeStatus(rechargeId)
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local tips = self:GetRechargeTips(isOpen, isSoldOut, isAvailable)
  local flag = isOpen and not isSoldOut and isAvailable
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, flag)
  UIHelper.SetLocText(part.textUnOpen, tips)
  part.textUnOpen.gameObject:SetActive(not flag)
  part.imgArrow.gameObject:SetActive(flag)
  part.imgOpenBG.gameObject:SetActive(flag)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    if not flag then
      noticeManager:ShowTipById(tips)
      return
    end
    UIHelper.ClosePage(self.page:GetName())
    moduleManager:JumpToFunc(functionId, {shopId = shopId, rechargeId = rechargeId})
  end)
end

function DropPath:GetRechargeTips(isOpen, isSoldOut, isAvailable)
  if not isOpen then
    return 132000
  elseif isSoldOut then
    return 132001
  elseif not isAvailable then
    return 132002
  else
    return 132000
  end
end

function DropPath:_DisplayDropFunc(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local funcConfig = configManager.GetDataById("config_function_info", tostring(functionId))
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen)
  part.imgArrow.gameObject:SetActive(isOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    UIHelper.ClosePage(self.page:GetName())
    moduleManager:JumpToFunc(functionId)
  end)
end

function DropPath:_OpenLevelDetailsPage(copyId)
  local chapterId = Logic.copyLogic:GetChapterIdByCopyId(copyId)
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  local param = {
    copyType = CopyType.COMMONCOPY,
    tabSerData = copyData,
    chapterId = chapterId,
    IsRunningFight = copyData.IsRunningFight == true,
    copyId = copyId
  }
  if Logic.copyLogic:IsAssistFleet(copyId) then
    UIHelper.OpenPage("FleetPage", {
      subType = 2,
      copyId = param.copyId,
      chapterId = param.chapterId
    })
  else
    local isHasFleet = Logic.fleetLogic:IsHasFleet()
    if not isHasFleet then
      noticeManager:OpenTipPage(self, 110007)
      return
    end
    UIHelper.OpenPage("LevelDetailsPage", param)
  end
end

function DropPath:_IsAccessOpen(config)
  return self:_IsOpenPeriod(config) and self:_IsOpenTime(config)
end

function DropPath:_IsOpen(config)
  return true
end

function DropPath:_IsOpenPeriod(config)
  local periodIds = config.period_id
  if #periodIds <= 0 then
    return true
  end
  return PeriodManager:IsInPeriods(periodIds)
end

function DropPath:_IsOpenTime(config)
  return time.getSvrTime() >= config.activatetime
end

function DropPath:_DisplayDropMubarOutpostFunc(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local chapterId = dropInfo[2]
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local funcConfig = configManager.GetDataById("config_function_info", tostring(functionId))
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen)
  part.imgArrow.gameObject:SetActive(isOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen)
  local chapterInfo = Logic.copyLogic:GetChaperConfById(chapterId)
  local openParam = {chapterInfo = chapterInfo}
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    UIHelper.ClosePage(self.page:GetName())
    moduleManager:JumpToFunc(functionId, openParam)
  end)
end

function DropPath:_DisplayDropAlchemyFunc(config, part, itemData)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local funcConfig = configManager.GetDataById("config_function_info", tostring(functionId))
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen)
  part.imgArrow.gameObject:SetActive(isOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    UIHelper.ClosePage(self.page:GetName())
    moduleManager:JumpToFunc(functionId, itemData.ryzaFormulaId)
  end)
end

function DropPath:_DisplayDropPVERoomCopy(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local funcConfig = configManager.GetDataById("config_function_info", tostring(functionId))
  local chapterName = funcConfig.name
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen)
  part.imgArrow.gameObject:SetActive(isOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    if moduleManager:CheckFunc(functionId, true) then
      UIHelper.ClosePage(self.page:GetName())
      local uid = Data.userData:GetUserUid()
      PlayerPrefs.SetInt(uid .. "NewCopyButtomIndex", 4)
      UIHelper.OpenPage("CopyPage")
    end
  end)
end

function DropPath:_DisplayDropFoodComposeFunc(config, part)
  local dropInfo = config.drop_path
  local functionId = dropInfo[1]
  local isOpen = moduleManager:CheckFunc(functionId, false) and self:_IsOpen(config)
  local funcConfig = configManager.GetDataById("config_function_info", tostring(functionId))
  UIHelper.SetTextColorByBool(part.textName, config.name, COLOR.DropOpen, COLOR.DropLock, isOpen)
  part.textUnOpen.gameObject:SetActive(not isOpen)
  part.imgArrow.gameObject:SetActive(isOpen)
  part.imgOpenBG.gameObject:SetActive(isOpen)
  UGUIEventListener.AddButtonOnClick(part.btn, function()
    UIHelper.ClosePage(self.page:GetName())
    moduleManager:JumpToFunc(functionId)
  end)
end

return DropPath
