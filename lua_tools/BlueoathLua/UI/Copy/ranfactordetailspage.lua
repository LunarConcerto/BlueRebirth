local RanFactorDetailsPage = class("UI.Copy.RanFactorDetailsPage", LuaUIPage)

function RanFactorDetailsPage:DoInit()
end

function RanFactorDetailsPage:DoOnOpen()
  local params = self:GetParam()
  local copyDisplayId = params.copyDisplayId
  local isInBattle = params.isInBattle
  self.tab_Widgets.bgInBattle:SetActive(isInBattle)
  self.tab_Widgets.bgOutBattle:SetActive(not isInBattle)
  local randFactor = Logic.copyLogic:GetRandFactors(copyDisplayId) or {}
  local factors = self:RemoveDuplicate(randFactor.Factors)
  local count = #factors
  UIHelper.CreateSubPart(self.tab_Widgets.item, self.tab_Widgets.content, count, function(nIndex, tabPart)
    local factor = factors[nIndex]
    local setRec = configManager.GetDataById("config_random_factor_set", factor.SetId)
    UIHelper.SetImage(tabPart.icon, setRec.set_icon)
    UIHelper.SetText(tabPart.name, setRec.set_name)
    local desc = ""
    local fcount = #factor.Factors
    for i, fid in ipairs(factor.Factors) do
      local factorRec = configManager.GetDataById("config_random_factor", fid)
      desc = desc .. factorRec.factor_description
    end
    UIHelper.SetText(tabPart.desc, desc)
  end)
end

function RanFactorDetailsPage:RemoveDuplicate(factors)
  if factors == nil then
    return {}
  end
  local ret = {}
  local exist = {}
  for i, f in ipairs(factors) do
    local key = f.SetId .. "" .. f.GroupId
    if not exist[key] then
      table.insert(ret, f)
      exist[key] = true
    end
  end
  return ret
end

function RanFactorDetailsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnOk, self._Close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self._Close, self)
end

function RanFactorDetailsPage:_Close()
  UIHelper.ClosePage(self:GetName())
end

function RanFactorDetailsPage:DoOnHide()
end

function RanFactorDetailsPage:DoOnClose()
end

return RanFactorDetailsPage
