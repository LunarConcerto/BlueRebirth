local ATowerCopyDetailsPage = class("UI.TowerActivity.ATowerCopyDetailsPage", LuaUIPage)

function ATowerCopyDetailsPage:DoInit()
end

function ATowerCopyDetailsPage:DoOnOpen()
  local widgets = self:GetWidgets()
  local copyList = Data.towerActivityData:GetAllCopyList()
  table.remove(copyList, 1)
  UIHelper.CreateSubPart(widgets.txt_record, widgets.content, #copyList, function(index, tabPart)
    local copyId = copyList[index]
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
    if isBuff then
      UIHelper.SetLocText(tabPart.txt_record, 2900005, index, copyConfig.name)
    else
      UIHelper.SetLocText(tabPart.txt_record, 2900004, index, copyConfig.copy_index .. " " .. copyConfig.name)
    end
  end)
end

function ATowerCopyDetailsPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self.btn_close, self)
end

function ATowerCopyDetailsPage:btn_close()
  UIHelper.ClosePage("ATowerCopyDetailsPage")
end

return ATowerCopyDetailsPage
