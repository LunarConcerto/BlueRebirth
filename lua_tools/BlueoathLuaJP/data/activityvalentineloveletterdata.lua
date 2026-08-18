local ActivityValentineLoveLetterData = class("data.ActivityValentineLoveLetterData")
ValentineLoveLetterMaxNum = 4

function ActivityValentineLoveLetterData:initialize()
  self.mLoveShipData = {}
  self.mLoveShipList = {}
  self.mCurActShip = 0
end

function ActivityValentineLoveLetterData:UpdateData(TRet)
  if TRet == nil then
    logError("TRet is nil !")
    return
  end
  if TRet.CurActShip then
    self.mCurActShip = TRet.CurActShip
  end
  if TRet.LoveShip ~= nil and #TRet.LoveShip > 0 then
    for _, data in ipairs(TRet.LoveShip) do
      if data.ShipTid == nil or 0 >= data.ShipTid then
        self.mLoveShipData = {}
        self.mLoveShipList = {}
      else
        self.mLoveShipData[data.ShipTid] = data
        self.mLoveShipList[data.Index] = data
      end
    end
  end
end

function ActivityValentineLoveLetterData:GetShipTidByIndex(index)
  local data = self.mLoveShipList[index] or {}
  local shipTid = data.ShipTid or 0
  return shipTid
end

function ActivityValentineLoveLetterData:GetIsGift(index)
  local data = self.mLoveShipList[index] or {}
  local isGift = data.IsGift or false
  return isGift
end

function ActivityValentineLoveLetterData:GetHeroTidByShipTid(shipTid)
  local data = self.mLoveShipData[shipTid] or {}
  local tid = data.TemplateId or 0
  return tid
end

function ActivityValentineLoveLetterData:GetHeroIdByShipTid(shipTid)
  local data = self.mLoveShipData[shipTid] or {}
  local hid = data.HeroId or 0
  return hid
end

function ActivityValentineLoveLetterData:GetCurActShipCanGet()
  return self.mCurActShip ~= 0
end

return ActivityValentineLoveLetterData
