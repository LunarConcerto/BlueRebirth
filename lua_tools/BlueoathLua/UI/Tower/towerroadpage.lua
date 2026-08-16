local TowerRoadPage = class("UI.Tower.TowerRoadPage", LuaUIPage)
local SoloProcess = require("ui.page.tower.TowerSoloProcess")
local MultiProcess = require("ui.page.tower.TowerMultiProcess")
local TreeProcess = require("ui.page.tower.TowerTreeProcess")
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local distance_vertical = UIManager:GetUIWidth() * 200 / 1334
local zoom_max_disappear_start = 1.35
local zoom_max_disappear_end = 1.39
local zoom_min_disappear = 0.06
local zoom_min_disappear_bottom = 2.576
local zoom_min_disappear_alpha = 0.85
local offset_x = 621
local offset_x_half = 310.5
local zoom_min_tile = 0.6
local camera_move_rate = 0.04
local line_disappear_rate_min = 0.3
local line_disappear_rate_max = 1.35
local perfect_rate = 1.056
local content_offset = 400
local sea_padding = 8 * UIManager:GetUIHeight() / 750

function TowerRoadPage:DoInit()
  self.tileTbl = {}
  self.tileIndex = 0
  self.tabPart = {}
  self.tabPartNew = {}
  Logic.towerLogic:SetTowerRoadPos(nil)
  self.posMultiTable = {
    [1] = {
      {x = 0, y = 0}
    },
    [2] = {
      {x = -200, y = 20},
      {x = 200, y = -20}
    },
    [3] = {
      {x = -200, y = 20},
      {x = 0, y = 0},
      {x = 200, y = -20}
    },
    [4] = {
      {x = -300, y = 20},
      {x = -100, y = 20},
      {x = 100, y = -20},
      {x = 300, y = -20}
    }
  }
  self.posTreeTable = {
    [1] = {
      {x = 0, y = 0}
    },
    [2] = {
      {x = -300, y = 0},
      {x = 300, y = 0}
    },
    [3] = {
      {x = -400, y = 0},
      {x = 0, y = 20},
      {x = 400, y = 0}
    },
    [4] = {
      {
        x = -400,
        y = 10,
        x_os = {1, 2},
        y_os = {2, 0.8}
      },
      {
        x = -200,
        y = -10,
        x_os = {1, 2},
        y_os = {2, 0.8}
      },
      {
        x = 200,
        y = 10,
        x_os = {3, 4},
        y_os = {4, 0.8}
      },
      {
        x = 400,
        y = -10,
        x_os = {3, 4},
        y_os = {4, 0.8}
      }
    }
  }
end

function TowerRoadPage:DoOnOpen()
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.TOWER
  })
  local towerData = Data.towerData:GetData() or {}
  self.towerData = towerData
  if towerData.ChapterId and towerData.ChapterId > 0 then
    self:_refresh(true)
  else
    Service.towerService:SendTowerInfo()
  end
  self:_CheckBindEquips()
end

function TowerRoadPage:showReward(rewards, boxIndex)
  local widgets = self:GetWidgets()
  local paramConfig = configManager.GetDataById("config_parameter", 221).arrValue
  UIHelper.SetImage(widgets.img_reward, paramConfig[boxIndex], true)
  UIHelper.CreateSubPart(widgets.obj_reward, widgets.ContentReward, #rewards, function(indexSub, tabPartSub)
    local reward = rewards[indexSub]
    local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
    UIHelper.SetText(tabPartSub.tx_num, reward.Num)
    UIHelper.SetImage(tabPartSub.img_icon, display.icon)
    UIHelper.SetImageByQuality(tabPartSub.img_quality, display.quality)
    UGUIEventListener.AddButtonOnClick(tabPartSub.btn_reward, self.btn_reward, self, reward)
  end)
end

