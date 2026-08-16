local NewPlayerPage = class("UI.Activity.NewPlayerPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local TaskOperate = require("ui.page.task.TaskOperate")

function NewPlayerPage:DoInit()
  self.userInfo = {}
  self.achieveData = {}
  self.dayNum = 1
  self.curDay = 1
end

function NewPlayerPage:DoOnOpen()
  self.userInfo = Data.userData:GetUserData()
  local tabContentInfo = configManager.GetData("config_days_activity")
  self.achieveData = Data.taskData:GetAchieveData()
  self.curDay = self.userInfo.NewTaskStage
  self.dayNum = self.userInfo.NewTaskStage
  local tabContentInfo = configManager.GetData("config_days_activity")
  if self.curDay > #tabContentInfo then
    self.curDay = #tabContentInfo
  end
  self:_LoadDayNum()
  local index
  local toggleIndex = Logic.achieveLogic:GetNewPlayerToggle()
  if toggleIndex == nil then
    index = self.curDay
  else
    index = toggleIndex
  end
  Logic.achieveLogic:SetAchieveDay(index)
  self:_ShowDayInfo(self, tabContentInfo[index])
  UIHelper.SetImage(self.tab_Widgets.im_girl, tabContentInfo[index].picture)
  UIHelper.SetImage(self.tab_Widgets.im_des, tabContentInfo[index].description)
  self.timer = self:CreateTimer(function()
    self.tab_Widgets.ScrollbarVer.value = 1
  end, 0.1, 1, false)
  self:StartTimer(self.timer)
  self.userData = Data.userData:GetUserData()
  Logic.activityLogic:SetDaysActivity(false)
  eventManager:SendEvent(LuaEvent.SelfReddotCallBack)
end

function NewPlayerPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_loginGet, self._ClickLoginGet, self)
  self:RegisterEvent(LuaEvent.GetNewPlayerReward, self._OnGetReward, self)
  self:RegisterEvent(LuaEvent.UpdataTaskList, self._OnUpdataTaskList, self)
end

function NewPlayerPage:_OnUpdataTaskList(args)
  local tabContentInfo = configManager.GetData("config_days_activity")
  local selectTog = Logic.achieveLogic:GetAchieveDay()
  self:_ShowDayInfo(self, tabContentInfo[selectTog])
end

function NewPlayerPage:_OnGetReward(args)
  for v, k in pairs(args) do
    Logic.rewardLogic:ShowCommonReward(k, "NewPlayerPage", nil)
  end
  local tabContentInfo = configManager.GetData("config_days_activity")
  local selectTog = Logic.achieveLogic:GetAchieveDay()
  self.achieveData = Data.taskData:GetAchieveData()
  stage = Data.userData:GetUserData().NewTaskStage
  if self.curDay ~= stage and stage <= #tabContentInfo then
    self.curDay = stage
    selectTog = stage
    self:_LoadDayNum()
  end
  self:_ShowDayInfo(self, tabContentInfo[selectTog])
end

function NewPlayerPage:_LoadDayNum()
  self.tabPartInfo = {}
  local tabContentInfo = configManager.GetData("config_days_activity")
  UIHelper.CreateSubPart(self.tab_Widgets.obj_dayItem, self.tab_Widgets.trans_dayItem, #tabContentInfo, function(index, tabPart)
    self:RegisterRedDot(tabPart.red_Dot, tabContentInfo[index].id)
    table.insert(self.tabPartInfo, tabPart)
    local str = tabContentInfo[index].name
    tabPart.tx_dayNum.text = str
    tabPart.tx_selected_dayNum.text = str
    UIHelper.SetImage(tabPart.im_numIcon, tabContentInfo[index].icon)
    if index <= self.userInfo.NewTaskStage then
      tabPart.im_over:SetActive(false)
    else
      tabPart.im_over:SetActive(true)
    end
    tabPart.tx_num.gameObject:SetActive(tabContentInfo[index].count ~= 0)
    UIHelper.SetImage(tabPart.im_quality, tabContentInfo[index].bg)
    UIHelper.SetText(tabPart.tx_num, tabContentInfo[index].count)
    if index <= self.userInfo.NewTaskStage then
      UGUIEventListener.AddButtonOnClick(tabPart.btn_day, function()
        self:_ShowDayInfo(self, tabContentInfo[index])
      end)
    else
      UGUIEventListener.AddButtonOnClick(tabPart.btn_day, function()
        noticeManager:OpenTipPage(self, UIHelper.GetString(800004))
      end)
    end
  end)
