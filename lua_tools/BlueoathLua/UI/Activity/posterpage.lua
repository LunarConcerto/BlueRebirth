local PosterPage = class("UI.Activity.PosterPage", LuaUIPage)
local NON_POSTER = 0

function PosterPage:DoInit()
  if self.tab_Widgets == nil then
    self.tab_Widgets = self:GetWidgets()
  end
  self.m_isShowList = false
  self.m_allHeroList = {}
  self.m_ownedHeroListMap = {}
  self.m_ownedHeroList = {}
  self.m_curshipGril = 0
  self.m_curIndex = 0
  self.point = 0
end

function PosterPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_expand, self._ShowHelp, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_left, self._ChangePre, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_right, self._ChangeNext, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_get, self._ClickMagazinePage, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_ok, self._ClickSave, self)
  self:RegisterEvent(LuaEvent.RefreshAllInteractionItem, self.ShowPage, self)
end

function PosterPage:DoOnOpen()
  self.param = self:GetParam()
  self.point = self.param.Point
  self:OpenTopPage("PosterPage", 1, UIHelper.GetString(3500000), self, true)
  self.m_allHeroList = self:GetAllPosterInTable()
  table.sort(self.m_allHeroList, function(a, b)
    return a < b
  end)
  local _, tmpPoster = Logic.interactionItemLogic:GetDecorateBagOther()
  tmpPoster[0] = 0
  self.m_ownedHeroListMap = tmpPoster
  local tmp = {}
  for _, v in pairs(self.m_allHeroList) do
    for _, u in pairs(self.m_ownedHeroListMap) do
      if v == u then
        table.insert(tmp, u)
      end
    end
  end
  self.m_ownedHeroList = tmp
  self.m_curshipGril = Logic.interactionItemLogic:GetPosterByPoint(self.point)
  local numText = #self.m_ownedHeroList - 1 .. "/" .. #self.m_allHeroList - 1
  UIHelper.SetText(self.tab_Widgets.tx_num, numText)
  self:SetRedDot()
  eventManager:SendEvent(LuaEvent.RefreshAllInteractionItem)
  self:ShowPage()
end

function PosterPage:SetRedDot()
  local posterList = configManager.GetDataById("config_parameter", 377).arrValue
  local point = self.point
  local userInfo = Data.userData:GetUserData()
  local uid = tostring(userInfo.Uid)
  local dot = PlayerPrefs.GetInt(uid .. "PosterPage" .. point, 0)
  if dot ~= 1 then
    PlayerPrefs.SetInt(uid .. "PosterPage" .. point, 1)
  end
end

function PosterPage:GetAllPosterInTable()
  local tmp = {}
  local config = configManager.GetData("config_interaction_item_bag")
  table.insert(tmp, 0)
  for i, v in pairs(config) do
    if v.type == InteractionBagItemType.Poster then
      table.insert(tmp, v.id)
    end
  end
  return tmp
end

function PosterPage:__GetGirlIndex()
  for i, v in pairs(self.m_ownedHeroList) do
    if v == self.m_curshipGril then
      return i
    end
  end
  return 0
end

function PosterPage:ShowPage()
  local widgets = self.tab_Widgets
  self:ShowPoster()
  self:ShowGrilList()
end

function PosterPage:_ShowHelp()
  self.m_isShowList = not self.m_isShowList
  self.tab_Widgets.obj_list.gameObject:SetActive(self.m_isShowList)
  self:ShowPage()
end

function PosterPage:ShowPoster()
  if self.m_curshipGril == NON_POSTER then
    self.tab_Widgets.im_noequipped.gameObject:SetActive(true)
    self.tab_Widgets.im_poster.gameObject:SetActive(false)
    self.tab_Widgets.txt_name.gameObject:SetActive(false)
  else
    self.tab_Widgets.im_noequipped.gameObject:SetActive(false)
    self.tab_Widgets.im_poster.gameObject:SetActive(true)
    self.tab_Widgets.txt_name.gameObject:SetActive(true)
    local posterConfig = configManager.GetDataById("config_interaction_item_bag", self.m_curshipGril)
    UIHelper.SetImage(self.tab_Widgets.im_poster, posterConfig.picture)
    UIHelper.SetText(self.tab_Widgets.txt_name, posterConfig.name)
  end
