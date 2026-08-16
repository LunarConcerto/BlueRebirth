local m = class("SelectBasePage", LuaUIPage)

function m:SetData(param)
end

function m:DoOnOpen()
  local widgets = self:GetWidgets()
  self.param = self.param or self.TestDisplayData
  self.m_data = self:GetParam()
  self:SetData(self.m_data)
  self:DisplayAll()
end

function m:RegisterAllEvent()
  self:RegisterUIEvent()
end

function m:RegisterUIEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_confirm, self.OnConfirm, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_cancel, self.OnCancel, self)
end

function m:DoOnHide()
end

function m:DoOnClose()
  local widgets = self:GetWidgets()
  self.m_itemArr = {}
  widgets.togGroup_item:ClearToggles()
end

function m.GenDisplayData()
  return nil
end

function m:DisplayAll()
  self:DisplayItemList()
  self:DisplaySelectExtra()
end

function m:DisplayItemList()
  local widgets = self:GetWidgets()
  local itemDisplayArr = self.m_filterAndSortGroup
  UIHelper.SetInfiniteItemParam(widgets.infiniteLayout, widgets.obj_item, #itemDisplayArr, function(partDic)
    local tabTemp = {}
    for k, v in pairs(partDic) do
      tabTemp[tonumber(k)] = v
    end
    for i, part in ipairs(tabTemp) do
      local index = tonumber(i)
      self.m_itemArr[index] = self.m_itemArr[index] or self.itemClass:new()
      local item = self.m_itemArr[index]
      local bSelected = self.m_selectedMap and self.m_selectedMap[itemDisplayArr[index]]
      item:SetData(itemDisplayArr[index], part, index, bSelected)
      item:Display()
      if self.m_maxSelectNum == 1 then
        widgets.togGroup_item:RemoveToggle(part.tgl_item)
        widgets.togGroup_item:RegisterToggle(part.tgl_item)
      end
      UGUIEventListener.AddButtonToggleChanged(part.tgl_item, function(go, isOn)
        if isOn then
          self:Select(index)
          item:OnSelect()
        else
          self:UnSelect(index)
        end
      end)
    end
  end)
end

function m:Select(index)
  if self.m_maxSelectNum == 1 then
    self.m_selectedMap = {
      [self.m_filterAndSortGroup[index]] = true
    }
    return
  end
  if table.nums(self.m_selectedMap) >= self.m_maxSelectNum then
    noticeManager:OpenTipPage(self, "\233\128\137\230\139\169\230\149\176\233\135\143\229\183\178\232\190\190\228\184\138\233\153\144\239\188\140\232\175\183\229\133\136\229\143\150\230\182\136")
  end
end

function m:UnSelect(index)
  self.m_selectedMap[self.m_filterAndSortGroup[index]] = nil
end

function m:GetSelectedArr()
end

function m:OnConfirm()
end

function m:OnCancel()
end

return m
