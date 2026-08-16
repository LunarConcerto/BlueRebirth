local gccount = 0
local SearchGoodsLoginPage = class("UI.Activity.SearchGoodsLoginPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function SearchGoodsLoginPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.isShowSG = false
end

function SearchGoodsLoginPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_help, self.ClickHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_search, self.ClickOpenSearch, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_searchClose, self.ClickCloseSearch, self)
  UGUIEventListener.AddOnDrag(self.tab_Widgets.img_searchgroup, self.__OnDrag, self)
  self:RegisterEvent(LuaEvent.UpdateSearchGoodsInfo, self._UpdateInfo, self)
  self:RegisterEvent(LuaEvent.GetTaskReward, self._OnGetReward, self)
end

function SearchGoodsLoginPage:DoOnOpen()
  local params = self:GetParam()
  self.activityId = params.activityId
  self.activityCfg = configManager.GetDataById("config_activity", self.activityId)
  local Idata = Data.searchGoodsData:GetIsUpdate()
  if not Idata then
    if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
      noticeManager:OpenTipPage(self, UIHelper.GetString(270022))
    else
      Service.searchGoodsService:SendRefresh()
    end
  else
    self:_ShowPage()
  end
  self:__RegisterModeBInput()
end

function SearchGoodsLoginPage:_ShowPage(param)
  self:_ShowLoginTask()
  self:_ShowSearchInfo(param)
end

function SearchGoodsLoginPage:_UpdateInfo(param)
  if param and param.Last == true and self.sortTaskInfo then
    local rewardId = self.sortTaskInfo[param.TeamId].Config.rewards
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    Logic.rewardLogic:ShowCommonReward(rewards, "SearchGoodsLoginPage")
  end
  self:_ShowPage(param)
end

function SearchGoodsLoginPage:_ShowLoginTask()
  local widgets = self:GetWidgets()
  local bgList = self.activityCfg.p1
  local tabTaskInfo = Logic.taskLogic:GetAllTaskListByType(TaskType.Activity, self.activityId)
  if tabTaskInfo == nil then
    logError("SearchGoodsLoginPage _ShowTasks tabTaskInfo is nil")
    return
  end
  table.sort(tabTaskInfo, function(data1, data2)
    return data1.TaskId < data2.TaskId
  end)
  local sortTaskInfo = tabTaskInfo
  local len = #sortTaskInfo
  self.sortTaskInfo = sortTaskInfo
  UIHelper.CreateSubPart(widgets.objDay, widgets.contentDay, len, function(index, tabPart)
    local iconBg = bgList[index]
    UIHelper.SetImage(tabPart.img_bg_day, iconBg)
    local title = sortTaskInfo[index].Config.desc
    local rewardId = sortTaskInfo[index].Config.rewards
    local rewards = Logic.rewardLogic:FormatRewardById(rewardId)
    local reward = rewards[1]
    local typ = reward.Type
    local id = reward.ConfigId
    local num = reward.Num
    local icon = Logic.goodsLogic:GetIcon(id, typ)
    local name = Logic.goodsLogic:GetName(id, typ)
    local quality = Logic.goodsLogic:GetQuality(id, typ)
    local status = sortTaskInfo[index].State
    UIHelper.SetText(tabPart.tx_name_todo, name)
    UIHelper.SetText(tabPart.tx_num_todo, "x" .. num)
    UIHelper.SetImage(tabPart.img_icon_todo, icon)
    UIHelper.SetText(tabPart.tx_name_fetch, name)
    UIHelper.SetText(tabPart.tx_num_fetch, "x" .. num)
    UIHelper.SetImage(tabPart.img_icon_fetch, icon)
    UIHelper.SetText(tabPart.tx_name_fetched, name)
    UIHelper.SetText(tabPart.tx_num_fetched, "x" .. num)
    UIHelper.SetImage(tabPart.img_icon_fetched, icon)
    UIHelper.SetImageByQuality(tabPart.img_quality_todo, quality)
    UIHelper.SetImageByQuality(tabPart.img_quality_fetch, quality)
    UIHelper.SetImageByQuality(tabPart.img_quality_fetched, quality)
    UIHelper.SetText(tabPart.tx_day_todo, title)
    UIHelper.SetText(tabPart.tx_day_fetch, title)
    UIHelper.SetText(tabPart.tx_day_fetched, title)
    tabPart.todo:SetActive(status == TaskState.TODO)
    tabPart.fetch:SetActive(status == TaskState.FINISH)
    tabPart.fetched:SetActive(status == TaskState.RECEIVED)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item_todo, self.btnItem, self, reward)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item_fetch, self.btnFetch, self, sortTaskInfo[index])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_item_fetched, self.btnItem, self, reward)
    UGUIEventListener.AddButtonOnClick(tabPart.btnFetch, self.btnFetch, self, sortTaskInfo[index])
  end)
