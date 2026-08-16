local ActivityAdventurePage = class("ui.page.Activity.BigActivity.ActivityAdventurePage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local time_attack_animation = 0.5
local time_death = 1
local isAnimation = false

function ActivityAdventurePage:DoInit()
  self.heroPart = {}
  self.heroLevel = {}
end

function ActivityAdventurePage:DoOnOpen()
  isAnimation = false
  self:ShowContent()
end

function ActivityAdventurePage:ShowRoles()
  local widgets = self:GetWidgets()
  local roles = configManager.GetDataById("config_parameter", 284).arrValue
  for index = 1, #roles do
    local tabPart = widgets["hero" .. index]:GetLuaTableParts()
    local roleId = roles[index]
    local config = configManager.GetDataById("config_adventure_role", roleId)
    UIHelper.SetText(tabPart.tx_name, config.hero_name)
    UIHelper.SetImage(tabPart.im_profession, config.hero_profession)
    local level = Data.adventureData:GetLevelById(roleId)
    self.heroLevel[index] = level
    tabPart.tx_max:SetActive(level >= config.level_max)
    UIHelper.SetLocText(tabPart.tx_level, 160022, level)
    local hp = Data.adventureData:GetHpById(roleId)
    UIHelper.SetText(tabPart.tx_hp, hp)
    UIHelper.SetImage(tabPart.im_hero, config.image)
    local itemInfo = config.levelup_item
    local numOwn = Data.bagData:GetItemNum(itemInfo[2])
    if level >= config.level_max then
      UIHelper.SetText(tabPart.tx_num, numOwn)
    else
      UIHelper.SetText(tabPart.tx_num, numOwn .. "/" .. config.levelup_item_num[level])
    end
    local display = ItemInfoPage.GenDisplayData(itemInfo[1], itemInfo[2])
    UIHelper.SetImage(tabPart.img_item, display.icon_small)
  end
  local result = Logic.adventureLogic:IsAllLevelMax()
  widgets.btn_levelup.gameObject:SetActive(not result)
end

function ActivityAdventurePage:ShowEnemy()
  local widgets = self:GetWidgets()
  local index = Data.adventureData:GetIndex()
  local enemyTbl = configManager.GetDataById("config_parameter", 285).arrValue
  if index < #enemyTbl then
    local enemyId = enemyTbl[index + 1]
    local config = configManager.GetDataById("config_adventure_role", enemyId)
    self.configEnemyPre = config
    UIHelper.SetText(widgets.tx_name, config.hero_name)
    UIHelper.SetImage(widgets.im_enemy, config.image)
    UIHelper.SetImage(widgets.im_enemy_be_attack, config.image_attack)
    local damage = Data.adventureData:GetEnemyDamage()
    local hpMax = config.enemy_life
    local hpLeft = hpMax - damage
    UIHelper.SetText(widgets.txt_hp, hpLeft .. "/" .. hpMax)
    widgets.Slider.value = hpLeft / hpMax
  else
    local enemyId = enemyTbl[index]
    local config = configManager.GetDataById("config_adventure_role", enemyId)
    self.configEnemyPre = config
    UIHelper.SetText(widgets.tx_name, config.hero_name)
    UIHelper.SetImage(widgets.im_enemy, config.image_death)
    UIHelper.SetImage(widgets.im_enemy_be_attack, config.image_attack)
    local hpMax = config.enemy_life
    local hpLeft = 0
    UIHelper.SetText(widgets.txt_hp, hpLeft .. "/" .. hpMax)
    widgets.Slider.value = hpLeft / hpMax
  end
  local isAllKill = Logic.adventureLogic:IsAllKill()
  local haveHp = Logic.adventureLogic:HaveHp()
  local unAttack = isAllKill or not haveHp
  widgets.btnUnAttack.gameObject:SetActive(unAttack)
  widgets.btnAttack.gameObject:SetActive(not unAttack)
end

function ActivityAdventurePage:ShowEnemyKill()
  local widgets = self:GetWidgets()
  UIHelper.SetText(widgets.txt_hp, 0)
  widgets.Slider.value = 0
end

function ActivityAdventurePage:ShowReward()
  local widgets = self:GetWidgets()
  local index = Data.adventureData:GetIndex()
  local enemyTbl = configManager.GetDataById("config_parameter", 285).arrValue
  local progress = index .. "/" .. #enemyTbl
  UIHelper.SetText(widgets.tx_reward, progress)
end

function ActivityAdventurePage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.btn_levelup, self.btn_levelup, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_attack, self.btn_attack, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnAttack, self.btn_attack, self)
  UGUIEventListener.AddButtonOnClick(widgets.btnUnAttack, self.btn_un_attack, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_reward, self.btn_reward, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_help, self.btn_help, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_closeTip, self.btn_closeTip, self)
  self:RegisterEvent(LuaEvent.AdventureLevelUp, self.AdventureLevelUp, self)
  self:RegisterEvent(LuaEvent.AdventureAttack, self.AdventureAttack, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
end

function ActivityAdventurePage:btn_levelup(...)
  local result = false
  local roles = configManager.GetDataById("config_parameter", 284).arrValue
  for i, roleId in ipairs(roles) do
    local config = configManager.GetDataById("config_adventure_role", roleId)
    local level = Data.adventureData:GetLevelById(roleId)
    local itemInfo = config.levelup_item
    local numOwn = Data.bagData:GetItemNum(itemInfo[2])
    if level < config.level_max and numOwn >= config.levelup_item_num[level] then
      result = true
      break
    end
  end
  if result == false then
    noticeManager:ShowTipById(7200011)
    return
  end
  Service.adventureService:SendLevelUp()
end

function ActivityAdventurePage:btn_attack(...)
  if Logic.adventureLogic:IsAllKill() then
    noticeManager:ShowTipById(7200014)
    return
  end
  local haveHp = Logic.adventureLogic:HaveHp()
  if haveHp == false then
    noticeManager:ShowTipById(7200012)
    return
  end
  if isAnimation == true then
    return
  end
  Service.adventureService:SendAttack()
end

function ActivityAdventurePage:btn_un_attack(...)
  if Logic.adventureLogic:IsAllKill() then
    noticeManager:ShowTipById(7200014)
    return
  end
  local haveHp = Logic.adventureLogic:HaveHp()
  if haveHp == false then
    noticeManager:ShowTipById(7200012)
    return
  end
end

function ActivityAdventurePage:btn_reward(...)
  UIHelper.OpenPage("ActivityPage", {
    activityId = Activity.Adventure_task
  })
end

function ActivityAdventurePage:AdventureLevelUp(msg)
  local roles = configManager.GetDataById("config_parameter", 284).arrValue
  for index = 1, #roles do
    local roleId = roles[index]
    local level = Data.adventureData:GetLevelById(roleId)
    if level > self.heroLevel[index] then
      local widgets = self:GetWidgets()
      widgets["eff2d_adventure_levelup" .. index]:SetActive(false)
      widgets["eff2d_adventure_levelup" .. index]:SetActive(true)
    end
  end
  self:ShowContent()
end

function ActivityAdventurePage:AdventureAttack(msg)
  isAnimation = true
  if msg and msg.Damage > 0 then
    local widgets = self:GetWidgets()
    widgets.eff2d_adventure_attack.gameObject:SetActive(true)
    widgets.eff2d_adventure_attack:Play()
    UIHelper.SetText(widgets.tx_damage, -msg.Damage)
    local timer = self:CreateTimer(function()
      self:AdventureDeath(msg)
    end, time_attack_animation, 1, true)
    self:StartTimer(timer)
  end
end

function ActivityAdventurePage:AdventureDeath(msg)
  local widgets = self:GetWidgets()
  if msg and msg.IsKilled then
    widgets.eff2d_adventure_death:SetActive(false)
    widgets.eff2d_adventure_death:SetActive(true)
    UIHelper.SetImage(widgets.im_enemy, self.configEnemyPre.image_death)
    self:ShowRoles()
    self:ShowEnemyKill()
    local timer = self:CreateTimer(function()
      local index = Data.adventureData:GetIndex()
      local enemyTbl = configManager.GetDataById("config_parameter", 285).arrValue
      local enemyId = enemyTbl[index]
      local roleConfig = configManager.GetDataById("config_adventure_role", enemyId)
      local taskId = roleConfig.task_id
      local taskConfig = configManager.GetDataById("config_task_activity", taskId)
      local rewardId = taskConfig.rewards
      Logic.rewardLogic:ShowCommonReward(Logic.rewardLogic:FormatRewardById(rewardId), "ActivityAdventurePage")
      if index >= #enemyTbl then
        noticeManager:ShowTipById(7200013)
      end
      self:ShowContent()
      widgets.eff2d_adventure_death:SetActive(false)
      isAnimation = false
    end, time_death, 1, true)
    self:StartTimer(timer)
  else
    self:ShowContent()
    isAnimation = false
  end
end

function ActivityAdventurePage:ShowContent(...)
  self:ShowRoles()
  self:ShowEnemy()
  self:ShowReward()
end

function ActivityAdventurePage:_OnGetReward(args)
  local taskInfo = Logic.taskLogic:GetTaskConfig(args.TaskId, args.TaskType)
  if taskInfo then
    self:_ShowTips({
      rewards = args.Rewards,
      config = taskInfo
    })
    self:_LoadItemInfo()
  end
end

function ActivityAdventurePage:_ShowItemInfo(go, award)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
end

function ActivityAdventurePage:DoOnHide()
end

function ActivityAdventurePage:DoOnClose()
end

function ActivityAdventurePage:btn_help()
  local widgets = self:GetWidgets()
  widgets.help:SetActive(true)
end

function ActivityAdventurePage:btn_closeTip()
  local widgets = self:GetWidgets()
  widgets.help:SetActive(false)
end

return ActivityAdventurePage
