local PVECopyPage = class("UI.Pve.PVECopyPage", LuaUIPage)

function PVECopyPage:DoInit()
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
  self.m_PveChapterData = {}
  self.m_RoomKey = ""
end

function PVECopyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_instruction, self.OpenInstruction, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_roomnum, self.OpenRoomNum, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_activityup, self._UpCardInfo, self)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_roomlist, self.OpenRoomList, self)
end

function PVECopyPage:DoOnOpen()
  eventManager:SendEvent(LuaEvent.UpdateCopyTitle, {
    TitleName = UIHelper.GetString(6100059)
  })
  self:GetConfigData()
  local serverData = Data.copyData:GetMultiPveBattleCopyInfo()
  self:ShowChapterInfo()
  self:_ShowUpCardAct()
end

function PVECopyPage:ShowChapterInfo()
  local isLock = false
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_copy, self.m_tabWidgets.trans_content, #self.m_PveChapterData, function(index, part)
    local chapterInfoData = self.m_PveChapterData[index]
    local chapterIsPass = Logic.copyLogic:IsChapterPassByChapterId(chapterInfoData.id)
    UGUIEventListener.AddButtonOnClick(part.btn_copy, function()
      UIHelper.OpenPage("PVECopyDetailPage", chapterInfoData)
    end, self)
    UIHelper.SetImage(part.img_copy, chapterInfoData.plot_copy_cover)
    UIHelper.SetText(part.text_title, chapterInfoData.name)
  end, self)
end

function PVECopyPage:GetConfigData()
  local data = configManager.GetMultiDataByKey("config_chapter", "class_type", ChapterType.MultiPveBattle)
  if self.m_PveChapterData == nil or #self.m_PveChapterData < 1 then
    for k, v in pairs(data) do
      table.insert(self.m_PveChapterData, v)
    end
  end
end

function PVECopyPage:OpenInstruction()
  UIHelper.OpenPage("HelpPage", {content = 6100022})
end

function PVECopyPage:OpenRoomNum()
  UIHelper.OpenPage("PveRoomNumPage")
end

function PVECopyPage:_ShowUpCardAct()
  local actOpen = Logic.pveRoomLogic:CheckUpCardAct()
  self.m_tabWidgets.btn_activityup.gameObject:SetActive(actOpen)
end

function PVECopyPage:_UpCardInfo()
  local curActId = Logic.activityLogic:GetActivityIdByType(ActivityType.ActDropUpCard)
  if curActId == nil then
    noticeManager:ShowTipById(910001766)
    return
  end
  UIHelper.OpenPage("PveActivityUpPage")
end

function PVECopyPage:OpenRoomList()
  UIHelper.OpenPage("PveRoomListPage", 0)
end

return PVECopyPage