function TowerRoadPage:_refresh(isOnOpen)
  local widgets = self:GetWidgets()
  local towerData = Data.towerData:GetData() or {}
  self.towerDataPre = self.towerData
  self.towerData = towerData
  self.chapterId = towerData.ChapterId
  self.areaIndex = towerData.AreaIndex + 1
  self.copyIndex = towerData.CopyIndex + 1
  self:SetProcess()
  self.process:RegisterScrollRectChange(self)
  self.times = towerData.DailyCount - towerData.DailyCountEx
  self.resetTime = towerData.ResetTime
  self:OpenTopPage("TowerRoadPage", 1, "\231\169\134\228\188\175\233\152\178\229\141\171\229\156\136", self, true)
  local chapterConfig = configManager.GetDataById("config_chapter", self.chapterId)
  local towerId = chapterConfig.relation_chapter_id
  local chapterTowerConfig = configManager.GetDataById("config_chapter_tower", towerId)
  self.chapterTowerConfig = chapterTowerConfig
  self.themeIndex = Logic.towerLogic:FormatThemeIndex(towerData.TopicIndex, #chapterTowerConfig.tower_topic)
  local themeId = chapterTowerConfig.tower_topic[self.themeIndex]
  local themeConfig = configManager.GetDataById("config_tower_topic", themeId)
  self.themeConfig = themeConfig
  local area_pass_reward = chapterTowerConfig.area_pass_reward
  local rewardIndex = Logic.towerLogic:GetRewardIndex()
  local isCopyMax = Logic.towerLogic:IsCopyMax()
  local isDeadRoad = self.process:IsDeadRoad(self)
  widgets.mask:SetActive(isCopyMax or isDeadRoad)
  widgets.dead_end:SetActive(isDeadRoad and not isCopyMax)
  widgets.max_end:SetActive(isCopyMax)
  widgets.next_reward:SetActive(not isCopyMax)
  widgets.bu_reset.gameObject:SetActive(not isCopyMax)
  local boxIndex = chapterTowerConfig.basic_reward > 0 and rewardIndex + 1 or rewardIndex
  if not isCopyMax then
    local rewardId = area_pass_reward[rewardIndex]
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    self:showReward(rewards, boxIndex)
  end
  self:ShowLeftTime()
  local timer = self:CreateTimer(function()
    if self.chapterId <= 0 then
      return
    end
    self:ShowLeftTime()
    local timeLeft = Logic.towerLogic:GetLeftTime()
    if timeLeft <= -2 then
      Service.towerService:SendTowerInfo()
      self:StopAllTimer()
    end
  end, 0.5, -1)
  self:StartTimer(timer)
  UIHelper.SetLocText(widgets.tx_times, 1700010, chapterTowerConfig.daily_battle_time - self.times)
  UIHelper.SetText(widgets.tx_level, chapterConfig.name)
  self.themeConfig = themeConfig
  if chapterTowerConfig.topic_visible == 1 then
    UIHelper.SetImage(widgets.im_theme, themeConfig.image)
    UIHelper.SetText(widgets.tx_theme, themeConfig.name)
  end
  widgets.obj_theme:SetActive(chapterTowerConfig.topic_visible == 1)
  widgets.bu_upgrade.gameObject:SetActive(Data.towerData:IsShowUpgrade())
  self.process:prepareCopyData(self)
  self.process:showCopyInfo(self)
  local rewardInfo = Data.towerData:GetRewardInfo()
  local rewardChapter = rewardInfo.ChapterId
  local isReset = Data.towerData:IsReset()
  local isNewLevel = Data.towerData:IsNewLevel()
  local timer = FrameTimer.New(function()
    self:_OnScrollRectChange(nil, isOnOpen, isReset or isNewLevel or not self.towerDataPre.ChapterId)
  end, 1, 1)
  timer:Start()
  if not GR.guideHub:isInGuide() then
    if rewardChapter then
      self:fetchReward(rewardInfo)
      Data.towerData:ResetRewardInfo()
    elseif Data.towerData:IsReset() then
      Logic.towerLogic:ShowTowerReset(self.chapterId)
    elseif Data.towerData:IsNewLevel() then
      UIHelper.OpenPage("TowerNewLevelPage")
      Data.towerData:ResetNewLevel()
    end
  end
  local heroIdList = Logic.towerLogic:GetHeroIdList(FleetType.Tower)
  if 0 < #heroIdList then
    UIHelper.OpenPage("TowerLockedPage", {
      fleetType = FleetType.Tower
    })
  end
  local heroIdList = Data.towerData:GetHeroIdList()
  if 0 < #heroIdList then
    Data.towerData:ResetHeroIdList()
  end
  Data.towerData:ResetValue()
end

function TowerRoadPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.bu_instruction, self.bu_instruction, self)
  UGUIEventListener.AddButtonOnPointDown(widgets.bu_instruction, self.bu_instruction_down, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_theme, self.bu_theme, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_reset, self.bu_reset, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_upgrade, self.bu_upgrade, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_reward, self.bu_reward, self)
  UGUIEventListener.AddButtonOnPointDown(widgets.bu_reward, self.bu_reward_down, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_shop, self.bu_shop, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_hide, self.bu_hide, self)
  UGUIEventListener.AddButtonOnClick(widgets.bu_map, self.bu_map, self)
  self:RegisterEvent(LuaEvent.UpdateTowerInfo, self._refresh, self)
  self:RegisterEvent(LuaEvent.TowerReceiveBuff, self._refresh, self)
  self:RegisterEvent(LuaEvent.TowerFetchReward, self.fetchReward, self)
end

function TowerRoadPage:bu_instruction()
  local widgets = self:GetWidgets()
  widgets.tween_instruction:Stop()
  widgets.tween_instruction.transform.localScale = Vector3.one
  UIHelper.OpenPage("TowerHelpPage")
