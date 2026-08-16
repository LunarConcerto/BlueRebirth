local PrivilegePage = class("UI.Recharge.PrivilegePage", LuaUIPage)

function PrivilegePage:DoInit()
  self.m_tabWidgets = nil
end

function PrivilegePage:DoOnOpen()
  self:_LoadContent(self.param)
end

function PrivilegePage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickClose, self)
end

function PrivilegePage:_LoadContent(desTab)
  local descInfos = {}
  for i = 1, #desTab do
    local info = configManager.GetDataById("config_privilegedesc", desTab[i])
    table.insert(descInfos, info)
  end
  table.sort(descInfos, function(data1, data2)
    return data1.id < data2.id
  end)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_desc, self.tab_Widgets.trans_desc, #descInfos, function(index, tabPart)
    UIHelper.SetText(tabPart.text_title, descInfos[index].texttitle)
    UIHelper.SetText(tabPart.text_desc, descInfos[index].desc)
  end)
end

function PrivilegePage:_ClickClose()
  UIHelper.ClosePage("PrivilegePage")
end

return PrivilegePage
