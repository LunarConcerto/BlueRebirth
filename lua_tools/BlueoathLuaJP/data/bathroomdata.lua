local BathroomData = class("data.BathroomData", Data.BaseData)

function BathroomData:initialize()
  self:ResetData()
end

function BathroomData:ResetData()
  self.bathRoomHero = {}
  self.bathRoomHeroCache = {}
  self.isAllAuto = 0
end

function BathroomData:SetData(param)
  self.bathRoomHero = param.HeroList
  self.isAllAuto = param.IsAllAuto
  for _, data in pairs(param.HeroList) do
    if data.HeroId then
      eventManager:SendEvent(LuaEvent.HERO_TryUpdateHeroExData, data.HeroId)
    end
  end
end

function BathroomData:GetBathHero()
  return self.bathRoomHero
end

function BathroomData:GetBathHeroId()
  local bathInfo = {}
  for _, v in ipairs(self.bathRoomHero) do
    if next(v) ~= nil then
      bathInfo[v.HeroId] = v
    end
  end
  return bathInfo
end

function BathroomData:GetAllAuto()
  return self.isAllAuto
end

return BathroomData
