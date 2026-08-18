local GatewaySignPage = class("UI.Copy.GatewaySignPage", LuaUIPage)
local ANGLE_SETOFF = 180
local ANGLE_Line = 90
local EnemyKuang = {
  [true] = "uipic_ui_gatewaysign_im_dahongquan",
  [false] = "uipic_ui_gatewaysign_im_xiaohongquan"
}

function GatewaySignPage:DoInit()
end

function GatewaySignPage:DoOnOpen()
  self.id = self:GetParam()
  self:_ShowContent()
end

function GatewaySignPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_closeGroup, self._ClickBeforeBack, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_close, self._ClickBeforeBack, self)
end

function GatewaySignPage:_ShowContent(...)
  local copydemoConfig = configManager.GetDataById("config_copy_demo", self.id)
  local enemy = copydemoConfig.ship_enemy_birth
  local scale = copydemoConfig.scale_value / 10000
  local playBirth = {}
  if copydemoConfig.battlefield_id == -1 then
    playBirth = configManager.GetDataById("config_scene_position", copydemoConfig.palyer_birth)
  else
    local battleInfo = configManager.GetDataById("config_battlefield_info", copydemoConfig.battlefield_id)
    playBirth = configManager.GetDataById("config_scene_position", battleInfo.player_position)
  end
  playBirth = self:_ChangeZuobiao(playBirth)
  self:_ShowPlayerContent(copydemoConfig, playBirth, scale)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_gateway, self.tab_Widgets.trans_gateway, #enemy, function(index, tabPart)
    local enemyInfo = enemy[index]
    local enemyData = {}
    if copydemoConfig.battlefield_id == -1 then
      enemyData = configManager.GetDataById("config_fleet", enemyInfo[1]).birth_sp_id
    else
      local battlefieldInfo = configManager.GetDataById("config_battlefield_info", copydemoConfig.battlefield_id).enemy_position
      enemyData = battlefieldInfo[index]
    end
    UIHelper.SetImage(tabPart.im_icon, GatewayBoss[index], true)
    UIHelper.SetImage(tabPart.im_kuang, EnemyKuang[index == 1], true)
    local positionInfo = configManager.GetDataById("config_scene_position", enemyData)
    positionInfo = self:_ChangeZuobiao(positionInfo)
    tabPart.im_kuang.transform.eulerAngles = Vector3.New(0, 0, positionInfo.eluer_y + ANGLE_SETOFF)
    tabPart.im_icon.transform.localPosition = Vector3.New(positionInfo.position_x * scale, positionInfo.position_z * scale, 0)
    tabPart.im_kuang.transform.localPosition = Vector3.New(positionInfo.position_x * scale, positionInfo.position_z * scale, 0)
    local length, angle
    if enemyInfo[2] == GatewayWalkType.One then
      length = math.sqrt((positionInfo.position_x * scale - playBirth.position_x * scale) ^ 2 + (positionInfo.position_z * scale - playBirth.position_z * scale) ^ 2)
      angle = math.atan(playBirth.position_z * scale - positionInfo.position_z * scale, playBirth.position_x * scale - positionInfo.position_x * scale) * 180 / math.pi
      local startX, startY = self:_GetRealPosition(tabPart.im_kuang, positionInfo, playBirth, length, scale)
      local endX, endY = self:_GetRealPosition(self.tab_Widgets.im_playerKuang, playBirth, positionInfo, length, scale)
      tabPart.im_line.transform.localPosition = Vector3.New(positionInfo.position_x * scale + startX, positionInfo.position_z * scale + startY, 0)
      length = math.sqrt((positionInfo.position_x * scale + startX - (playBirth.position_x * scale + endX)) ^ 2 + (positionInfo.position_z * scale + startY - (playBirth.position_z * scale + endY)) ^ 2)
      tabPart.rect_line.sizeDelta = Vector2.New(length, 16)
      tabPart.im_line.transform.eulerAngles = Vector3.New(0, 0, angle)
      UIHelper.SetText(tabPart.tx_line, "\231\177\187\229\158\1391 \231\154\132\230\128\170\231\137\169\232\183\175\229\190\132")
    elseif enemyInfo[2] == GatewayWalkType.Two then
      local size = tabPart.im_kuang.gameObject:GetComponent(RectTransform.GetClassType())
      tabPart.im_line.transform.eulerAngles = Vector3.New(0, 0, positionInfo.eluer_y + ANGLE_Line)
      local x = size.rect.height / 2 * math.cos((positionInfo.eluer_y + ANGLE_Line) * math.pi / 180)
      local y = size.rect.height / 2 * math.sin((positionInfo.eluer_y + ANGLE_Line) * math.pi / 180)
      tabPart.rect_line.sizeDelta = Vector2.New(90, 16)
      tabPart.im_line.transform.localPosition = Vector3.New(positionInfo.position_x * scale + x, positionInfo.position_z * scale + y, 0)
      UIHelper.SetText(tabPart.tx_line, "\231\177\187\229\158\1392 \231\154\132\230\128\170\231\137\169\232\183\175\229\190\132")
    elseif enemyInfo[2] == GatewayWalkType.There then
      local ship_enemy_path = copydemoConfig.ship_enemy_path
      tabPart.im_line.gameObject:SetActive(false)
      if #ship_enemy_path[index] == 0 then
        return
      end
      UIHelper.CreateSubPart(tabPart.objTwo_line, tabPart.trans_line, #ship_enemy_path[index] - 1, function(nIndex, inPart)
        local enemyStart = configManager.GetDataById("config_scene_position", ship_enemy_path[index][nIndex])
        local enemyEnd = configManager.GetDataById("config_scene_position", ship_enemy_path[index][nIndex + 1])
        enemyStart = self:_ChangeZuobiao(enemyStart)
        enemyEnd = self:_ChangeZuobiao(enemyEnd)
        length = math.sqrt((enemyStart.position_x * scale - enemyEnd.position_x * scale) ^ 2 + (enemyStart.position_z * scale - enemyEnd.position_z * scale) ^ 2)
        angle = math.atan(enemyEnd.position_z * scale - enemyStart.position_z * scale, enemyEnd.position_x * scale - enemyStart.position_x * scale) * 180 / math.pi
        local x = 0
        local y = 0
        if index == 1 then
          x, y = self:_GetRealPosition(tabPart.im_kuang, enemyStart, enemyEnd, length, scale)
          length = math.sqrt((enemyStart.position_x * scale + x - playerEnd.position_x * scale) ^ 2 + (enemyStart.position_z * scale + y - playerEnd.position_z * scale) ^ 2)
        end
        inPart.im_line.transform.localPosition = Vector3.New(enemyStart.position_x * scale + x, enemyStart.position_z * scale + y, 0)
        inPart.rect_line.sizeDelta = Vector2.New(length, 16)
        inPart.im_line.transform.eulerAngles = Vector3.New(0, 0, angle)
        UIHelper.SetText(inPart.tx_line, "\231\177\187\229\158\1393 \231\154\132\230\128\170\231\137\169\232\183\175\229\190\132")
      end)
    end
  end)
