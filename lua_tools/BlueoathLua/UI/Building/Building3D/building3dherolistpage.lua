local Building3DHeroListPage = class("UI.Building.Building3D.Building3DHeroListPage", LuaUIPage)

function Building3DHeroListPage:DoInit()
end

function Building3DHeroListPage:DoOnOpen()
  self:_Refresh()
end

function Building3DHeroListPage:RegisterAllEvent()
  local widgets = self:GetWidgets()
  UGUIEventListener.AddButtonOnClick(widgets.im_mask, self._CloseSelf, self)
  UGUIEventListener.AddButtonOnClick(widgets.btn_close, self._CloseSelf, self)
  self:RegisterEvent(LuaEvent.BuildingRefreshData, self._Refresh, self)
end

function Building3DHeroListPage:_Refresh()
  self:_ShowHeroList()
end

function Building3DHeroListPage:_ShowTip(tid)
  local widgets = self:GetWidgets()
  local target = Logic.buildingLogic:_getRmdCharacter(tid)
  local str = ""
  if 0 < #target then
    for _, id in ipairs(target) do
      local name = configManager.GetDataById("config_character", id).name
      str = str .. " " .. name
    end
  end
  widgets.tx_tip.gameObject:SetActive(0 < #target)
  UIHelper.SetText(widgets.tx_tip, string.format("\230\128\167\230\160\188\228\184\186%s\231\154\132\232\136\176\229\168\152\230\156\137\229\138\160\230\136\144", str))
end

function Building3DHeroListPage:_ShowHeroList()
  local widgets = self:GetWidgets()
  local data = Data.buildingData:GetBuildingById(self:GetParam().data.Id)
  if data == nil then
    logError("\229\143\150\232\161\165\229\136\176\230\149\176\230\141\174\228\186\134,Id:" .. self:GetParam().data.Id)
    return
  end
  local slot = Logic.buildingLogic:GetOneBuildingHeroMax(data.Tid)
  local heroList = data.HeroList
  UIHelper.CreateSubPart(widgets.girl, widgets.girl_list, slot, function(index, tabPart)
    if heroList[index] then
      local ship = Data.heroData:GetHeroById(heroList[index])
      local shipInfo = Logic.shipLogic:GetShipShowByHeroId(ship.HeroId)
      UIHelper.SetImage(tabPart.im_icon, tostring(shipInfo.ship_icon5))
      local char = Logic.shipLogic:GetHeroCharcaterStr(ship.TemplateId)
      UIHelper.SetText(tabPart.tx_desc, char)
      local moodInfo = Logic.marryLogic:GetLoveInfo(heroList[index], MarryType.Mood)
      local cur, mood, rate = Logic.buildingLogic:GetHeroMoodCost(data.Id, heroList[index])
      UIHelper.SetImage(tabPart.im_mood, moodInfo.mood_icon, true)
      tabPart.Slider.value = rate
    end
    tabPart.have_girl:SetActive(heroList[index] ~= nil)
    tabPart.im_add:SetActive(heroList[index] == nil)
    UGUIEventListener.AddButtonOnClick(tabPart.im_bg, self._OnClickHeroCard, self, heroList[index] or 0)
  end)
  self:_ShowTip(data.Tid)
end

function Building3DHeroListPage:_OnClickHeroCard(go, param)
  local data = Data.buildingData:GetBuildingById(self:GetParam().data.Id)
  if data == nil then
    logError("\229\143\150\232\161\165\229\136\176\230\149\176\230\141\174\228\186\134,Id:" .. self:GetParam().data.Id)
    return
  end
  local max = Logic.buildingLogic:GetOneBuildingHeroMax(data.Tid)
  local tabShowHero = Logic.dockLogic:FilterShipList(DockListType.All)
  UIHelper.OpenPage("CommonSelectPage", {
    CommonHeroItem.Building,
    tabShowHero,
    {
      m_selectMax = max,
      m_selectedIdList = data.HeroList,
      m_buildingInfo = data
    }
  })
end

function Building3DHeroListPage:_CloseSelf()
  UIHelper.ClosePage("Building3DHeroListPage")
end

function Building3DHeroListPage:DoOnHide()
end

function Building3DHeroListPage:DoOnClose()
end

return Building3DHeroListPage
