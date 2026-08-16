local TowerTreeProcess = class("UI.Tower.TowerTreeProcess")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local distance_vertical = UIManager:GetUIWidth() * 200 / 1334
local zoom_max_disappear_start = 1.35
local zoom_max_disappear_end = 1.39
local line_max_global_y = 0.53
local line_mim_global_y = 0.1
local zoom_min_disappear = 0.06
local zoom_min_disappear_bottom = 2.576
local zoom_min_disappear_alpha = 0.85
local offset_x = 621
local camera_move_rate = 0.04
local perfect_rate = 1.056
local content_offset = 400
local sea_padding = 8 * UIManager:GetUIHeight() / 750

function TowerTreeProcess:GetIndex()
  return 2
end

function TowerTreeProcess:GetGrid(page)
  local widgets = page:GetWidgets()
  return widgets.grid_new
end

function TowerTreeProcess:GetScrollContent(page)
  local widgets = page:GetWidgets()
  return widgets.Content_new
end

function TowerTreeProcess:prepareCopyData(page)
  local themeConfig = page.themeConfig
  local copyList = Data.towerData:GetCopyList()
  page.copyList = copyList
  local copyListRevert = {}
  for i = #copyList, 1, -1 do
    table.insert(copyListRevert, copyList[i])
  end
  page.copyListRevert = copyListRevert
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
      local towerCopyType = self:GetTowerCopyType(themeConfig, copyBranch)
      copyBranchInfo.towerCopyType = towerCopyType
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
      towerCopyType = self:GetTowerCopyType(themeConfig, copyIdInit)
    }
  })
  page.copyTbl = copyTblReal
end

function TowerTreeProcess:RegisterScrollRectChange(page)
  local widgets = page:GetWidgets()
  page.pos = widgets.Content_new.transform.localPosition
  widgets.scrollRectNew.gameObject:SetActive(true)
  widgets.bu_map.gameObject:SetActive(true)
  widgets.scrollRect.gameObject:SetActive(false)
  widgets.scrollRectNew.onValueChanged:AddListener(function()
    page:_OnScrollRectChange(page)
  end)
end

