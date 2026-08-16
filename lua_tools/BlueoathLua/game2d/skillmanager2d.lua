local skillManager2d = class("game2d.skillManager2d")
local socket = require("socket")

function skillManager2d:InitData(scene_root)
  self.item_root = scene_root:Find("Bomb")
  self.skillItem = {}
  self.skill_time = {}
  self.skill_count = 0
end

function skillManager2d:Skill(id)
  local config = configManager.GetDataById("config_minigame_skill", id)
  local _time = self.skill_time[id] or 0
  if GameManager2d:GetTime() - _time < config.skill_cd and _time ~= 0 then
    return
  end
  self.skill_time[id] = GameManager2d:GetTime()
  if id == Skill2d.Bomb then
    BombManager2d:CreateBomb()
  else
    self.skill_count = self.skill_count + 1
    PlayerManager2d:SetTimeByBuffId(config.buff_id)
  end
end

function skillManager2d:GetCd(id)
  if id <= 0 then
    return 1
  end
  local config = configManager.GetDataById("config_minigame_skill", id)
  local _time = self.skill_time[id] or 0
  if _time == 0 then
    return 1
  else
    return (GameManager2d:GetTime() - _time) / config.skill_cd
  end
end

function skillManager2d:Destroy()
  self.item_root = nil
end

function skillManager2d:GetSkillCount()
  return self.skill_count
end

return skillManager2d
