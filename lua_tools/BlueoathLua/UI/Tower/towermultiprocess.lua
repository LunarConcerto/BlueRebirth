local TowerMultiProcess = class("UI.Tower.TowerMultiProcess")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local distance_vertical = UIManager:GetUIWidth() * 200 / 1334
local zoom_max_disappear_start = 1.35
local zoom_max_disappear_end = 1.39
local zoom_min_disappear = 0.06
local zoom_min_disappear_bottom = 2.576
local zoom_min_disappear_alpha = 0.85
local offset_x = 620
local zoom_min_tile = 0.8
local camera_move_rate = 0.04
local line_disappear_rate_min = 0.3
local line_disappear_rate_max = 1.35
local perfect_rate = 1.056
local content_offset = 400
local sea_padding = 8 * UIManager:GetUIHeight() / 750

function TowerMultiProcess:GetIndex()
  return 2
end

function TowerMultiProcess:GetGrid(page)
  local widgets = page:GetWidgets()
  return widgets.grid_new
end

function TowerMultiProcess:GetScrollContent(page)
  local widgets = page:GetWidgets()
  return widgets.Content_new
end

function TowerMultiProcess:prepareCopyData(page)
  local themeConfig = page.themeConfig
  local copyList = Data.towerData:GetCopyList()
  page.copyList = copyList
  local copyListRevert = {}
  for i = #copyList, 1, -1 do
    table.insert(copyListRevert, copyList[i])
  end
  page.copyListRevert = copyListRevert
  local bossMap = {}
  for i, v in ipairs(themeConfig.area_final_copy) do
    for iSub, vSub in ipairs(v) do
      bossMap[vSub] = true
    end
  end
  local copyTblReal = {}
  local len = #copyList
  for i = len, 1, -1 do
    local copyId = copyList[i]
    local copyConfig = configManager.GetDataById("config_copy_display", copyId)
    local copyListBranch = copyConfig.branch_copy
    local copyListSub = {}
    for index = 1, #copyListBranch do
      local copyBranch = copyListBranch[index]
      local copyBranchInfo = {}
      copyBranchInfo.copyId = copyBranch
      copyBranchInfo.isBoss = bossMap[copyId]
      local flag = true
      for indexSub = 1, i - 1 do
        if copyBranch == copyList[indexSub] then
          flag = false
        end
      end
      if flag == true then
        table.insert(copyListSub, copyBranchInfo)
      end
    end
    table.insert(copyTblReal, copyListSub)
  end
  local copyIdInit = Logic.towerLogic:GetMultiCopyIdInit()
  table.insert(copyTblReal, {
    {
      copyId = copyIdInit,
      isBoss = bossMap[copyIdInit]
    }
  })
  page.copyTbl = copyTblReal
end

function TowerMultiProcess:RegisterScrollRectChange(page)
  local widgets = page:GetWidgets()
  page.pos = widgets.Content_new.transform.localPosition
  widgets.scrollRectNew.gameObject:SetActive(true)
  widgets.bu_map.gameObject:SetActive(true)
  widgets.scrollRect.gameObject:SetActive(false)
  widgets.scrollRectNew.onValueChanged:AddListener(function()
    page:_OnScrollRectChange(page)
  end)
end

function TowerMultiProcess:showCopyInfo(page)
  local widgets = page:GetWidgets()
  local buffDes = Logic.towerLogic:GetAllBuffDes()
  UIHelper.SetText(widgets.tx_buff, buffDes)
  widgets.buff.gameObject:SetActive(true)
  local copyTbl = page.copyTbl
  page.tabPartNew = {}
  UIHelper.CreateSubPart(widgets.obj_level_new, widgets.Content_new, #copyTbl, function(index, tabPart)
    local copyTblSub = copyTbl[index]
    page.tabPartNew[index] = {}
    UIHelper.CreateSubPart(tabPart.obj_level_hero, tabPart.obj_level_new, #copyTblSub, function(indexSub, tabPartSub)
      local copyInfo = copyTblSub[indexSub]
      self:showCopyInfoSub(page, index, tabPartSub, copyInfo, indexSub)
      page.tabPartNew[index][indexSub] = tabPartSub
    end)
  end)
end

function TowerMultiProcess:_OnScrollRectChange(page, vec2, isOnOpen, isJump)
  for index, tabPart in ipairs(page.tabPartNew) do
    for indexSub, tabPartSub in ipairs(tabPart) do
      page:_OnScrollRectChangeSub(index, tabPartSub, isOnOpen, isJump, indexSub)
    end
  end
end