end

function SearchGoodsLoginPage:btnItem(go, award)
  if award.Type == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award.ConfigId,
      showEquipType = ShowEquipType.Simple
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award.Type, award.ConfigId))
  end
end

function SearchGoodsLoginPage:btnFetch(go, args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function SearchGoodsLoginPage:_ShowSearchInfo(param)
  local widgets = self:GetWidgets()
  self.curTeam = Data.searchGoodsData:GetCurTeamId()
  self.receiveTime = Data.searchGoodsData:GetLastReceiveTime()
  self.searchInfo = Data.searchGoodsData:GetSearchMap()
  local searchInfo = self.searchInfo
  local mainBgList = self.activityCfg.p2
  local goodsAllList = self.activityCfg.p5
  local stateBg = self.activityCfg.p3
  local mainBg = mainBgList[self.curTeam]
  local goodsDayList = goodsAllList[self.curTeam]
  local isSameDay = time.isSameDay(self.receiveTime, time.getSvrTime())
  local bgClose = isSameDay or self.curTeam > #mainBgList
  self.tab_Widgets.im_search.gameObject:SetActive(not bgClose)
  self.tab_Widgets.im_finish.gameObject:SetActive(bgClose)
  widgets.obj_searchgroup.gameObject:SetActive(self.isShowSG)
  if not self.isShowSG then
    return
  end
  if isSameDay then
    mainBg = mainBgList[self.curTeam - 1]
    goodsDayList = goodsAllList[self.curTeam - 1]
    for _, v in pairs(goodsDayList) do
      searchInfo[v] = 1
    end
  elseif self.curTeam > #mainBgList then
    mainBg = mainBgList[#mainBgList]
    goodsDayList = goodsAllList[#mainBgList]
    for _, v in pairs(goodsDayList) do
      searchInfo[v] = 1
    end
  end
  UIHelper.SetImage(widgets.im_mainBg, mainBg, true)
  Logic.searchGoodsLogic:CheckAndSetScale(self.tab_Widgets.im_mainBg, self.tab_Widgets.trans_mainBg)
  Logic.searchGoodsLogic:SetDeviation(self.tab_Widgets.im_mainBg, self.tab_Widgets.trans_mainBg)
  UIHelper.CreateSubPart(widgets.item_searchItem, widgets.trans_mainBg, #goodsDayList, function(index, tabPart)
    local id = goodsDayList[index]
    local config = configManager.GetDataById("config_search_goods_login", id)
    local positions = config.position
    tabPart.item.transform.anchoredPosition = Vector2.New(positions[1], positions[2])
    local tweenbg = tabPart.tweenScale
    tweenbg.gameObject:SetActive(false)
    UIHelper.SetImage(tabPart.img_searchItem, config.icon)
    if searchInfo[id] ~= nil then
      tabPart.item:SetActive(false)
    else
      tabPart.item:SetActive(true)
      UGUIEventListener.AddButtonOnClick(tabPart.btn_searchItem, function()
        if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
          noticeManager:ShowTipById(270022)
          return
        end
        tweenbg:SetOnFinished(function()
          tabPart.item:SetActive(false)
          tweenbg:ResetToBeginning()
          local isLast = self:CheckLast(goodsDayList, id, self.searchInfo)
          local tab = {
            TeamId = self.curTeam,
            ItemId = id
          }
          local param = {
            TeamId = self.curTeam,
            ItemId = id,
            Last = isLast
          }
          Service.searchGoodsService:FindItem(tab, param)
        end)
        tweenbg.gameObject:SetActive(true)
        tweenbg:Play(true)
      end)
    end
  end)
  UIHelper.CreateSubPart(widgets.item_target, widgets.trans_target, #goodsDayList, function(index, tabPart)
    local id = goodsDayList[index]
    local config = configManager.GetDataById("config_search_goods_login", id)
    UIHelper.SetImage(tabPart.im_target_icon, config.icon)
    if searchInfo[id] ~= nil then
      UIHelper.SetImage(tabPart.im_target_bg, stateBg[2])
      tabPart.im_yiwancheng.gameObject:SetActive(true)
      if param ~= nil and id == param.ItemId then
        tabPart.tween_yiwancheng:Play(true)
      end
    else
      UIHelper.SetImage(tabPart.im_target_bg, stateBg[1])
      tabPart.im_yiwancheng.gameObject:SetActive(false)
    end
  end)
end

function SearchGoodsLoginPage:CheckLast(goodsDayList, id, searchInfo)
  for i, v in ipairs(goodsDayList) do
    if searchInfo[v] == nil and id ~= v then
      return false
    end
  end
  return true
end

function SearchGoodsLoginPage:__OnDrag(go, eventData)
  self.m_isDrag = true
  self:__On2DDragCheck(go, eventData)
end

function SearchGoodsLoginPage:__On2DDragCheck(go, eventData)
  Logic.searchGoodsLogic:GirlDrag2D(go, eventData, self.tab_Widgets.im_mainBg.transform, self.tab_Widgets.im_mainBg, self.tab_Widgets.trans_mainBg)
end

function SearchGoodsLoginPage:__CheckGC()
  gccount = gccount + 1
  if 20 < gccount then
    gccount = 0
    collectgarbage("collect")
  end
end

function SearchGoodsLoginPage:__RegisterModeBInput()
  local tabParam = {
    zoom = function(param)
      self:__OnModeBZoom(param)
    end
  }
  inputManager:RegisterInput(self, tabParam)
end

function SearchGoodsLoginPage:__OnModeBZoom(delta)
  Logic.searchGoodsLogic:GirlPinch2D(delta, self.tab_Widgets.im_mainBg.transform, self.tab_Widgets.im_mainBg, self.tab_Widgets.trans_mainBg)
end

function SearchGoodsLoginPage:ClickHelp()
  UIHelper.OpenPage("HelpPage", {
    content = self.activityCfg.p6[1]
  })
end

function SearchGoodsLoginPage:ClickOpenSearch()
  if not self.isShowSG then
    self.isShowSG = true
    self:_ShowPage()
  end
end

function SearchGoodsLoginPage:ClickCloseSearch()
  if self.isShowSG then
    self.isShowSG = false
    self:_ShowPage()
  end
end

function SearchGoodsLoginPage:_GetRewards(args)
  if not Logic.activityLogic:CheckActivityOpenById(self.activityId) then
    noticeManager:ShowTipById(270022)
    return
  end
  Service.taskService:SendTaskReward(args.TaskId, args.Data.Type)
end

function SearchGoodsLoginPage:_OnGetReward(args)
  Logic.rewardLogic:ShowCommonReward(args.Rewards, "SearchGoodsLoginPage")
  self:_ShowPage()
end

function SearchGoodsLoginPage:DoOnHide()
end

function SearchGoodsLoginPage:DoOnClose()
  inputManager:UnregisterAllInput(self)
end

return SearchGoodsLoginPage
