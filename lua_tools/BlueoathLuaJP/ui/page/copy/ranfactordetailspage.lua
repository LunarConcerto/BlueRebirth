local RanFactorDetailsPage = class("UI.Copy.RanFactorDetailsPage", LuaUIPage)

function RanFactorDetailsPage:DoInit()
  self.factors = {}
  self.pictureIndex = 0
  self.pictureTab = {}
  self.uipartTab = {}
end

function RanFactorDetailsPage:DoOnOpen()
  local params = self:GetParam()
  local copyDisplayId = params.copyDisplayId
  local isInBattle = params.isInBattle
  self.tab_Widgets.bgInBattle:SetActive(isInBattle)
  self.tab_Widgets.bgOutBattle:SetActive(not isInBattle)
  local randFactor = Logic.copyLogic:GetRandFactors(copyDisplayId) or {}
  self.factors = self:RemoveDuplicate(randFactor.Factors)
  local idx = 0
  if params.Factors ~= nil and #params.Factors ~= 0 and params.Idx ~= nil and 0 < params.Idx then
    self.factors = self:RemoveDuplicate(params.Factors)
    idx = params.Idx - 1
  end
  local count = #self.factors
  UIHelper.CreateSubPart(self.tab_Widgets.item, self.tab_Widgets.content, count, function(nIndex, tabPart)
    local factor = self.factors[nIndex]
    self.uipartTab[nIndex] = tabPart
    local setRec = configManager.GetDataById("config_random_factor_set", factor.SetId)
    UIHelper.SetImage(tabPart.icon, setRec.set_icon)
    self.tab_Widgets.tgp_yinziToggleGroup:RegisterToggle(tabPart.tog_tubiao)
  end)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgp_yinziToggleGroup, self, nil, self._SwitchToggle)
  self.tab_Widgets.tgp_yinziToggleGroup:SetActiveToggleIndex(idx)
end

function RanFactorDetailsPage:_SwitchToggle(index)
  if #self.factors <= 0 then
    return
  end
  for i, uipart in pairs(self.uipartTab) do
    self.uipartTab[i].selectIcon.gameObject:SetActive(i == index + 1)
  end
  local factor = self.factors[index + 1]
  local setRec = configManager.GetDataById("config_random_factor_set", factor.SetId)
  UIHelper.SetText(self.tab_Widgets.txt_name, setRec.set_name)
  local desc = ""
  local fcount = #factor.Factors
  self.pictureTab = {}
  for i, fid in ipairs(factor.Factors) do
    local factorRec = configManager.GetDataById("config_random_factor", fid)
    desc = desc .. factorRec.factor_description
    for _, v in ipairs(factorRec.factor_image) do
      table.insert(self.pictureTab, v)
    end
  end
  UIHelper.SetText(self.tab_Widgets.txt_desText, desc)
  self.pictureIndex = 1
  self.tab_Widgets.btn_leftBtn.gameObject:SetActive(#self.pictureTab > 2)
  self.tab_Widgets.btn_rightBtn.gameObject:SetActive(#self.pictureTab > 2)
  self.tab_Widgets.gray_leftBtn.Gray = 1 < #self.pictureTab and 1 < self.pictureIndex
  self.tab_Widgets.gray_rightBtn.Gray = 1 < #self.pictureTab and self.pictureIndex < #self.pictureTab
  if 0 >= #self.pictureTab then
    logError("\233\133\141\231\189\174\232\161\168\228\184\173\230\156\170\233\133\141\231\189\174\231\170\129\229\143\152\229\155\160\229\173\144\229\155\190\231\137\135,setid\228\184\186", factor.SetId)
    return
  end
  self:_RefreshPicture()
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

function RanFactorDetailsPage:_ClickNext()
  self.pictureIndex = self.pictureIndex + 1
  if self.pictureIndex > #self.pictureTab then
    self.pictureIndex = #self.pictureTab
  end
  self.tab_Widgets.gray_leftBtn.Gray = 1 < #self.pictureTab and self.pictureIndex > 1
  self.tab_Widgets.gray_rightBtn.Gray = 1 < #self.pictureTab and self.pictureIndex < #self.pictureTab
  self:_RefreshPicture()
end

function RanFactorDetailsPage:_ClickLast()
  self.pictureIndex = self.pictureIndex - 1
  if self.pictureIndex < 1 then
    self.pictureIndex = 1
  end
  self.tab_Widgets.gray_leftBtn.Gray = 1 < #self.pictureTab and self.pictureIndex > 1
  self.tab_Widgets.gray_rightBtn.Gray = 1 < #self.pictureTab and self.pictureIndex < #self.pictureTab
  self:_RefreshPicture()
end

function RanFactorDetailsPage:_RefreshPicture()
  if #self.pictureTab <= 0 then
    return
  end
  local picture = self.pictureTab[self.pictureIndex]
  UIHelper.SetImage(self.tab_Widgets.img_desImage, picture)
end

function RanFactorDetailsPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnClose, self._Close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.bg_mask, self._Close, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_leftBtn.gameObject, self._ClickLast, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_rightBtn.gameObject, self._ClickNext, self)
end

function RanFactorDetailsPage:_Close()
  UIHelper.ClosePage(self:GetName())
end

function RanFactorDetailsPage:DoOnHide()
end

function RanFactorDetailsPage:DoOnClose()
end

return RanFactorDetailsPage