end

function GatewaySignPage:_ShowPlayerContent(copydemoConfig, playBirth, scale)
  local playerLineInfo = copydemoConfig.player_path
  self.tab_Widgets.im_playerIcon.transform.localPosition = Vector3.New(playBirth.position_x * scale, playBirth.position_z * scale, 0)
  self.tab_Widgets.im_playerKuang.transform.localPosition = Vector3.New(playBirth.position_x * scale, playBirth.position_z * scale, 0)
  self.tab_Widgets.im_playerKuang.transform.eulerAngles = Vector3.New(0, 0, playBirth.eluer_y + ANGLE_SETOFF)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_playerInfo, self.tab_Widgets.trans_playerInfo, #playerLineInfo, function(nIndex, inPart)
    local playerLine = playerLineInfo[nIndex]
    UIHelper.CreateSubPart(inPart.obj_playerLine, inPart.rect_playerInfo, #playerLine - 1, function(index, tabPart)
      local length, angle
      local playerStart = configManager.GetDataById("config_scene_position", playerLine[index])
      local playerEnd = configManager.GetDataById("config_scene_position", playerLine[index + 1])
      playerStart = self:_ChangeZuobiao(playerStart)
      playerEnd = self:_ChangeZuobiao(playerEnd)
      angle = math.atan(playerEnd.position_z * scale - playerStart.position_z * scale, playerEnd.position_x * scale - playerStart.position_x * scale) * 180 / math.pi
      length = math.sqrt((playerStart.position_x * scale - playerEnd.position_x * scale) ^ 2 + (playerStart.position_z * scale - playerEnd.position_z * scale) ^ 2)
      local x = 0
      local y = 0
      if index == 1 and nIndex == 1 then
        x, y = self:_GetRealPosition(self.tab_Widgets.im_playerKuang, playerStart, playerEnd, length, scale)
        length = math.sqrt((playerStart.position_x * scale + x - playerEnd.position_x * scale) ^ 2 + (playerStart.position_z * scale + y - playerEnd.position_z * scale) ^ 2)
      end
      tabPart.im_playerLine.transform.localPosition = Vector3.New(playerStart.position_x * scale + x, playerStart.position_z * scale + y, 0)
      tabPart.rect_playerLine.sizeDelta = Vector2.New(length, 16)
      tabPart.im_playerLine.transform.eulerAngles = Vector3.New(0, 0, angle)
      tabPart.im_playerLine.gameObject:SetActive(true)
      UIHelper.SetText(tabPart.tx_line, "\231\142\169\229\174\182\232\183\175\229\190\132")
    end)
  end)
end

function GatewaySignPage:_GetRealPosition(obj, start, End, length, scale)
  local size = obj.gameObject:GetComponent(RectTransform.GetClassType())
  local x = size.rect.height / 2 * (End.position_x * scale - start.position_x * scale) / length
  local y = size.rect.height / 2 * (End.position_z * scale - start.position_z * scale) / length
  return x, y
end

function GatewaySignPage:_ChangeZuobiao(position)
  local copydemoConfig = configManager.GetDataById("config_copy_demo", self.id)
  local realPositionInfo = configManager.GetDataById("config_scene_position", copydemoConfig.copy_center)
  local zb = {
    position_x = position.position_x - realPositionInfo.position_x,
    position_z = position.position_z - realPositionInfo.position_z,
    eluer_y = position.eluer_y
  }
  return zb
end

function GatewaySignPage:_ClickBeforeBack()
  UIHelper.ClosePage("GatewaySignPage")
end

function GatewaySignPage:DoOnHide()
end

function GatewaySignPage:DoOnClose()
end

return GatewaySignPage
