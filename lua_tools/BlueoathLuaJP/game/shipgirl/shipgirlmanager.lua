local ShipGirlManager = class("game.ShipGirl.ShipGirlManager")
local ShipGirl = require("game.ShipGirl.ShipGirl")

function ShipGirlManager:initialize(param)
  self.UIDCounter = 0
  self.shipGirls = {}
end

local MAX_GIRL_NUM_CACHE = 10

function ShipGirlManager:checkGarbage()
  if self.UIDCounter % MAX_GIRL_NUM_CACHE == 0 then
    GR.luaInteraction:clearUnusedRes()
  end
end

function ShipGirlManager:createShipGirl(param, layer, parentTrans)
  local shipGirl = self:createShipGirlDirBehaviour(param, layer, parentTrans, "stand_loop")
  self:checkGarbage()
  return shipGirl
end

function ShipGirlManager:createShipGirlDirBehaviour(param, layer, parentTrans, behaviourName)
  param.dressID = param.dressID or -1
  param.UID = self:newID()
  local shipGirl = ShipGirl:new(param, layer, parentTrans)
  self.shipGirls[shipGirl.UID] = shipGirl
  if behaviourName ~= nil then
    shipGirl:playBehaviour(behaviourName, true)
    shipGirl:resetCollider()
  end
  return shipGirl
end

function ShipGirlManager:destroyShipGirl(shipGirl)
  if self.shipGirls[shipGirl.UID] then
    shipGirl:destroy()
    self.shipGirls[shipGirl.UID] = nil
  end
end

function ShipGirlManager:newID()
  self.UIDCounter = self.UIDCounter + 1
  return self.UIDCounter
end

function ShipGirlManager:clear()
  self.UIDCounter = 0
  for k, v in pairs(self.shipGirls) do
    v:destroy()
  end
  self.shipGirls = {}
end

return ShipGirlManager
