local AffectionAddPage = class("UI.Building.AffectionAddPage", LuaUIPage)

function AffectionAddPage:DoOnOpen()
  local param = self:GetParam()
  local addAffection = param.affection
  local heroId = param.heroId
  local plotId = param.plotId
  local heroInfo = Data.heroData:GetHeroById(heroId)
  local showInfo = Logic.shipLogic:GetShipShowByHeroId(heroInfo.HeroId)
  local noMarry = configManager.GetDataById("config_parameter", 155).arrValue
  local marryed = configManager.GetDataById("config_parameter", 156).arrValue
  local maxAffection = heroInfo.MarryTime == 0 and noMarry[2] or marryed[2]
  local _, curAffection = Logic.marryLogic:GetLoveInfo(heroId, MarryType.Love)
  local widgets = self:GetWidgets()
  local oldAffection = curAffection - addAffection
  local from = oldAffection / maxAffection
  local to = curAffection / maxAffection
  widgets.slider.value = from
  local shipPos = configManager.GetDataById("config_ship_position", showInfo.ss_id)
  local position = shipPos.character_story_position
  widgets.trans_hero.anchoredPosition = Vector2.New(position[1], position[2])
  local scale = shipPos.character_story_scale / 10000
  local mirror = shipPos.character_story_inversion
  widgets.trans_hero.localScale = Vector3.New(mirror == 0 and scale or -scale, scale, 1)
  UIHelper.SetImage(widgets.img_hero, showInfo.ship_draw)
  UIHelper.SetText(widgets.txt_affection, string.format("+%d", math.floor(addAffection / 10000)))
  UIHelper.SetText(widgets.txt_affection_bg, string.format("+%d", math.floor(addAffection / 10000)))
  UIHelper.SetText(widgets.txt_progress, string.format("%d/%d", math.floor(oldAffection / 10000), math.floor(maxAffection / 10000)))
  self.maxAffection = maxAffection
  self:PerformDelay(0.6, function()
    self:PlaySliderAnim(from, to)
    self:PlayNumAnim(oldAffection / 10000, curAffection / 10000)
  end)
end

function AffectionAddPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self.OnBtnClose, self)
end

function AffectionAddPage:DelayClose()
  self:PerformDelay(2, function()
    self:CloseSelf()
  end)
end

function AffectionAddPage:PlaySliderAnim(from, to)
  local widgets = self:GetWidgets()
  Logic.buildingLogic:StartSliderAnim(from, to, function(curValue)
    if widgets.slider ~= nil and not IsNil(widgets.slider) then
      widgets.slider.value = curValue
    end
  end)
end

function AffectionAddPage:PlayNumAnim(from, to)
  local widgets = self:GetWidgets()
  Logic.buildingLogic:StartSliderAnim(from, to, function(curValue)
    if widgets.txt_progress ~= nil and not IsNil(widgets.txt_progress) then
      curValue = math.floor(curValue)
      UIHelper.SetText(widgets.txt_progress, string.format("%d/%d", curValue, self.maxAffection / 10000))
    end
  end)
end

function AffectionAddPage:OnBtnClose()
  self:CloseSelf()
end

function AffectionAddPage:DoOnClose()
  Logic.buildingLogic:StopSliderAnim()
end

return AffectionAddPage
