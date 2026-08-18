local ShipLV5 = class("game.guide.guideTrigger.ShipLV5", GR.requires.GuideTriggerBase)

function ShipLV5:initialize(nType)
  self.type = nType
end

function ShipLV5:tick()
  local tblAllHeros = Data.heroData:GetHeroData()
  for k, v in pairs(tblAllHeros) do
    if v.Lvl >= 5 then
      self:sendTrigger()
    end
  end
end

return ShipLV5
