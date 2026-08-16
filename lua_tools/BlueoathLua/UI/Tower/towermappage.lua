local TowerMapPage = class("UI.Tower.TowerMapPage", LuaUIPage)

function TowerMapPage:DoInit()
  self.tablePart = {}
end

function TowerMapPage:DoOnOpen()
  local themeConfig = self.param.themeConfig
  self.themeConfig = themeConfig
  self.page = self.param.page
  local copyMap = Logic.copyLogic:TowerGetCopyMapByTheme(themeConfig)
  local widgets = self:GetWidgets()
  self:ShowPath()
  self:ShowArrow()
  for copyId, v in pairs(copyMap) do
    UIHelper.CreateSubPart(widgets.im_point, widgets[tostring(copyId)], 1, function(index, tablePart)
      self:ShowPoint(copyId, tablePart)
      self.tablePart[copyId] = tablePart
    end)
  end
end

function TowerMapPage:ShowPath()
  local widgets = self:GetWidgets()
  local copyMapAttack = Logic.towerLogic:GetCopyAttack()
  local pathMapPart = widgets.line:GetLuaTableParts()
  local pathListSrc = Data.towerData:GetCopyList()
  local pathMap = {}
  if 0 < #pathListSrc then
    for i = 1, #pathListSrc do
      if i < #pathListSrc then
        local src = pathListSrc[i]
        local dst = pathListSrc[i + 1]
        self:setPathMap(pathMap, pathMapPart, src, dst)
      end
    end
  end
  for name, go in pairs(pathMapPart) do
    if name ~= "gameObject" then
      go:SetActive(pathMap[name] == true)
    end
  end
end

function TowerMapPage:ShowArrow()
  local widgets = self:GetWidgets()
  local pathListSrc = Data.towerData:GetCopyList()
  local arrowMapPart = widgets.arrow:GetLuaTableParts()
  local copyMapAttack = Logic.towerLogic:GetCopyAttack()
  local arrowMap = {}
  local src
  if 0 < #pathListSrc then
    src = pathListSrc[#pathListSrc]
  else
    src = 0
  end
  for dst, _ in pairs(copyMapAttack) do
    local arrow = src .. "_" .. dst
    arrowMap[arrow] = true
  end
  for name, go in pairs(arrowMapPart) do
    if name ~= "gameObject" then
      go:SetActive(arrowMap[name] == true)
    end
  end
end

function TowerMapPage:ShowPoint(copyId, tablePart)
  local state = Logic.towerLogic:GetCopyState(copyId)
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  local isClear = state == TowerCopyState.Clear
  tablePart.im_buff_clear:SetActive(isClear and isBuff)
  tablePart.im_buff_lock:SetActive(not isClear and isBuff)
  tablePart.im_clear:SetActive(isClear and not isBuff)
  tablePart.im_lock:SetActive(not isClear and not isBuff)
  if not isBuff then
    UIHelper.SetText(tablePart.text_clear, copyConfig.copy_index)
    UIHelper.SetText(tablePart.text_lock, copyConfig.copy_index)
  end
  UGUIEventListener.AddButtonOnClick(tablePart.btn, function()
    local state = Logic.towerLogic:GetCopyState(copyId)
    if state == TowerCopyState.Attack then
      local isNotDeadRoad = Logic.towerLogic:IsNotDeadRoad()
      local result = Logic.towerLogic:CheckAvailable(copyId)
      if isNotDeadRoad and not result then
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              Logic.towerLogic:CopyClick(copyId)
            end
          end
        }
        local tips = string.format(UIHelper.GetString(1703006), str)
        noticeManager:ShowMsgBox(tips, tabParams)
      else
        Logic.towerLogic:CopyClick(copyId)
      end
    elseif state == TowerCopyState.Lock then
      Logic.towerLogic:CopyClick(copyId)
    elseif state == TowerCopyState.Clear then
      noticeManager:ShowTipById(1703010)
    end
  end)
end

function TowerMapPage:_refresh()
  self:ShowPath()
  self:ShowArrow()
  for copyId, tablePart in pairs(self.tablePart) do
    self:ShowPoint(copyId, tablePart)
  end
end

function TowerMapPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
  self:RegisterEvent(LuaEvent.UpdateTowerInfo, self._refresh, self)
  self:RegisterEvent(LuaEvent.TowerReceiveBuff, self._refresh, self)
end

function TowerMapPage:btn_close()
  self.page:CloseSubPage(self.themeConfig.tower_map)
end

function TowerMapPage:setPathMap(pathMap, pathMapPart, src, dst)
  local line = src .. "_" .. dst .. "_l"
  local line_revert = dst .. "_" .. src .. "_l"
  pathMap[line] = true
  pathMap[line_revert] = true
end

return TowerMapPage