end

function NewPlayerPage:_ShowDayInfo(go, award)
  self:StopTimer(self.timer)
  self.timer = self:CreateTimer(function()
    self.tab_Widgets.ScrollbarVer.value = 1
  end, 0.1, 1, false)
  self:StartTimer(self.timer)
  Logic.achieveLogic:SetNewPlayerToggle(award.id)
  local tabContentInfo = configManager.GetData("config_days_activity")
  for v, k in pairs(self.tabPartInfo) do
    if v == award.id then
      k.tx_selected_dayNum.gameObject:SetActive(true)
      k.tx_dayNum.gameObject:SetActive(false)
      k.tx_outLine.effectColor = Color.New(tabContentInfo[v].outlinecolor[1] / 255, tabContentInfo[v].outlinecolor[2] / 255, tabContentInfo[v].outlinecolor[3] / 255, tabContentInfo[v].outlinecolor[4] / 255)
      k.im_selete.gameObject:SetActive(true)
      k.obj_canvas.overrideSorting = true
      UIHelper.SetImage(k.im_selete, tabContentInfo[v].selected)
    else
      k.tx_selected_dayNum.gameObject:SetActive(false)
      k.tx_dayNum.gameObject:SetActive(true)
      k.obj_canvas.overrideSorting = false
      k.tx_outLine.effectColor = Color.New(0, 0, 0, 0)
      k.im_selete.gameObject:SetActive(false)
    end
  end
  self.dayNum = award.id
  local loginInfo = configManager.GetDataById("config_achievement", award.login_achievements)
  local tabContentInfo = configManager.GetData("config_days_activity")
  Logic.achieveLogic:SetAchieveDay(self.dayNum)
  UIHelper.SetImage(self.tab_Widgets.im_girl, tabContentInfo[self.dayNum].picture)
  UIHelper.SetImage(self.tab_Widgets.im_des, tabContentInfo[self.dayNum].description)
  self:_LoadLoginReward(loginInfo.rewards)
  self:_LoadItemInfo(award)
end

function NewPlayerPage:_refreshGoods()
  for gridId, tabPart in pairs(self.goods) do
    local goodData = Logic.shopLogic:GetGoodDataById(ShopId.Days, gridId)
    tabPart.btn_get.gameObject:SetActive(self.curDay >= self.dayNum and goodData.Num == 0)
    tabPart.btn_fetched.gameObject:SetActive(goodData.Num > 0)
  end
end

function NewPlayerPage:_LoadGoods(shopId, goods)
  self.goods = {}
  UIHelper.CreateSubPart(self.tab_Widgets.obj_gift, self.tab_Widgets.trans_gift, #goods, function(index, tabPart)
    local gridId = goods[index]
    self.goods[gridId] = tabPart
    local goodData = Logic.shopLogic:GetGoodDataById(shopId, gridId)
    local goodId = goodData.GoodsId
    local goodConfig = configManager.GetDataById("config_shop_goods", goodId)
    local goodsInfo = Logic.bagLogic:GetItemByTempateId(goodConfig.goods[1], goodConfig.goods[2])
    UIHelper.SetImage(tabPart.im_loginIcon, goodsInfo.icon)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[goodsInfo.quality])
    local curIcon = Logic.currencyLogic:GetSmallIcon(goodConfig.price2[1][2])
    UIHelper.SetImage(tabPart.img_cur_origin, curIcon)
    UIHelper.SetImage(tabPart.img_cur_now, curIcon)
    UIHelper.SetText(tabPart.tx_rewardNum, "x" .. goodConfig.goods[3])
    UIHelper.SetText(tabPart.tx_price_origin, goodConfig.price2[1][4])
    UIHelper.SetText(tabPart.tx_price_now, goodConfig.price2[1][3])
    UGUIEventListener.AddButtonOnClick(tabPart.im_loginIcon, function()
      UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(goodConfig.goods[1], goodConfig.goods[2]))
    end)
    tabPart.btn_get.gameObject:SetActive(self.curDay >= self.dayNum and goodData.Num == 0)
    tabPart.btn_fetched.gameObject:SetActive(goodData.Num > 0)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_get, function()
      local tabParams = {
        msgType = NoticeType.TwoButton,
        callback = function(bool)
          if bool then
            local info = {
              goodData = goodConfig,
              shopId = ShopId.Days,
              buyNum = 1,
              goodId = goodId
            }
            Logic.shopLogic:BuyGoods(info)
          end
        end
      }
      local tips = string.format(UIHelper.GetString(800001), goodConfig.name)
      noticeManager:ShowMsgBox(tips, tabParams)
    end)
  end)
