local PictureHeroItem = class("UI.Picture.PictureHeroItem")

function PictureHeroItem:initialize(...)
  self.page = nil
  self.tabPart = nil
  self.heroInfo = {}
  self.index = nil
  self.tabHero = {}
  self.tabHeroId = {}
  self.type = nil
end

function PictureHeroItem:Init(tabPart, data, index, tabHeroId, type)
  self.tabPart = tabPart
  self.heroInfo = data
  self.index = index
  self.tabHeroId = tabHeroId
  self.type = type
  self:_SetHeroInfo()
end

function PictureHeroItem:_SetHeroInfo()
  local luaPart = self.tabPart.cardPart:GetLuaTableParts()
  UIHelper.SetText(luaPart.tx_name, self.heroInfo.Name)
  UIHelper.SetImage(luaPart.bg_quality, VerCardQualityImg[self.heroInfo.quality])
  local tabHeroIcon = Logic.illustrateLogic:GetIllustratePicture(self.heroInfo.IllustrateId)
  local drawBlackIcon = Logic.shipLogic:GetIcon2Black(self.heroInfo.IllustrateId)
  local tabHero = Logic.shipLogic:GetPictureData(self.heroInfo.IllustrateId)
  local canCombine = configManager.GetDataById("config_ship_fleet", tabHero.sf_id).combination_open == 1
  luaPart.obj_combine:SetActive(canCombine)
  if self.heroInfo.IllustrateState == IllustrateState.UNLOCK then
    UIHelper.SetImage(luaPart.im_girl, tabHeroIcon)
  elseif self.heroInfo.IllustrateState == IllustrateState.LOCK then
    UIHelper.SetImage(luaPart.im_girl, drawBlackIcon)
  elseif self.heroInfo.IllustrateState == IllustrateState.CLOSE then
    UIHelper.SetImage(luaPart.im_girl, drawBlackIcon)
  end
  UIHelper.SetImage(luaPart.im_type, NewCardShipTypeImg[tabHero.ship_type])
  UGUIEventListener.AddButtonOnClick(self.tabPart.btnDrag, function()
    self:_ShowGirlInfo(self, self.heroInfo)
  end)
end

function PictureHeroItem:_ShowGirlInfo(go, param)
  self.tabPart.img_new:SetActive(param.NewHero)
  if param.IllustrateState ~= IllustrateState.CLOSE then
    UIHelper.OpenPage("IllustrateInfo", {
      id = param.IllustrateId,
      tabHeroId = self.tabHeroId,
      Type = self.type
    })
    local new = Logic.illustrateLogic:IsNewIllustrate(param.IllustrateId)
    if new then
      Service.illustrateService:SendIllustrateNew({
        param.IllustrateId
      })
    end
  end
end

return PictureHeroItem
