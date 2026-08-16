local TowerSoloProcess = class("UI.Tower.TowerSoloProcess")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local distance_vertical = UIManager:GetUIWidth() * 200 / 1334
local zoom_max_disappear_start = 1.35
local zoom_max_disappear_end = 1.39
local zoom_min_disappear = 0.06
local zoom_min_disappear_bottom = 2.576
local zoom_min_disappear_alpha = 0.85
local offset_x = 620
local zoom_min_tile = 0.6
local camera_move_rate = 0.04
local line_disappear_rate_min = 0.3
local line_disappear_rate_max = 1.35
local perfect_rate = 1.056
local content_offset = 400
local sea_padding = 8 * UIManager:GetUIHeight() / 750

function TowerSoloProcess:GetIndex(page)
  return page.index
end

function TowerSoloProcess:GetGrid(page)
  local widgets = page:GetWidgets()
  return widgets.grid
end

function TowerSoloProcess:GetScrollContent(page)
  local widgets = page:GetWidgets()
  return widgets.Content
end

function TowerSoloProcess:prepareCopyData(page, themeConfig, chapterTowerConfig)
  local themeConfig = page.themeConfig
  local chapterTowerConfig = page.chapterTowerConfig
  local copyIdNow = Logic.towerLogic:GetCopyIdNow()
  local chapterNum = #themeConfig.copy_list
  local copyNum = 0
  local copyNumNotBoss = 0
  local copyTbl = {}
  for i = 1, chapterNum do
    copyNum = copyNum + #themeConfig.copy_list[i]
    for k, v in ipairs(themeConfig.copy_list[i]) do
      local sub = {}
      sub.copyId = v
      sub.isBoss = k == #themeConfig.copy_list[i]
      if sub.isBoss then
        sub.rewardId = chapterTowerConfig.area_pass_reward[i]
        sub.name = themeConfig.copy_list_name[i]
        sub.posIndex = 0
      else
        copyNumNotBoss = copyNumNotBoss + 1
        local indexTmp = copyNumNotBoss % 2
        if indexTmp == 1 then
          sub.posIndex = 1
        else
          sub.posIndex = -1
        end
      end
      table.insert(copyTbl, sub)
    end
  end
  local copyTblReal = {}
  page.index = 0
  for i = #copyTbl, 1, -1 do
    table.insert(copyTblReal, copyTbl[i])
    if copyTbl[i].copyId == copyIdNow then
      page.index = #copyTblReal
    end
  end
  page.copyTbl = copyTblReal
end

function TowerSoloProcess:RegisterScrollRectChange(page)
  local widgets = page:GetWidgets()
  page.pos = widgets.Content.transform.localPosition
  widgets.scrollRect.gameObject:SetActive(true)
  widgets.bu_map.gameObject:SetActive(false)
  widgets.scrollRectNew.gameObject:SetActive(false)
  widgets.scrollRect.onValueChanged:AddListener(function()
    page:_OnScrollRectChange(page)
  end)
end

function TowerSoloProcess:showCopyInfo(page)
  local widgets = page:GetWidgets()
  widgets.buff.gameObject:SetActive(false)
  local copyTbl = page.copyTbl
  page.tabPart = {}
  UIHelper.CreateSubPart(widgets.obj_level, widgets.Content, #copyTbl, function(index, tabPart)
    page.tabPart[index] = tabPart
    local copyInfo = copyTbl[index]
    self:showCopyInfoSub(page, index, tabPart, copyInfo)
    if copyInfo.rewardId then
      UIHelper.SetText(tabPart.tx_level, copyInfo.name)
      local rewards = Logic.rewardLogic:FormatRewardById(copyInfo.rewardId)
      UIHelper.CreateSubPart(tabPart.obj_reward, tabPart.content_reward, #rewards, function(indexSub, tabPartSub)
        local reward = rewards[indexSub]
        local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
        UIHelper.SetText(tabPartSub.tx_num, reward.Num)
        UIHelper.SetImage(tabPartSub.icon, display.icon_small)
      end)
    end
  end)
end

function TowerSoloProcess:_OnScrollRectChange(page, vec2, isOnOpen, isJump)
  for index, tabPart in ipairs(page.tabPart) do
    page:_OnScrollRectChangeSub(index, tabPart, isOnOpen, isJump)
  end
end

function TowerSoloProcess:_OnScrollRectChangeSub(page, tabPart, scale, index, indexSub)
  local copyIdNow = Logic.towerLogic:GetCopyIdNow()
  local copyInfo = page.copyTbl[index]
  local flag = scale < zoom_max_disappear_end and scale > zoom_min_disappear
  local isCopyMax = Logic.towerLogic:IsCopyMax()
  local isClear = self:IsClear(page, index, copyInfo.copyId) or isCopyMax
  local boss_luapart = tabPart.boss_luapart:GetLuaTableParts()
  boss_luapart.im_diban:SetActive(flag and not isClear)
  boss_luapart.im_dingceng:SetActive(flag and not isClear)
  boss_luapart.im_bossname:SetActive(flag and not isClear)
  boss_luapart.other:SetActive(flag and not isClear)
  boss_luapart.im_icon_boss.enabled = flag and not isClear
  boss_luapart.im_icon_clear.gameObject:SetActive(flag and isClear)
  boss_luapart.im_now:SetActive(flag and copyInfo.copyId == copyIdNow)
  local littleboss_luapart = tabPart.littleboss_luapart:GetLuaTableParts()
  littleboss_luapart.im_diban:SetActive(flag and not isClear)
  littleboss_luapart.im_dingceng:SetActive(flag and not isClear)
  littleboss_luapart.im_littlebossname:SetActive(flag and not isClear)
  littleboss_luapart.im_icon.enabled = flag and not isClear
  littleboss_luapart.im_icon_clear.gameObject:SetActive(flag and isClear)
  littleboss_luapart.im_now:SetActive(flag and copyInfo.copyId == copyIdNow)
  tabPart.boss_anim.enabled = flag and copyInfo.copyId == copyIdNow
  tabPart.littleboss_anim.enabled = flag and copyInfo.copyId == copyIdNow
  tabPart.littleboss_xian_anim.enabled = flag and copyInfo.copyId == copyIdNow
  tabPart.line.transform.localScale = Vector3.New(scale, scale, scale)
  local pos = tabPart.im_levelcopy.transform.position
  tabPart.im_levelcopy.transform.position = Vector3.New(pos.x, tabPart.icon_rect.position.y, pos.z)
  tabPart.trans.localPosition = Vector3.New(offset_x + copyInfo.posIndex * distance_vertical * scale, pos.y, pos.z)
  if scale < line_disappear_rate_min then
    tabPart.levelcopy.transform.localScale = Vector3.New(0, 0, 0)
  elseif scale > line_disappear_rate_max then
    tabPart.levelcopy.transform.localScale = Vector3.New(0, 0, 0)
  else
    tabPart.levelcopy.transform.localScale = Vector3.New(1, 1, 1)
  end