end

function NewPlayerPage:_LoadLoginReward(rewardId)
  local loginInfo = configManager.GetDataById("config_rewards", rewardId).rewards
  self.loginReward = {}
  self.loginReward = loginInfo
  UIHelper.CreateSubPart(self.tab_Widgets.obj_loginItem, self.tab_Widgets.trans_loginItem, #loginInfo, function(index, tabPart)
    local reward = {
      Type = loginInfo[index][1],
      Num = loginInfo[index][3],
      ConfigId = loginInfo[index][2]
    }
    local tabReward = Logic.goodsLogic.AnalyGoods(reward)
    UIHelper.SetImage(tabPart.im_loginIcon, tabReward.texIcon)
    UIHelper.SetImage(tabPart.im_quality, QualityIcon[tabReward.quality])
    UIHelper.SetText(tabPart.tx_rewardNum, "x" .. loginInfo[index][3])
    UGUIEventListener.AddButtonOnClick(tabPart.btn_look, self._ShowItemInfo, self, loginInfo[index])
  end)
  local args = configManager.GetDataById("config_days_activity", self.dayNum)
  local logintabReward = {}
  table.insert(logintabReward, args.login_achievements)
  local tabAchieve = Logic.achieveLogic:GetAchieveByDays(logintabReward, self.achieveData)
  if tabAchieve[1].status == TaskState.RECEIVED then
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330006)
    UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
  elseif tabAchieve[1].status == TaskState.TODO then
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330007)
    UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
  else
    self.tab_Widgets.tx_btn.text = UIHelper.GetString(330007)
    if self.curDay >= self.dayNum then
      UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_huang")
    else
      UIHelper.SetImage(self.tab_Widgets.im_loginAnniu, "uipic_ui_common_bu_fang_hui")
    end
  end
end

function NewPlayerPage:_ShowItemInfo(go, award)
  if award[1] == GoodsType.EQUIP then
    UIHelper.OpenPage("ShowEquipPage", {
      templateId = award[2],
      showEquipType = ShowEquipType.Simple,
      showDrop = false
    })
  else
    UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(award[1], award[2]))
  end
end

