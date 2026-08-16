local TrainPage = class("UI.Train.TrainPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")

function TrainPage:DoInit()
end

function TrainPage:RegisterAllEvent()
end

function TrainPage:DoOnOpen()
  self:OpenTopPage("TrainPage", 1, UIHelper.GetString(1000002), self, true, function()
    UIHelper.OpenPage("HomePage")
    TrainPage.LastPosX = 0
  end)
  if TrainPage.LastPosX then
    local pos = self.tab_Widgets.content.anchoredPosition
    self.tab_Widgets.content.anchoredPosition = Vector3.New(TrainPage.LastPosX, pos.y, pos.z)
  end
  self:CloseRepeatPage()
  self:_CreateChapters()
end

function TrainPage:CloseRepeatPage()
  if UIHelper.IsExistPage("TrainLevelPage") then
    UIHelper.ClosePage("TrainLevelPage")
  end
  if UIHelper.IsExistPage("FleetPage") then
    UIHelper.ClosePage("FleetPage")
  end
  if UIHelper.IsExistPage("CommonHeroPage") then
    UIHelper.ClosePage("CommonHeroPage")
  end
  if UIHelper.IsExistPage("RepairePage") then
    UIHelper.ClosePage("RepairePage")
  end
end

function TrainPage:_CreateChapters()
  local chapters = Logic.copyLogic:GetTrainChapters()
  local count = #chapters
  self.tab_Widgets.lockItem:SetActive(count <= 3)
  UIHelper.CreateSubPart(self.tab_Widgets.listItem, self.tab_Widgets.content, #chapters, function(nIndex, tabPart)
    local chapter = chapters[nIndex]
    tabPart.progress.gameObject:SetActive(chapter.class_type == ChapterType.Train or chapter.class_type == ChapterType.TrainLv)
    tabPart.progress_adv:SetActive(chapter.class_type == ChapterType.TrainAdvance)
    tabPart.txt_ar:SetActive(chapter.class_type == ChapterType.AR)
    if chapter.class_type == ChapterType.Train or chapter.class_type == ChapterType.TrainLv then
      local chapterInfo = Data.copyData.ChapterInfo[chapter.id]
      local percent = chapter.passNum / chapter.totalLevels
      tabPart.progress.value = percent
      local percentStr = math.floor(percent * 100) .. "%"
      UIHelper.SetText(tabPart.txt_percent, percentStr)
    else
      UIHelper.SetText(tabPart.txt_star, string.format("%s/%s", math.floor(chapter.starNum), chapter.totalStars))
      UIHelper.SetText(tabPart.txt_defeat, UIHelper.GetLocString(1000000, chapter.rank * 100))
    end
    UIHelper.SetText(tabPart.title, chapter.name)
    tabPart.img_finish:SetActive(chapter.isFinish)
    tabPart.img_lock:SetActive(not chapter.isOpen)
    UIHelper.SetImage(tabPart.bg_item, chapter.copy_background)
    local rewards = Logic.rewardLogic:FormatRewardById(chapter.training_reward_show)
    for i = 1, 2 do
      local reward = rewards[i]
      if reward then
        local display = ItemInfoPage.GenDisplayData(reward.Type, reward.ConfigId)
        UIHelper.SetImage(tabPart["icon_reward" .. i], display.icon)
        UIHelper.SetImage(tabPart["bg_reward" .. i], QualityIcon[display.quality])
        UGUIEventListener.AddButtonOnClick(tabPart["bg_btn" .. i], function()
          self:_ShowItemInfo(display)
        end)
      else
        tabPart["bg_reward" .. i].gameObject:SetActive(false)
      end
    end
    if chapter.isOpen then
      if chapter.class_type == ChapterType.AR then
        UGUIEventListener.AddButtonOnClick(tabPart.btn_item, function()
          local fleet = Data.fleetData:GetFleetData()[1]
          if fleet == nil or table.empty(fleet.heroInfo) then
            noticeManager:OpenTipPage(self, 1430034)
            return
          end
          Logic.battleManager:JoinArPcp()
        end)
      else
        UGUIEventListener.AddButtonOnClick(tabPart.btn_item, function()
          self:_OnBtnChapterClicked(chapter, nIndex)
        end)
      end
    else
      UGUIEventListener.AddButtonOnClick(tabPart.btn_item, function()
        self:_OnBtnChapterLockClicked(chapter, nIndex)
      end)
    end
  end)
end

function TrainPage:_ShowItemInfo(displayData)
  UIHelper.OpenPage("ItemInfoPage", displayData)
end

function TrainPage:_OnBtnChapterClicked(chapter, index)
  TrainPage.LastPosX = self.tab_Widgets.content.anchoredPosition.x
  UIHelper.OpenPage("TrainLevelPage", {chapter = chapter, index = index})
end

function TrainPage:_OnBtnChapterLockClicked(chapter, index)
  local chapterTrainId = chapter.relation_chapter_id
  if 0 < chapterTrainId then
    local chapterTrain = configManager.GetDataById("config_chapter_training", chapterTrainId)
    noticeManager:ShowTip(UIHelper.GetLocString(961001, chapterTrain.open_level))
  end
end

function TrainPage:DoOnHide()
end

return TrainPage
