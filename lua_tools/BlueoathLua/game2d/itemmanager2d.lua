local itemManager2d = class("game2d.itemManager2d")

function itemManager2d:InitData(scene_root)
  self.itemMap = {}
  self.itemMapByTemplateId = {}
  self.index = 1
  self.goMap = {}
  self.itemTemplateMap = {}
  local item_root = scene_root:Find("Item")
  self.item_root = item_root
  local gameConfig = GameManager2d:GetConfig()
  local item_random = gameConfig.item_random
  local randomMap = {}
  for i, v in ipairs(item_random) do
    randomMap[v[1]] = v[2]
  end
  for i = 0, item_root.childCount - 1 do
    local child = item_root:GetChild(i)
    local id = tonumber(child.name)
    local child_child_count = child.childCount
    if 0 < child_child_count then
      local index_tbl = {}
      for i = 1, child_child_count do
        table.insert(index_tbl, i)
      end
      local index_tbl_use = Logic2d:SelectNumber(randomMap[id], table.unpack(index_tbl))
      local index_map = {}
      for i, v in pairs(index_tbl_use) do
        index_map[v] = Item2dState.Active
      end
      if not self.itemMapByTemplateId[id] then
        self.itemMapByTemplateId[id] = {}
      end
      for i = 0, child.childCount - 1 do
        local child_child = child:GetChild(i)
        local state = index_map[i + 1] or Item2dState.UnActive
        if state == Item2dState.Active then
          local config = configManager.GetDataById("config_minigame_item", id)
          local item = require("game2d.item2d.item2d" .. config.template):new(self.index, id, child_child, state)
          self.itemMap[self.index] = item
          self.itemMapByTemplateId[id][self.index] = item
          self.index = self.index + 1
        else
          child_child.gameObject:SetActive(false)
        end
      end
    end
  end
end

function itemManager2d:DropItem(id, pos)
  for i = 0, self.item_root.childCount - 1 do
    local child = self.item_root:GetChild(i)
    if tonumber(child.name) == id then
      local config = configManager.GetDataById("config_minigame_item", id)
      local item = self.itemMapByTemplateId[id]
      if not item then
        local go = GR.objectPoolManager:LuaGetGameObject(config.respath, child.transform)
        self.goMap[self.index] = go
        item = require("game2d.item2d.item2d" .. config.template):new(self.index, id, go.transform, Item2dState.Active)
        go.transform.localPosition = pos
        self.itemMap[self.index] = item
        if not self.itemMapByTemplateId[id] then
          self.itemMapByTemplateId[id] = {}
        end
        self.itemMapByTemplateId[id][self.index] = item
        self.index = self.index + 1
      end
    end
  end
end

function itemManager2d:Reset()
  for i, v in pairs(self.itemMap) do
    v:Reset()
  end
end

function itemManager2d:CheckPlayerCollision()
  for id, v in pairs(self.itemMap) do
    local isCollision = self:CheckPlayerCollisionById(id)
  end
end

function itemManager2d:CheckPlayerCollisionById(id)
  local playerRect = PlayerManager2d:GetPlayerRect()
  local itemRect = self:GetRectById(id)
  return Logic2d:IsCollision(playerRect, itemRect)
end

function itemManager2d:GetRectById(id)
  local itemInfo = self.itemMap[id]
  return itemInfo:GetRect()
end

function itemManager2d:PickById(id)
  local itemInfo = self.itemMap[id]
  local templateId = itemInfo:GetTemplateId()
  self.itemTemplateMap[templateId] = true
  return itemInfo:Pick()
end

function itemManager2d:DropById(id)
  local itemInfo = self.itemMap[id]
  return itemInfo:Drop()
end

function itemManager2d:UseById(id)
  local itemInfo = self.itemMap[id]
  return itemInfo:Use()
end

function itemManager2d:GetPosById(id)
  local itemInfo = self.itemMap[id]
  return itemInfo:GetPos()
end

function itemManager2d:GetItemIdById(id)
  local itemInfo = self.itemMap[id]
  return itemInfo:GetItemId()
end

function itemManager2d:SetActiveById(id, state)
  local itemInfo = self.itemMap[id]
  return itemInfo:SetActive(state)
end

function itemManager2d:GetItemMap()
  return self.itemMap
end

function itemManager2d:Destroy()
  for i, v in pairs(self.itemMap) do
    if not self.goMap[self.index] then
      v:Destroy()
    end
  end
  self.itemMap = {}
  for i, v in pairs(self.goMap) do
    GR.objectPoolManager:LuaUnspawnAndDestory(v)
  end
  self.goMap = {}
  self.itemMapByTemplateId = {}
end

function itemManager2d:GetItemTemplateMap()
  local result = {}
  for i, v in pairs(self.itemTemplateMap) do
    table.insert(result, i)
  end
  return result
end

return itemManager2d
