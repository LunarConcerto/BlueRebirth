local GuildMemberSortPage = class("UI.Guild.GuildMemberSortPage", LuaUIPage)

function GuildMemberSortPage:DoInit()
  self.mToggleSortList = {
    self.tab_Widgets.tgSortUp,
    self.tab_Widgets.tgSortDown
  }
  self.mToggleIndexList = {
    self.tab_Widgets.tgIndexPost,
    self.tab_Widgets.tgIndexTotalCon,
    self.tab_Widgets.tgIndexTodayCon,
    self.tab_Widgets.tgIndexLevel,
    self.tab_Widgets.tgIndexStatus
  }
end

function GuildMemberSortPage:DoOnOpen()
  self.mTgSort = Logic.guildLogic.cache_GuildMemberSort_Sort or 0
  self.mTgIndex = Logic.guildLogic.cache_GuildMemberSort_Index or 0
  self.tab_Widgets.tgGroupSort:SetActiveToggleIndex(self.mTgSort)
  self.tab_Widgets.tgGroupIndex:SetActiveToggleIndex(self.mTgIndex)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnCancal, function()
    UIHelper.ClosePage("GuildMemberSortPage")
  end)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btnConfirm, function()
    Logic.guildLogic.cache_GuildMemberSort_Sort = self.mTgSort or 0
    Logic.guildLogic.cache_GuildMemberSort_Index = self.mTgIndex or 0
    UIHelper.ClosePage("GuildMemberSortPage")
    eventManager:SendEvent(LuaEvent.Update_GuildPage)
  end)
end

function GuildMemberSortPage:RegisterAllEvent()
  self.tab_Widgets.tgGroupSort:ClearToggles()
  for _, toggle in ipairs(self.mToggleSortList) do
    self.tab_Widgets.tgGroupSort:RegisterToggle(toggle)
  end
  self.tab_Widgets.tgGroupSort:RemoveToggleUnActive(0)
  self.tab_Widgets.tgGroupIndex:ClearToggles()
  for _, toggle in ipairs(self.mToggleIndexList) do
    self.tab_Widgets.tgGroupIndex:RegisterToggle(toggle)
  end
  self.tab_Widgets.tgGroupIndex:RemoveToggleUnActive(0)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupSort, self, "", self._SwitchTogs_Sort)
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tgGroupIndex, self, "", self._SwitchTogs_Index)
end

function GuildMemberSortPage:DoOnHide()
end

function GuildMemberSortPage:DoOnClose()
end

function GuildMemberSortPage:_SwitchTogs_Sort(index)
  self.mTgSort = index
end

function GuildMemberSortPage:_SwitchTogs_Index(index)
  self.mTgIndex = index
end

return GuildMemberSortPage
