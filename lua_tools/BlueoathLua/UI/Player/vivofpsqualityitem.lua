local QualityItem = class("UI.Player.vivoFpsQualityItem")

function QualityItem:SetData(data, part)
  self.data = data
  self.part = part
  self:Display()
end

function QualityItem:Display()
  local data = self.data
  local part = self.part
  part.txt_title.text = data.name
  self:_SetToggle(data.curLv, data.count)
end

function QualityItem:_SetToggle(curLv, count)
  local data = self.data
  local part = self.part
  local lv2index = {}
  setmetatable(lv2index, {
    __index = function(t, k)
      return rawget(t, k) or 1
    end
  })
  for k, v in pairs(data.select) do
    lv2index[v] = k
  end
  part.tog_open.gameObject:SetActive(count == 1)
  part.tog_low.gameObject:SetActive(2 <= count)
  part.tog_middle.gameObject:SetActive(3 <= count)
  part.tog_high.gameObject:SetActive(2 <= count)
  if part.tog_superhigh then
    part.tog_superhigh.gameObject:SetActive(count == 4)
  end
  if count == 1 then
    part.txt_name.text = self.data.name
    part.tog_open.isOn = lv2index[curLv] ~= 1
    if part.tog_open.isOn then
      part.togp_open:SetActive(true)
      part.togp_noopen:SetActive(false)
    else
      part.togp_open:SetActive(false)
      part.togp_noopen:SetActive(true)
    end
    UGUIEventListener.AddButtonToggleChanged(part.tog_open, self._OnToggleChange, self)
  end
  if count == 2 then
    part.togp_quality:ClearToggles()
    part.togp_quality:RegisterToggle(part.tog_low)
    part.togp_quality:RegisterToggle(part.tog_high)
    part.togp_quality:SetActiveToggleIndex(lv2index[curLv] - 1)
    UIHelper.AddToggleGroupChangeValueEvent(part.togp_quality, self, nil, self._OnToggleGroupChange)
  end
  if count == 3 then
    part.togp_quality:ClearToggles()
    part.togp_quality:RegisterToggle(part.tog_low)
    part.togp_quality:RegisterToggle(part.tog_middle)
    part.togp_quality:RegisterToggle(part.tog_high)
    part.togp_quality:SetActiveToggleIndex(lv2index[curLv] - 1)
    UIHelper.AddToggleGroupChangeValueEvent(part.togp_quality, self, setFunc, self._OnToggleGroupChange)
  end
  if count == 4 then
    part.togp_quality:ClearToggles()
    part.togp_quality:RegisterToggle(part.tog_low)
    part.togp_quality:RegisterToggle(part.tog_middle)
    part.togp_quality:RegisterToggle(part.tog_high)
    part.togp_quality:RegisterToggle(part.tog_superhigh)
    part.togp_quality:SetActiveToggleIndex(lv2index[curLv] - 1)
    UIHelper.AddToggleGroupChangeValueEvent(part.togp_quality, self, setFunc, self._OnToggleGroupChange)
  end
  if data.lowName then
    part.txt_low.text = data.lowName
    part.txt_low_choose.text = data.lowName
  end
  if data.highName then
    part.txt_high.text = data.highName
    part.txt_high_choose.text = data.highName
  end
end

function QualityItem:_OnToggleGroupChange(index)
  local data = self.data
  data.curLv = data.select[index + 1]
  GR.qualityManager:setQualityLvByType(data.curLv, data.type)
  self.timer = Timer.New(function()
    eventManager:SendEvent(LuaEvent.vivoFpsSetting, data.curLv)
    self.timer:Stop()
  end, 0.01, 1)
  self.timer:Start()
end

function QualityItem:_OnToggleChange(go, enabled)
  if self.part.tog_open.isOn then
    self.part.togp_open:SetActive(true)
    self.part.togp_noopen:SetActive(false)
  else
    self.part.togp_open:SetActive(false)
    self.part.togp_noopen:SetActive(true)
  end
  local data = self.data
  local index = enabled and 1 or 0
  data.curLv = data.select[index + 1]
  GR.qualityManager:setQualityLvByType(data.curLv, data.type)
  self.timer = Timer.New(function()
    eventManager:SendEvent(LuaEvent.vivoFpsSetting, data.curLv)
    self.timer:Stop()
  end, 0.01, 1)
  self.timer:Start()
end

return QualityItem