function TowerMultiProcess:_OnScrollRectChangeSub(page, tabPart, scale, index, indexSub)
  local copyInfo = page.copyTbl[index][indexSub]
  local flag = scale < zoom_max_disappear_end and scale > zoom_min_disappear
  local copyId = copyInfo.copyId
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  local state = self:GetCopyState(page, index, copyId, indexSub)
  local isClear = state == TowerCopyState.Clear
  isClear = isClear and flag
  local isAttack = state == TowerCopyState.Attack
  isAttack = isAttack and flag
  local isAttackOrAbandon = state == TowerCopyState.Attack or state == TowerCopyState.Abandon
  isAttackOrAbandon = isAttackOrAbandon and flag
  local isAttackOrClear = state == TowerCopyState.Attack or state == TowerCopyState.Clear
  isAttackOrClear = isAttackOrClear and flag
  local boss_luapart = tabPart.boss_luapart:GetLuaTableParts()
  boss_luapart.im_diban:SetActive(isAttackOrAbandon)
  boss_luapart.im_dingceng:SetActive(isAttack)
  boss_luapart.im_bossname:SetActive(isAttack)
  boss_luapart.other:SetActive(isAttackOrAbandon)
  boss_luapart.im_icon_boss.enabled = isAttack
  boss_luapart.im_icon_clear.gameObject:SetActive(isClear)
  boss_luapart.im_now:SetActive(isAttack)
  local littleboss_luapart = tabPart.littleboss_luapart:GetLuaTableParts()
  littleboss_luapart.im_diban:SetActive(isAttackOrAbandon)
  littleboss_luapart.im_dingceng:SetActive(isAttack)
  littleboss_luapart.im_littlebossname:SetActive(isAttack)
  littleboss_luapart.im_icon.enabled = isAttack
  littleboss_luapart.im_icon_clear.gameObject:SetActive(isClear)
  littleboss_luapart.im_now:SetActive(false)
  littleboss_luapart.buff:SetActive(isAttackOrClear and isBuff)
  tabPart.boss_anim.enabled = isAttack
  tabPart.littleboss_anim.enabled = isAttack
  tabPart.littleboss_xian_anim.enabled = isAttack
  local pos = tabPart.im_levelcopy.transform.position
  local copys = page.tabPartNew[index]
  local offset = page.posMultiTable[#copys][indexSub]
  tabPart.trans.localPosition = Vector3.New(offset_x + offset.x * scale, pos.y + offset.y, pos.z)
end

function TowerMultiProcess:_drawLine(page, index, scale, alpha)
  local flag = scale < zoom_max_disappear_end and scale > zoom_min_disappear
  if 1 < index and scale > zoom_min_tile and 0 < alpha and flag then
    local copyList = page.copyTbl[index]
    local lineIndex = 1
    for k, v in ipairs(copyList) do
      if v == page.copyListRevert[index] then
        lineIndex = k
      end
    end
    local copysNow = page.tabPartNew[index]
    local copysPre = page.tabPartNew[index - 1]
    local iconNow = copysNow[lineIndex].pos_rect.position
    for indexSub = 1, #copysPre do
      local iconPre = copysPre[indexSub].pos_rect.position
      page:drawLine(iconNow, iconPre)
    end
  end
end

function TowerMultiProcess:IsClear(page, index, copyId)
  local copyList = Data.towerData:GetCopyList()
  for i, v in ipairs(copyList) do
    if v == copyId then
      return true
    end
  end
  return false
end

function TowerMultiProcess:showCopyInfoSub(page, index, tabPart, copyInfo, indexSub)
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
  local state = self:GetCopyState(page, index, copyId, indexSub)
  logError("", index, indexSub, copyId, state)
  local isClear = state == TowerCopyState.Clear
  boss_luapart.im_icon_revive.gameObject:SetActive(copyConfig.revive_icon_before ~= "" and not isClear)
  littleboss_luapart.im_icon_revive.gameObject:SetActive(copyConfig.revive_icon_before ~= "" and not isClear)
  boss_luapart.im_icon_revive_clear.gameObject:SetActive(copyConfig.revive_icon_after ~= "" and isClear)
  littleboss_luapart.im_icon_revive_clear.gameObject:SetActive(copyConfig.revive_icon_after ~= "" and isClear)
  littleboss_luapart.buff:SetActive(isBuff)
  if isBuff then
    local buffDes = Logic.towerLogic:GetBuffDes(copyId)
    UIHelper.SetText(littleboss_luapart.tx_buff, buffDes)
  end
  if state == TowerCopyState.Attack then
    UGUIEventListener.AddButtonOnClick(tabPart.btn_boss, page.bu_copy, page, copyId)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_littleboss, page.bu_copy, page, copyId)
  end
  if state == TowerCopyState.Clear then
    if copyConfig.revive_icon_after ~= "" then
      UIHelper.SetImage(boss_luapart.im_icon_revive_clear, copyConfig.revive_icon_after, true)
      UIHelper.SetImage(littleboss_luapart.im_icon_revive_clear, copyConfig.revive_icon_after, true)
    end
  elseif copyConfig.revive_icon_before ~= "" then
    UIHelper.SetImage(boss_luapart.im_icon_revive, copyConfig.revive_icon_before, true)
    UIHelper.SetImage(littleboss_luapart.im_icon_revive, copyConfig.revive_icon_before, true)
  end
  tabPart.boss:SetActive(isBoss)
  tabPart.littleboss:SetActive(not isBoss)
  local hp = AllLBPoint
  if copyData then
    hp = AllLBPoint - copyData.LBPoint
  end
  UIHelper.SetText(tabPart.tx_hp, math.ceil(100 * hp / AllLBPoint) .. "%")
  tabPart.tx_hp.gameObject:SetActive(isBoss)
  tabPart.im_bosshp.fillAmount = hp / AllLBPoint
end

function TowerMultiProcess:GetCopyState(page, index, copyId, indexSub)
  local copyMapClear = Data.towerData:GetCopyMap()
  local copyMapAttack = Logic.towerLogic:GetCopyAttack()
  if copyMapClear[copyId] then
    return TowerCopyState.Clear
  elseif copyMapAttack[copyId] then
    return TowerCopyState.Attack
  else
    return TowerCopyState.Abandon
  end
end

function TowerMultiProcess:IsDeadRoad(page)
  local copyList = Data.towerData:GetCopyList()
  if #copyList <= 0 then
    return false
  end
  local copyId = copyList[#copyList]
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  for i, v in ipairs(copyConfig.branch_copy) do
    if not self:IsClear(page, nil, v) then
      return false
    end
  end
  return true
end

function TowerMultiProcess:GetOffSet(page, index, indexSub)
  local copys = page.tabPartNew[index]
  local offset = page.posMultiTable[#copys][indexSub]
  return offset.y
end

return TowerMultiProcess