end

function PosterPage:ShowGrilList()
  local allHeroList = self.m_allHeroList
  local ownedHeroList = self.m_ownedHeroListMap
  UIHelper.CreateSubPart(self.tab_Widgets.item_poster, self.tab_Widgets.Content, #allHeroList, function(index, tabPart)
    local posterId = allHeroList[index]
    if posterId ~= nil then
      if posterId == NON_POSTER then
        tabPart.item_noequipped.gameObject:SetActive(posterId == NON_POSTER)
      else
        local posterConfig = configManager.GetDataById("config_interaction_item_bag", posterId)
        UIHelper.SetImage(tabPart.im_girl, tostring(posterConfig.icon))
        UIHelper.SetImage(tabPart.im_pinzhi, QualityIcon[posterConfig.quality])
      end
      tabPart.btn_poster.gameObject:SetActive(true)
      tabPart.im_choose.gameObject:SetActive(false)
      tabPart.im_unget.gameObject:SetActive(ownedHeroList[posterId] == nil)
      if posterId == self.m_curshipGril then
        tabPart.im_choose.gameObject:SetActive(true)
      end
      UGUIEventListener.AddButtonOnClick(tabPart.btn_poster, self._ChangeClickIcon, self, {id = posterId})
    end
  end)
end

function PosterPage:_ChangePre()
  self.m_curIndex = self:__GetGirlIndex()
  if self.m_curIndex == 1 then
    self.m_curIndex = #self.m_ownedHeroList
  else
    self.m_curIndex = self.m_curIndex - 1
  end
  if self.m_ownedHeroList[self.m_curIndex] then
    self.m_curshipGril = self.m_ownedHeroList[self.m_curIndex]
  end
  self:ShowPage()
end

function PosterPage:_ChangeNext()
  self.m_curIndex = self:__GetGirlIndex()
  if self.m_curIndex == #self.m_ownedHeroList then
    self.m_curIndex = 1
  else
    self.m_curIndex = self.m_curIndex + 1
  end
  if self.m_ownedHeroList[self.m_curIndex] then
    self.m_curshipGril = self.m_ownedHeroList[self.m_curIndex]
  end
  self:ShowPage()
end

function PosterPage:_ChangeClickIcon(go, param)
  if not self.m_ownedHeroListMap[param.id] and param.id ~= NON_POSTER then
    noticeManager:ShowTip(UIHelper.GetString(3500001))
    return
  end
  self.m_curshipGril = param.id
  self.m_curIndex = self:__GetGirlIndex()
  self:ShowPage()
end

function PosterPage:_ClickMagazinePage()
  moduleManager:JumpToFunc(FunctionID.Magazine)
end

function PosterPage:_ClickSave()
  local interactionItemTab = {
    point = self.point,
    posterId = self.m_curshipGril
  }
  Service.interactionItemService:SetPosters(interactionItemTab)
end

function PosterPage:__ShowPosterModel(posterConfig)
  local posterConfig = configManager.GetDataById("config_interaction_item_bag", self.m_curshipGril)
  local ModelPathELISA = posterConfig.item_name
  if self.m_sprayObj ~= nil then
    GR.objectPoolManager:LuaUnspawnAndDestory(self.m_sprayObj)
    self.m_sprayObj = nil
  end
  self.m_sprayObj = GR.objectPoolManager:LuaGetGameObject(ModelPathELISA, self.tab_Widgets.trans)
  local itemPosition = configManager.GetDataById("config_parameter", 328).arrValue
  self.m_sprayObj.transform.localPosition = Vector3.New(itemPosition[1][1], itemPosition[1][2], itemPosition[1][3])
  self.m_sprayObj.transform.localEulerAngles = Vector3.New(itemPosition[2][1], itemPosition[2][2], itemPosition[2][3])
  self.m_sprayObj.transform.localScale = Vector3.New(1, 1, 1)
  UIHelper.SetLayer(self.m_sprayObj, LayerMask.NameToLayer("UI"))
end

function PosterPage:__RefreshChangeView()
  self:ShowPage()
end

function PosterPage:_ClickClose()
  UIHelper.ClosePage("PosterPage")
end

function PosterPage:DoOnHide()
end

function PosterPage:DoOnClose()
end

return PosterPage