function NewPlayerPage:_LoadItemInfo(award)
  local tabAchieve = Logic.achieveLogic:GetAchieveByDays(award.achievements, self.achieveData)
  UIHelper.CreateSubPart(self.tab_Widgets.obj_itemInfo, self.tab_Widgets.trans_itemInfo, #tabAchieve, function(index, tabPart)
    UIHelper.SetText(tabPart.tx_des, tabAchieve[index].config.desc)
    UIHelper.SetText(tabPart.tx_num, tabAchieve[index].progressStr)
    if tabAchieve[index].status == TaskState.TODO then
      local isJump = TaskOperate.NewPlayerIsJump(tabAchieve[index].config.goal[1], tabAchieve[index].config.go_up_to)
      tabPart.btn_anniu.gameObject:SetActive(isJump)
      tabPart.tx_num.gameObject:SetActive(isJump)
    else
      tabPart.btn_anniu.gameObject:SetActive(true)
      tabPart.tx_num.gameObject:SetActive(true)
    end
    if tabAchieve[index].status == TaskState.RECEIVED then
      tabPart.im_anniu.gameObject:SetActive(false)
    end
    tabPart.tx_num.gameObject:SetActive(tabAchieve[index].config.progress == 1)
    tabPart.im_get.gameObject:SetActive(tabAchieve[index].status == TaskState.RECEIVED)
    if tabAchieve[index].status == TaskState.TODO then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(800005))
      UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_common_bu_fang_hui")
    elseif tabAchieve[index].status == TaskState.FINISH then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(330007))
      if self.dayNum <= self.userInfo.NewTaskStage then
        UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_common_bu_fang_huang")
      else
        UIHelper.SetImage(tabPart.im_anniu, "uipic_ui_common_bu_fang_hui")
      end
    elseif tabAchieve[index].status == TaskState.RECEIVED then
      UIHelper.SetText(tabPart.tx_btn, UIHelper.GetString(330006))
      tabPart.tx_num.gameObject:SetActive(false)
    end
    local reward = configManager.GetDataById("config_rewards", tabAchieve[index].config.rewards).rewards
    UIHelper.CreateSubPart(tabPart.obj_item, tabPart.trans_rewards, #reward, function(i, t)
      local tabReward = Logic.bagLogic:GetItemByTempateId(reward[i][1], reward[i][2])
      UIHelper.SetImage(t.im_icon, tabReward.icon)
      UIHelper.SetImage(t.im_quality, QualityIcon[tabReward.quality])
      UIHelper.SetText(t.tx_rewardNum, "x" .. reward[i][3])
      UGUIEventListener.AddButtonOnClick(t.btn_icon, self._ShowItemInfo, self, reward[i])
    end)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_anniu, self._NewPlayerCall, self, tabAchieve[index])
  end)
end

function NewPlayerPage:_NewPlayerCall(go, args)
  if args.status == TaskState.TODO then
    local isJump = TaskOperate.NewPlayerJumpByKind(args.config.go_up_to)
  elseif args.status == TaskState.FINISH then
    local name = configManager.GetDataById("config_days_activity", self.dayNum).name
    if self.dayNum <= self.userInfo.NewTaskStage then
      local dotinfo = {
        info = "ui_activity_task",
        achievement_id = args.achieveId
      }
      RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
      local reward = {
        TaskId = args.achieveId,
        TaskType = TaskType.Achieve,
        Day = self.dayNum
      }
      Service.taskService:SendTaskRewardDay(reward)
    else
      noticeManager:OpenTipPage(self, name .. "\231\153\187\229\189\149\229\174\140\230\136\144\228\187\187\229\138\161\229\143\175\233\162\134\229\143\150")
    end
  end
end

function NewPlayerPage:_ClickLoginGet()
  local args = configManager.GetDataById("config_days_activity", self.dayNum)
  local m_type = configManager.GetDataById("config_achievement", args.login_achievements)
  local tabReward = {}
  table.insert(tabReward, args.login_achievements)
  local tabAchieve = Logic.achieveLogic:GetAchieveByDays(tabReward, self.achieveData)
  if self.dayNum <= self.userInfo.NewTaskStage and tabAchieve[1].status == TaskState.FINISH then
    local reward = {
      TaskId = args.login_achievements,
      TaskType = TaskType.Achieve,
      Day = self.dayNum
    }
    Service.taskService:SendTaskRewardDay(reward)
    local dotinfo = {
      info = "ui_activity_login",
      day_id = self.dayNum
    }
    RetentionHelper.Retention(PlatformDotType.uilog, dotinfo)
  elseif tabAchieve[1].status == TaskState.RECEIVED then
    noticeManager:OpenTipPage(self, UIHelper.GetString(330006))
  else
    local name = configManager.GetDataById("config_days_activity", self.dayNum).name
    local str = string.format(UIHelper.GetString(800006), name)
    noticeManager:OpenTipPage(self, str)
  end
end

function NewPlayerPage:DoOnHide()
end

function NewPlayerPage:DoOnClose()
  Logic.achieveLogic:SetNewPlayerToggle(nil)
end

return NewPlayerPage
