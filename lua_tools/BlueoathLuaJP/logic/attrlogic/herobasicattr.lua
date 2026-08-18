local HeroBasicAttr = class("logic.AttrLogic.HeroBasicAttr", require("logic.AttrLogic.Attr"))

function HeroBasicAttr:initialize(heroLvl, heroTId)
  self.heroLvl = heroLvl
  self.heroTId = heroTId
  self.attrDic = {}
  self:_GetHeroBasicAttr()
end

function HeroBasicAttr:_GetHeroBasicAttr()
  local tabHeroInfo = configManager.GetDataById("config_ship_main", self.heroTId)
  local attrTbl = Logic.attrLogic:GetAttrTableShow()
  local lvconfig = configManager.GetDataById("config_ship_levelup", self.heroLvl)
  local factor = lvconfig and lvconfig.attribute_level - 1 or 0
  for k, v in pairs(attrTbl) do
    local attrString = Logic.attrLogic:GetAttrStringById(v)
    local temp = 0
    if tabHeroInfo[attrString] ~= nil then
      temp = tabHeroInfo[attrString]
    end
    local lvlAttrString = attrString .. "_levelup"
    if tabHeroInfo[lvlAttrString] ~= nil then
      temp = temp + math.floor(factor * (tabHeroInfo[lvlAttrString] / 100))
    end
    self:AddAttr(self.attrDic, v, temp)
  end
end

return HeroBasicAttr