function TowerTreeProcess:showCopyInfo(page)
  local widgets = page:GetWidgets()
  local buffDes = Logic.towerLogic:GetAllBuffDes()
  UIHelper.CreateSubPart(widgets.tx_buff, widgets.content_buff, #buffDes, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_buff, buffDes[index])
  end)
  widgets.buff.gameObject:SetActive(0 < #buffDes)
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

function TowerTreeProcess:_OnScrollRectChange(page, vec2, isOnOpen, isJump)
  for index, tabPart in ipairs(page.tabPartNew) do
    for indexSub, tabPartSub in ipairs(tabPart) do
      page:_OnScrollRectChangeSub(index, tabPartSub, isOnOpen, isJump, indexSub)
    end
  end
end

function TowerTreeProcess:_OnScrollRectChangeSub(page, tabPart, scale, index, indexSub)
  local copyInfo = page.copyTbl[index][indexSub]
  local towerCopyType = copyInfo.towerCopyType
  local flag = scale < zoom_max_disappear_end and scale > zoom_min_disappear
  local copyId = copyInfo.copyId
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  local state = self:GetCopyState(page, index, copyId, indexSub)
  local isClear = state == TowerCopyState.Clear
  isClear = isClear and flag
  local isAttack = state == TowerCopyState.Attack
  isAttack = isAttack and flag
  local isAbandon = state == TowerCopyState.Abandon
  isAbandon = isAbandon and flag
  local isAttackOrAbandon = state == TowerCopyState.Attack or state == TowerCopyState.Abandon
  isAttackOrAbandon = isAttackOrAbandon and flag
  local isAttackOrClear = state == TowerCopyState.Attack or state == TowerCopyState.Clear
  isAttackOrClear = isAttackOrClear and flag
  local isBoss = towerCopyType == TowerCopyType.Boss
  local isLittleBoss = towerCopyType == TowerCopyType.LittleBoss
  local boss_luapart = tabPart.boss_luapart:GetLuaTableParts()
  boss_luapart.im_diban:SetActive(isAttackOrAbandon and isBoss)
  boss_luapart.im_dingceng:SetActive(isAttack and isBoss)
  boss_luapart.im_bossname:SetActive(isAttack and isBoss)
  boss_luapart.other:SetActive(isAttack and isBoss)
  boss_luapart.im_icon_boss.enabled = isAttack and isBoss
  boss_luapart.im_icon_clear.gameObject:SetActive(isClear and isBoss)
  boss_luapart.im_now:SetActive(isAttack and isBoss)
  boss_luapart.notAbandon:SetActive(isAttackOrClear and isBoss)
  local littleboss_luapart = tabPart.littleboss_luapart:GetLuaTableParts()
  littleboss_luapart.im_diban:SetActive(isAttackOrAbandon and isLittleBoss)
  littleboss_luapart.im_dingceng:SetActive(isAttack and isLittleBoss)
  littleboss_luapart.im_littlebossname:SetActive(isAttack and isLittleBoss)
  littleboss_luapart.im_icon.enabled = isAttack and isLittleBoss
  littleboss_luapart.im_icon_clear.gameObject:SetActive(isClear and isLittleBoss)
  littleboss_luapart.im_now:SetActive(false)
  local buff_luapart = tabPart.buff:GetLuaTableParts()
  buff_luapart.gameObject:SetActive(isBuff)
  buff_luapart.clear:SetActive(isClear and isBuff)
  buff_luapart.attack:SetActive(isAttackOrClear and isBuff)
  buff_luapart.name:SetActive(isAttack and isBuff)
  buff_luapart.tx_buff.gameObject:SetActive(isAttack and isBuff)
  buff_luapart.abandon:SetActive(isAbandon and isBuff)
  tabPart.boss_anim.enabled = isAttack and towerCopyType == TowerCopyType.Boss
  tabPart.littleboss_anim.enabled = isAttack and towerCopyType == TowerCopyType.LittleBoss
  tabPart.littleboss_xian_anim.enabled = isAttack and towerCopyType == TowerCopyType.LittleBoss
  local pos = tabPart.im_levelcopy.transform.position
  local copys = page.tabPartNew[index]
  local offset = page.posTreeTable[#copys][indexSub]
  tabPart.trans.localPosition = Vector3.New(offset_x + offset.x * scale, pos.y + offset.y, pos.z)
end

function TowerTreeProcess:_drawLine(page, index, scale, alpha)
  if 1 < index and 0 < alpha then
    local scalPre = page.zoomTbl[index - 1]
    local copyList = page.copyTbl[index]
    local copyMap = Data.towerData:GetCopyMap()
    local lineIndex = 1
    for k, v in ipairs(copyList) do
      if copyMap[v.copyId] then
        lineIndex = k
      end
    end
    local copysNow = page.tabPartNew[index]
    local copysPre = page.tabPartNew[index - 1]
    local dst = copysNow[lineIndex].pos_rect.position
    for indexSub = 1, #copysPre do
      local src = copysPre[indexSub].pos_rect.position
      if src.y <= line_max_global_y and src.y >= line_mim_global_y then
        local tbl = page.posTreeTable[#copysPre][indexSub]
        if tbl.x_os then
          local x_sum = 0
          for i, v in ipairs(tbl.x_os) do
            x_sum = x_sum + copysPre[v].pos_rect.position.x
          end
          local _y = copysPre[tbl.y_os[1]].pos_rect.position.y
          local y = dst.y + (_y - dst.y) * tbl.y_os[2]
          local mid = Vector3.New(x_sum * 1.0 / 2, y, 0)
          page:drawLine(src, mid)
          page:drawLine(dst, mid)
        else
          page:drawLine(dst, src)
        end
      end
    end
  end
end

function TowerTreeProcess:IsClear(page, index, copyId)
  local copyList = Data.towerData:GetCopyList()
  for i, v in ipairs(copyList) do
    if v == copyId then
      return true
    end
  end
  return false
end

function TowerTreeProcess:showCopyInfoSub(page, index, tabPart, copyInfo, indexSub)
  local copyId = copyInfo.copyId
  local towerCopyType = copyInfo.towerCopyType
  local copyConfig = configManager.GetDataById("config_copy_display", copyId)
  local isBuff = copyConfig.pskill_id > 0 or 0 < #copyConfig.special_buff
  local copyData = Data.copyData:GetCopyInfoById(copyId)
  local boss_luapart = tabPart.boss_luapart:GetLuaTableParts()
  UIHelper.SetImage(boss_luapart.im_icon_clear, copyConfig.copy_thumbnail_after, true)
  local littleboss_luapart = tabPart.littleboss_luapart:GetLuaTableParts()
  UIHelper.SetImage(littleboss_luapart.im_icon_clear, copyConfig.copy_thumbnail_after, true)
  local buff_luapart = tabPart.buff:GetLuaTableParts()
  if isBuff then
    UIHelper.SetText(buff_luapart.tx_name, copyConfig.name)
  else
    UIHelper.SetText(tabPart.tx_name, copyConfig.copy_index .. " " .. copyConfig.name)
    UIHelper.SetText(tabPart.tx_name_boss, copyConfig.copy_index .. " " .. copyConfig.name)
  end
  UIHelper.SetImage(tabPart.im_icon, copyConfig.copy_thumbnail_before, true)
  UIHelper.SetImage(tabPart.icon_boss, copyConfig.copy_thumbnail_before, true)
  local state = self:GetCopyState(page, index, copyId, indexSub)
  local isClear = state == TowerCopyState.Clear
  boss_luapart.im_icon_revive.gameObject:SetActive(copyConfig.revive_icon_before ~= "" and not isClear)
  littleboss_luapart.im_icon_revive.gameObject:SetActive(copyConfig.revive_icon_before ~= "" and not isClear)
  boss_luapart.im_icon_revive_clear.gameObject:SetActive(copyConfig.revive_icon_after ~= "" and isClear)
  littleboss_luapart.im_icon_revive_clear.gameObject:SetActive(copyConfig.revive_icon_after ~= "" and isClear)
  if state == TowerCopyState.Attack then
    UGUIEventListener.AddButtonOnClick(tabPart.btn_boss, page.bu_copy, page, copyId)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_littleboss, page.bu_copy, page, copyId)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_buff, page.bu_copy, page, copyId)
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
  tabPart.boss:SetActive(towerCopyType == TowerCopyType.Boss)
  tabPart.littleboss:SetActive(towerCopyType == TowerCopyType.LittleBoss)
  buff_luapart.gameObject:SetActive(towerCopyType == TowerCopyType.Buff)
  local hp = AllLBPoint
  if copyData then
    hp = AllLBPoint - copyData.LBPoint
  end
  UIHelper.SetText(tabPart.tx_hp, math.ceil(100 * hp / AllLBPoint) .. "%")
  tabPart.tx_hp.gameObject:SetActive(towerCopyType == TowerCopyType.Boss)
  tabPart.im_bosshp.fillAmount = hp / AllLBPoint
end

function TowerTreeProcess:GetCopyState(page, index, copyId, indexSub)
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

function TowerTreeProcess:IsDeadRoad(page)
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

function TowerTreeProcess:GetOffSet(page, index, indexSub)
  local copys = page.tabPartNew[index]
  local offset = page.posTreeTable[#copys][indexSub]
  return offset.y
end

function TowerTreeProcess:GetTowerCopyType(themeConfig, copyId)
  local bossMap = {}
  for i, v in ipairs(themeConfig.area_final_copy) do
    for iSub, vSub in ipairs(v) do
      bossMap[vSub] = true
    end
  end
  local copyBranchConfig = configManager.GetDataById("config_copy_display", copyId)
  local isBuff = copyBranchConfig.pskill_id > 0 or 0 < #copyBranchConfig.special_buff
  local isBoss = bossMap[copyId]
  local towerCopyType
  if isBoss then
    towerCopyType = TowerCopyType.Boss
  elseif isBuff then
    towerCopyType = TowerCopyType.Buff
  else
    towerCopyType = TowerCopyType.LittleBoss
  end
  return towerCopyType
end

function TowerTreeProcess:bu_copy(page, copyId)
  local isNotDeadRoad = Logic.towerLogic:IsNotDeadRoad()
  local result = Logic.towerLogic:CheckAvailable(copyId)
  if isNotDeadRoad and not result then
    local tabParams = {
      msgType = NoticeType.TwoButton,
      callback = function(bool)
        if bool then
          Logic.towerLogic:CopyClick(copyId)
        end
      end
    }
    local tips = string.format(UIHelper.GetString(1703006), str)
    noticeManager:ShowMsgBox(tips, tabParams)
  else
    Logic.towerLogic:CopyClick(copyId)
  end
end

return TowerTreeProcess
