local HomeActivityEnter = class("UI.Home.HomeActivityEnter")

function HomeActivityEnter:initialize(...)
end

function HomeActivityEnter:Init(page)
  self.m_actIndex = 1
  self.m_openPage = ""
  self.m_actTog = {}
  self.page = page
  self.mTimer = nil
  self.funId = 0
  self.m_tabWidgets = page.m_tabWidgets
  UGUIEventListener.AddButtonOnClick(self.m_tabWidgets.btn_activity, self._OpenActivity, self)
  self.script = self.m_tabWidgets.trans_actMask.gameObject:GetComponent(ImageCarousel.GetClassType())
end

function HomeActivityEnter:_CarouselImage(index)
  local config = self.actConfig[index + 1]
  if config ~= nil then
    self.m_actIndex = config.banner_goto
    self.m_openPage = config.banner_gotopage
    self.config = config
    self.funId = config.function_id
  else
    self.m_actIndex = 1
    self.m_openPage = ""
    self.config = self.actConfig[1]
    self.funId = 0
  end
  for i, v in pairs(self.m_actTog) do
    v.obj_select:SetActive(false)
    if index + 1 == i then
      v.obj_select:SetActive(true)
    end
  end
end

function HomeActivityEnter:_OpenActivity()
  if Logic.redDotLogic.Supply() then
    Data.activityData:SetTag(Activity.Supply)
    UIHelper.OpenPage("ActivityPage")
    return
  end
  if self.m_openPage ~= "" then
    if self.funId ~= 0 then
      local funOpen = moduleManager:CheckFunc(self.funId, true)
      if not funOpen then
        return
      end
    end
    UIHelper.OpenPage(self.m_openPage, self.m_actIndex)
  else
    Data.activityData:SetTag(self.config.id)
    UIHelper.OpenPage("ActivityPage")
  end
end

function HomeActivityEnter:_CreateBanner()
  self:ResetBanner()
  self.script.enabled = false
  self:_StartTimer(param)
end

function HomeActivityEnter:_StartTimer()
  if self.mTimer == nil then
    self.mTimer = FrameTimer.New(function()
      self:_StartCarousel()
    end, 0, -1)
  end
  self.mTimer:Start()
end

function HomeActivityEnter:_StartCarousel()
  self:ClearBannerTimer()
  self.actConfig = Logic.activityLogic:GetActivityBanner()
  self:_CarouselImage(0)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_actItem, self.m_tabWidgets.trans_actMask, #self.actConfig, function(nIndex, tabPart)
    local config = self.actConfig[nIndex]
    UIHelper.SetImage(tabPart.img_banner, config.banner_pic)
    if next(config.red_dot) then
      self.page:RegisterRedDotById(tabPart.im_redflag, config.red_dot, config.id)
    end
    if Logic.redDotLogic.Supply() then
      tabPart.im_redflag.gameObject:SetActive(true)
    end
  end)
  UIHelper.CreateSubPart(self.m_tabWidgets.obj_actTogItem, self.m_tabWidgets.trans_actTog, #self.actConfig, function(nIndex, tabPart)
    tabPart.obj_select:SetActive(false)
    if nIndex == 1 then
      tabPart.obj_select:SetActive(true)
    end
    table.insert(self.m_actTog, tabPart)
  end)
  self.script.enabled = true
end

function HomeActivityEnter:ResetBanner()
  self.m_actTog = {}
  self:ClearBannerTimer()
  for i = 0, self.m_tabWidgets.trans_actMask.childCount - 1 do
    local child = self.m_tabWidgets.trans_actMask:GetChild(i).gameObject
    local redDot = child.transform:Find("im_redflag").gameObject:GetComponent(RedDot.GetClassType())
    self.page:UnRegisterRedDotById(redDot:GetId())
    GameObject.Destroy(child)
  end
end

function HomeActivityEnter:ClearBannerTimer()
  if self.mTimer ~= nil then
    self.mTimer:Stop()
  end
  self.mTimer = nil
end

return HomeActivityEnter