end

function TowerRoadPage:bu_instruction_down()
  local widgets = self:GetWidgets()
  widgets.tween_instruction:ResetToBeginning()
  widgets.tween_instruction:Play(true)
end

function TowerRoadPage:bu_theme()
  UIHelper.OpenPage("TowerThemePage")
end

function TowerRoadPage:bu_reward_down()
  local widgets = self:GetWidgets()
  widgets.tween_reward:ResetToBeginning()
  widgets.tween_reward:Play(true)
end

function TowerRoadPage:bu_reward()
  local widgets = self:GetWidgets()
  widgets.tween_reward:Stop()
  widgets.tween_reward.transform.localScale = Vector3.one
  UIHelper.OpenPage("TowerRewardPage")
end

function TowerRoadPage:bu_reset()
  UIHelper.OpenPage("TowerResetPage")
end

function TowerRoadPage:bu_upgrade()
  local tabParams = {
    msgType = NoticeType.TwoButton,
    callback = function(bool)
      if bool then
        Service.towerService:SendUpgrade()
      end
    end
  }
  noticeManager:ShowMsgBox(1700060, tabParams)
end

function TowerRoadPage:bu_shop()
  UIHelper.OpenPage("ShopPage", {
    shopId = ShopId.Tower
  })
end

function TowerRoadPage:btn_reward(go, reward)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId))
end

function TowerRoadPage:bu_map()
  self:OpenSubPage(self.themeConfig.tower_map, {
    themeConfig = self.themeConfig,
    page = self
  })
end

function TowerRoadPage:bu_copy(go, copyId)
  self.process:bu_copy(self, copyId)
  local content = self.process:GetScrollContent(self)
  Logic.towerLogic:SetTowerRoadPos(content.transform.localPosition)
  Logic.copyLogic:SetEnterLevelInfo(true)
end

function TowerRoadPage:fetchReward(args)
  if not args then
    return
  end
  local callback = function()
    local towerData = Data.towerData:GetData()
    local chapterId = towerData.ChapterId
    if towerData.PassLastChapterId <= 0 then
      if Data.towerData:IsNewLevel() then
        UIHelper.OpenPage("TowerNewLevelPage")
        Data.towerData:ResetNewLevel()
      else
        Logic.towerLogic:ShowTowerReset(chapterId)
      end
    end
  end
  local effectIsOff = not args.Reward or #args.Reward <= 0
  UIHelper.OpenPage("GetRewardsPage", {
    Rewards = args.Reward,
    callBack = callback,
    RewardType = RewardType.TOWER,
    TowerInfo = args,
    effectIsOff = effectIsOff
  })
end

function TowerRoadPage:bu_hide()
  local widgets = self:GetWidgets()
  widgets.mask:SetActive(false)
end

function TowerRoadPage:_OnScrollRectChangeSub(index, tabPart, isOnOpen, isJump, indexSub)
  tabPart.obj_copy_boss:SetActive(true)
  local _y = self:_getSeaPosition()
  local length = _y / (zoom_min_disappear_bottom - zoom_min_disappear)
  local offSet = self.process:GetOffSet(self, index, indexSub)
  local pos_y = _y - UIManager.uiCamera:WorldToScreenPoint(tabPart.obj_level.transform.position).y * UIManager:GetUIHeight() / Screen.height + length * zoom_min_disappear - sea_padding - offSet
  local scale = pos_y / length
  tabPart.bu_copy.transform.localScale = Vector3.New(scale, scale, scale)
  tabPart.bili.transform.localScale = Vector3.New(scale, scale, scale)
  local alpha
  if scale < zoom_min_disappear then
    alpha = 0
  elseif scale <= 1 and scale >= zoom_min_disappear then
    alpha = zoom_min_disappear_alpha + (1 - zoom_min_disappear_alpha) * (scale - zoom_min_disappear) / (1 - zoom_min_disappear)
  elseif scale >= zoom_max_disappear_end then
    alpha = 0
    tabPart.bu_copy.transform.localScale = Vector3.New(0, 0, 0)
  elseif scale > zoom_max_disappear_start then
    alpha = (zoom_max_disappear_end - scale) / (zoom_max_disappear_end - zoom_max_disappear_start)
  else
    alpha = 1
  end
  tabPart.canvas_group.alpha = alpha
  self.zoomTbl[index] = scale
  self.process:_OnScrollRectChangeSub(self, tabPart, scale, index, indexSub)
  self.process:_drawLine(self, index, scale, alpha)
end

