local TeachCopyPage = class("UI.Copy.TeachCopyPage", LuaUIPage)
local OPEN_STAR = 7

function TeachCopyPage:DoInit()
  self.tabChapterSortConfig = {}
  self.nSelectedChapIndex = 1
  self.bChaseFighting = false
  self.chapterLength = 0
  self.nBossHp = 0
  if self.m_tabWidgets == nil then
    self.m_tabWidgets = self:GetWidgets()
  end
end

function TeachCopyPage:DoOnOpen()
  self:_CerateChapter()
  self.m_tabWidgets.btn_left.interactable = self.nSelectedChapIndex > 1
  self.m_tabWidgets.btn_right.interactable = self.nSelectedChapIndex < self.chapterLength
end

function TeachCopyPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_left, function()
    self:_ClickLeft()
  end)
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_right, function()
    self:_ClickRight()
  end)
end

function TeachCopyPage:_CerateChapter()
  local togGroup = {}
  self.tabChapterSortConfig = Logic.teachCopyLogic:GetTeachChapterConf()
  self.chapterLength = #self.tabChapterSortConfig
  self.m_tabWidgets.tog_chapterGroup:ClearToggles()
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_chapterItem, self.m_tabWidgets.trans_chapterContent, #self.tabChapterSortConfig, function(nIndex, tabPart)
    local chaterConfInfo = self.tabChapterSortConfig[nIndex]
    tabPart.txt_normal.text = chaterConfInfo.name
    tabPart.txt_select.text = chaterConfInfo.name
    tabPart.tx_chapterNum.text = chaterConfInfo.title
    if self.chapterLength == nIndex then
      tabPart.im_cOne.gameObject:SetActive(false)
      tabPart.im_cTwo.gameObject:SetActive(false)
    end
    table.insert(togGroup, tabPart.tog_item)
  end)
  for i, tog in ipairs(togGroup) do
    self.m_tabWidgets.tog_chapterGroup:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.m_tabWidgets.tog_chapterGroup, self, " ", self._SwitchTogsTag)
  self.m_tabWidgets.tog_chapterGroup:SetActiveToggleIndex(0)
end

function TeachCopyPage:_SwitchTogsTag(nIndex)
  local curIndex = nIndex + 1
  self:_CreateBaseInfo(curIndex)
  self.nSelectedChapIndex = curIndex
  self.m_tabWidgets.btn_left.interactable = 1 < self.nSelectedChapIndex
  self.m_tabWidgets.btn_right.interactable = self.nSelectedChapIndex < self.chapterLength
end

function TeachCopyPage:_CreateBaseInfo(nIndex)
  local tabCopyConfig = self.tabChapterSortConfig[nIndex].level_list
  local tabAreasDesInfo = Logic.copyLogic:GetAreaConfig(tabCopyConfig)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_areaInfoItem, self.m_tabWidgets.trans_areaInfoContent, #tabCopyConfig, function(nAreaIndex, tabPart)
    local tabAreaDesInfo = tabAreasDesInfo[nAreaIndex]
    tabPart.tx_levelDetail.text = "\229\133\179\229\141\161" .. tabAreaDesInfo.title
    local baseId = tabAreaDesInfo.id
    tabPart.tx_areaName.text = tabAreaDesInfo.name
    tabPart.obj_maskImage:SetActive(false)
    tabPart.obj_chase:SetActive(false)
    tabPart.obj_BossHP:SetActive(false)
    self:_CreateShowStar(7, tabPart)
    UGUIEventListener.AddButtonOnClick(tabPart.btn_fun.gameObject, function()
      local areaConfig = {
        BaseId = baseId,
        bossHp = self.nBossHp,
        chapterId = self.nSelectedChapIndex,
        BossId = 0
      }
      UIHelper.OpenPage("TeachLevelDetailPage", areaConfig)
    end)
  end)
end

function TeachCopyPage:_CreateShowStar(param, tabPart)
  tabPart.obj_oneStar:SetActive(param & 1 == 1)
  tabPart.obj_twoStar:SetActive(param & 2 == 2)
  tabPart.obj_threeStar:SetActive(param & 4 == 4)
end

function TeachCopyPage:_ClickLeft()
  self.m_tabWidgets.btn_left.interactable = self.nSelectedChapIndex > 1
  self.m_tabWidgets.btn_right.interactable = self.nSelectedChapIndex < self.chapterLength
end

function TeachCopyPage:_ClickRight()
  self.m_tabWidgets.btn_left.interactable = self.nSelectedChapIndex > 1
  self.m_tabWidgets.btn_right.interactable = self.nSelectedChapIndex < self.chapterLength
end

return TeachCopyPage