end

function TowerSoloProcess:_drawLine(page, index, scale, alpha, flag)
  local flag = scale < zoom_max_disappear_end and scale > zoom_min_disappear
  if 1 < index and scale > zoom_min_tile and 0 < alpha and flag then
    local iconNow = page.tabPart[index].pos_rect.position
    local iconPre = page.tabPart[index - 1].pos_rect.position
    page:drawLine(iconNow, iconPre)
  end
end

function TowerSoloProcess:IsClear(page, index)
  return index > page.index
end

function TowerSoloProcess:showCopyInfoSub(page, index, tabPart, copyInfo)
  local copyId = copyInfo.copyId
  local isBoss = copyInfo.isBoss
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  UIHelper.SetText(tabPart.tx_name, copyConfig.name)
  UIHelper.SetText(tabPart.tx_name_boss, copyConfig.name)
  local boss_luapart = tabPart.boss_luapart:GetLuaTableParts()
  UIHelper.SetImage(boss_luapart.im_icon_clear, copyConfig.copy_thumbnail_after, true)
  local littleboss_luapart = tabPart.littleboss_luapart:GetLuaTableParts()
  UIHelper.SetImage(littleboss_luapart.im_icon_clear, copyConfig.copy_thumbnail_after, true)
  UIHelper.SetImage(tabPart.im_icon, copyConfig.copy_thumbnail_before, true)
  UIHelper.SetImage(tabPart.icon_boss, copyConfig.copy_thumbnail_before, true)
  local isCopyMax = Logic.towerLogic:IsCopyMax()
  local isClear = page.process:IsClear(page, index, copyId)
  isClear = isClear or isCopyMax
  boss_luapart.im_icon_revive.gameObject:SetActive(copyConfig.revive_icon_before ~= "" and not isClear)
  littleboss_luapart.im_icon_revive.gameObject:SetActive(copyConfig.revive_icon_before ~= "" and not isClear)
  boss_luapart.im_icon_revive_clear.gameObject:SetActive(copyConfig.revive_icon_after ~= "" and isClear)
  littleboss_luapart.im_icon_revive_clear.gameObject:SetActive(copyConfig.revive_icon_after ~= "" and isClear)
  if not isClear then
    UGUIEventListener.AddButtonOnClick(tabPart.btn_boss, page.bu_copy, page, copyId)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_littleboss, page.bu_copy, page, copyId)
    if copyConfig.revive_icon_before ~= "" then
      UIHelper.SetImage(boss_luapart.im_icon_revive, copyConfig.revive_icon_before, true)
      UIHelper.SetImage(littleboss_luapart.im_icon_revive, copyConfig.revive_icon_before, true)
    end
  elseif copyConfig.revive_icon_after ~= "" then
    UIHelper.SetImage(boss_luapart.im_icon_revive_clear, copyConfig.revive_icon_after, true)
    UIHelper.SetImage(littleboss_luapart.im_icon_revive_clear, copyConfig.revive_icon_after, true)
  end
  littleboss_luapart.buff:SetActive(isBuff)
  if isBuff then
    local buffDes = Logic.towerLogic:GetBuffDes(copyId)
    UIHelper.SetText(littleboss_luapart.tx_buff, buffDes)
  end
  tabPart.boss:SetActive(isBoss)
  tabPart.levelcopy:SetActive(isBoss)
  tabPart.littleboss:SetActive(not isBoss)
  local hp = AllLBPoint
  if copyData then
    hp = AllLBPoint - copyData.LBPoint
  end
  UIHelper.SetText(tabPart.tx_hp, math.ceil(100 * hp / AllLBPoint) .. "%")
  tabPart.tx_hp.gameObject:SetActive(isBoss)
  tabPart.im_bosshp.fillAmount = hp / AllLBPoint
end

function TowerSoloProcess:GetCopyState(page, index, copyId)
  local isCopyMax = Logic.towerLogic:IsCopyMax()
  local isClear = self:IsClear(page, index, copyId) or isCopyMax
  if isClear then
    return TowerCopyState.Clear
  else
    return TowerCopyState.Attack
  end
end

function TowerSoloProcess:IsDeadRoad()
  return false
end

function TowerSoloProcess:GetOffSet(page, index, indexSub)
  return 0
end

function TowerSoloProcess:bu_copy(page, copyId)
  Logic.towerLogic:CopyClick(copyId)
end

return TowerSoloProcess