function TowerRoadPage:_OnScrollRectChange(vec2, isOnOpen, isJump)
  self.tileIndex = 0
  self.zoomTbl = {}
  local content = self.process:GetScrollContent(self)
  local pos_content = Logic.towerLogic:GetTowerRoadPos()
  if isOnOpen and pos_content then
    content.transform.localPosition = pos_content
  elseif isOnOpen or isJump then
    local _y = self:_getSeaPosition()
    local length = _y / (zoom_min_disappear_bottom - zoom_min_disappear)
    local perfect_point_y = length * (zoom_min_disappear_bottom - perfect_rate)
    local grid = self.process:GetGrid(self)
    local height = grid.cellSize.y
    local padding = grid.spacing.y
    local index = self.process:GetIndex(self)
    local now = UIManager:GetUIHeight() - (content_offset + (height + (height + padding) * (index - 1)))
    local offset = perfect_point_y - now
    pos_content = content.transform.localPosition
    content.transform.localPosition = Vector3.New(pos_content.x, offset, pos_content.z)
  end
  pos_content = content.transform.localPosition
  local pos_between = pos_content.y - self.pos.y
  eventManager:SendEvent(LuaEvent.TowerMove, pos_between * camera_move_rate)
  self.pos = pos_content
  self.process:_OnScrollRectChange(self, vec2, isOnOpen, isJump)
  self:tileRecycle()
end

function TowerRoadPage:tileRecycle()
  local num = #self.tileTbl
  if 0 < num then
    local index = self.tileIndex
    for i = index + 1, num do
      local tile = self.tileTbl[i]
      if tile then
        tile:SetActive(false)
      else
        logError("tile is nil. index:", i)
      end
    end
  end
end

function TowerRoadPage:_btnClose()
  for index, tile in ipairs(self.tileTbl) do
    GameObject.Destroy(tile)
  end
end

function TowerRoadPage:_getSeaPosition()
  local m_camera = Logic.towerLogic:GetTowerCamera()
  local cam = m_camera:GetCam()
  local startPoint = cam.transform.position
  startPoint.y = 0
  local viewDir = cam.transform.forward
  viewDir.y = 0
  viewDir = Vector3.Normalize(viewDir)
  local pos = startPoint + viewDir * cam.farClipPlane
  local result = m_camera:WorldToScreenPoint(pos)
  return result.y * UIManager:GetUIHeight() / Screen.height
end

function TowerRoadPage:DoOnClose()
  GR.cameraManager:destroyCamera(GameCameraType.TowerSceneCamera, true)
  eventManager:SendEvent(LuaEvent.HomeSwitchState, {
    HomeStateID.MAIN
  })
end

function TowerRoadPage:ShowLeftTime()
  local widgets = self:GetWidgets()
  local timeLeft = Logic.towerLogic:GetLeftTime()
  if timeLeft <= 0 then
    timeLeft = 0
  end
  local timeFormat = time.getTimeStringFontTwo(timeLeft)
  UIHelper.SetLocText(widgets.tx_left_time, 270020, timeFormat)
  UIHelper.SetLocText(widgets.tx_reopen, 1700027, timeFormat)
end

function TowerRoadPage:SetProcess()
  local typ = Logic.towerLogic:GetChapterType()
  if typ == TowerType.Solo then
    self.process = SoloProcess
  elseif typ == TowerType.Multi then
    self.process = TreeProcess
  end
end

function TowerRoadPage:drawLine(dst, src, index, indexSub)
  local widgets = self:GetWidgets()
  local vec = dst - src
  local dst1 = widgets.tileTrans:InverseTransformPoint(dst)
  local src1 = widgets.tileTrans:InverseTransformPoint(src)
  local distance = Vector3.Distance(dst1, src1)
  local tileWidth = widgets.rec_tile.rect.width
  local num = math.ceil(distance / tileWidth)
  for i = 1, num do
    local tile
    if self.tileIndex < #self.tileTbl then
      self.tileIndex = self.tileIndex + 1
      tile = self.tileTbl[self.tileIndex]
    else
      tile = UIHelper.CreateGameObject(widgets.tile, widgets.tileTrans)
      table.insert(self.tileTbl, tile)
      self.tileIndex = self.tileIndex + 1
    end
    tile.transform.position = src + (dst - src) * (i - 0.4) / num
    tile:SetActive(true)
    local quaternion = Quaternion.FromToRotation(Vector3.right, vec)
    tile.transform.rotation = quaternion
  end
end

function TowerRoadPage:_CheckBindEquips()
  if Logic.towerLogic:IfNeedEquipTransplant(FleetType.Tower) then
    noticeManager:ShowMsgBox("\231\148\177\228\186\142\229\173\152\229\156\168\231\187\145\229\174\154\232\163\133\229\164\135\239\188\140\229\142\159\231\187\145\229\174\154\232\163\133\229\164\135\233\135\141\231\189\174")
  end
end

return TowerRoadPage
