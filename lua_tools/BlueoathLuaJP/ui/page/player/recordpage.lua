local RecordPage = class("UI.Player.RecordPage", LuaUIPage)
local ItemInfoPage = require("ui.page.Common.ItemInfoPage")
local CAMP_COLUMNS = {
  [1] = {
    HeroCampType.America
  },
  [2] = {
    HeroCampType.Japan
  },
  [3] = {
    HeroCampType.England
  },
  [4] = {
    HeroCampType.Germany
  },
  [5] = {
    HeroCampType.Franch,
    HeroCampType.Italian,
    HeroCampType.USSR,
    HeroCampType.China,
    HeroCampType.Turkish,
    HeroCampType.Unknown
  }
}
local CAMP_PIC = {
  [1] = {
    bg = "uipic_ui_settings_im_meiguo_hong_hei",
    hui = {
      "uipic_ui_settings_im_meiguo_hui_1",
      "uipic_ui_settings_im_meiguo_hui_2",
      "uipic_ui_settings_im_meiguo_hui_3",
      "uipic_ui_settings_im_meiguo_hui_4",
      "uipic_ui_settings_im_meiguo_hui_5"
    },
    isHave = {
      "uipic_ui_settings_im_meiguo_lan_1",
      "uipic_ui_settings_im_meiguo_lan_2",
      "uipic_ui_settings_im_meiguo_lan_3",
      "uipic_ui_settings_im_meiguo_lan_4",
      "uipic_ui_settings_im_meiguo_lan_5"
    },
    isMarry = {
      "uipic_ui_settings_im_meiguo_hong_1",
      "uipic_ui_settings_im_meiguo_hong_2",
      "uipic_ui_settings_im_meiguo_hong_3",
      "uipic_ui_settings_im_meiguo_hong_4",
      "uipic_ui_settings_im_meiguo_hong_5"
    }
  },
  [2] = {
    bg = "uipic_ui_settings_im_riben_hong_hei",
    hui = {
      "uipic_ui_settings_im_riben_hui_1",
      "uipic_ui_settings_im_riben_hui_2",
      "uipic_ui_settings_im_riben_hui_3",
      "uipic_ui_settings_im_riben_hui_4",
      "uipic_ui_settings_im_riben_hui_5"
    },
    isHave = {
      "uipic_ui_settings_im_riben_lan_1",
      "uipic_ui_settings_im_riben_lan_2",
      "uipic_ui_settings_im_riben_lan_3",
      "uipic_ui_settings_im_riben_lan_4",
      "uipic_ui_settings_im_riben_lan_5"
    },
    isMarry = {
      "uipic_ui_settings_im_riben_hong_1",
      "uipic_ui_settings_im_riben_hong_2",
      "uipic_ui_settings_im_riben_hong_3",
      "uipic_ui_settings_im_riben_hong_4",
      "uipic_ui_settings_im_riben_hong_5"
    }
  },
  [3] = {
    bg = "uipic_ui_settings_im_yingguo_hong_hei",
    hui = {
      "uipic_ui_settings_im_yingguo_hui_1",
      "uipic_ui_settings_im_yingguo_hui_2",
      "uipic_ui_settings_im_yingguo_hui_3",
      "uipic_ui_settings_im_yingguo_hui_4",
      "uipic_ui_settings_im_yingguo_hui_5"
    },
    isHave = {
      "uipic_ui_settings_im_yingguo_lan_1",
      "uipic_ui_settings_im_yingguo_lan_2",
      "uipic_ui_settings_im_yingguo_lan_3",
      "uipic_ui_settings_im_yingguo_lan_4",
      "uipic_ui_settings_im_yingguo_lan_5"
    },
    isMarry = {
      "uipic_ui_settings_im_yingguo_hong_1",
      "uipic_ui_settings_im_yingguo_hong_2",
      "uipic_ui_settings_im_yingguo_hong_3",
      "uipic_ui_settings_im_yingguo_hong_4",
      "uipic_ui_settings_im_yingguo_hong_5"
    }
  },
  [4] = {
    bg = "uipic_ui_settings_im_deguo_hong_hei",
    hui = {
      "uipic_ui_settings_im_deguo_hui_1",
      "uipic_ui_settings_im_deguo_hui_2",
      "uipic_ui_settings_im_deguo_hui_3",
      "uipic_ui_settings_im_deguo_hui_4",
      "uipic_ui_settings_im_deguo_hui_5"
    },
    isHave = {
      "uipic_ui_settings_im_deguo_lan_1",
      "uipic_ui_settings_im_deguo_lan_2",
      "uipic_ui_settings_im_deguo_lan_3",
      "uipic_ui_settings_im_deguo_lan_4",
      "uipic_ui_settings_im_deguo_lan_5"
    },
    isMarry = {
      "uipic_ui_settings_im_deguo_hong_1",
      "uipic_ui_settings_im_deguo_hong_2",
      "uipic_ui_settings_im_deguo_hong_3",
      "uipic_ui_settings_im_deguo_hong_4",
      "uipic_ui_settings_im_deguo_hong_5"
    }
  },
  [5] = {
    bg = "uipic_ui_settings_im_qita_hong_hei",
    hui = {
      "uipic_ui_settings_im_qita_hui_1",
      "uipic_ui_settings_im_qita_hui_2",
      "uipic_ui_settings_im_qita_hui_3",
      "uipic_ui_settings_im_qita_hui_4",
      "uipic_ui_settings_im_qita_hui_5"
    },
    isHave = {
      "uipic_ui_settings_im_qita_lan_1",
      "uipic_ui_settings_im_qita_lan_2",
      "uipic_ui_settings_im_qita_lan_3",
      "uipic_ui_settings_im_qita_lan_4",
      "uipic_ui_settings_im_qita_lan_5"
    },
    isMarry = {
      "uipic_ui_settings_im_qita_hong_1",
      "uipic_ui_settings_im_qita_hong_2",
      "uipic_ui_settings_im_qita_hong_3",
      "uipic_ui_settings_im_qita_hong_4",
      "uipic_ui_settings_im_qita_hong_5"
    }
  }
}

function RecordPage:DoInit()
  self.index = 1
  self.xunZhangInfo = {}
  self.tab_Widgets.btn_resume.gameObject:SetActive(platformManager:ShowShare())
  local loginType = PlayerPrefs.GetInt("login_type", 0)
  self.tab_Widgets.btn_inhercode.gameObject:SetActive(loginType == LoginType.Device and BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
  self.tab_Widgets.btn_saomiao.gameObject:SetActive(not isWindows and BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
  self.tab_Widgets.btn_bind.gameObject:SetActive(not isWindows and BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
end

function RecordPage:DoOnOpen()
  self:OpenTopPage("LvliPage", 3, UIHelper.GetString(920000151), self, true)
  self.tab_Widgets.input_content.onEndEdit:AddListener(function()
    self:_EndEditorMood()
  end)
  self.userInfo = Data.userData:GetUserData()
  self:_SetInfo()
  self.hideMech = PlayerPrefs.GetInt("HideMech", 0)
  self.tab_Widgets.txt_hideMech.text = self.hideMech == 0 and UIHelper.GetString(920000275) or UIHelper.GetString(920000276)
  if self.hideMech == 0 then
    UIHelper.SetImage(self.tab_Widgets.im_hideIcon, "uipic_ui_settings_bu_yincang")
  else
    UIHelper.SetImage(self.tab_Widgets.im_hideIcon, "uipic_ui_settings_bu_xianshi")
  end
  self.xunZhangInfo = Logic.userLogic:GetMedalIdTab(self.userInfo.MedalAcquiredTime)
  self:_ShowXunZhang()
  local showUser = platformManager:isShowUserCenter()
  self.tab_Widgets.btn_user.gameObject:SetActive(showUser)
end

function RecordPage:_EndEditorMood()
  self:_SetMessage()
end

function RecordPage:SetUserInfoHead()
  local icon, qualityIcon = Data.userData:GetUserHeadIcon(self.userInfo)
  UIHelper.SetImage(self.tab_Widgets.im_headback, qualityIcon)
  UIHelper.SetImage(self.tab_Widgets.im_head, icon)
end

function RecordPage:_SetInfo()
  local hero = Data.heroData:GetHeroById(self.userInfo.SecretaryId)
  local shipShow = Logic.shipLogic:GetShipShowByHeroId(hero.HeroId)
  UIHelper.SetImage(self.tab_Widgets.img_headIcon, tostring(shipShow.ship_draw))
  local position = configManager.GetDataById("config_ship_position", shipShow.ss_id)
  local grilTrans = self.tab_Widgets.img_headIcon.transform
  grilTrans.localPosition = Vector3.New(position.resume_position[1], position.resume_position[2], 0)
  local scaleSize = position.resume_scale / 10000
  local mirror = position.resume_inversion
  local scale = Vector3.New(mirror == 0 and scaleSize or -scaleSize, scaleSize, scaleSize)
  grilTrans.localScale = scale
  self:_SetUserName()
  self.tab_Widgets.txt_id.text = platformManager:getRoleId() or math.tointeger(self.userInfo.Uid)
  self.tab_Widgets.txt_lv.text = math.tointeger(self.userInfo.Level)
  self.tab_Widgets.txt_maxMilitary.text = UIHelper.GetString(920000277)
  self.tab_Widgets.txt_girlNum.text = math.floor(self.userInfo.GetHeroCount) or UIHelper.GetString(920000277)
  local ownNum, openNum = Logic.illustrateLogic:GetNormalShipNum()
  local rate = ownNum / openNum
  if 1 <= rate then
    self.tab_Widgets.txt_collect.text = string.format("%d%%", 100) or UIHelper.GetString(920000277)
  else
    self.tab_Widgets.txt_collect.text = string.format("%.1f%%", rate * 100) or UIHelper.GetString(920000277)
  end
  self.tab_Widgets.txt_server.text = Logic.loginLogic.SDKInfo and Logic.loginLogic.SDKInfo.name or UIHelper.GetString(920000277)
  self.tab_Widgets.txt_attackNum.text = math.floor(self.userInfo.AttackCount) or UIHelper.GetString(920000277)
  self.tab_Widgets.txt_marriedNum.text = self.userInfo.MarriedNum or UIHelper.GetString(920000277)
  self.tab_Widgets.txt_sectionNum.text = self.userInfo.SectionTimes or UIHelper.GetString(920000277)
  self.tab_Widgets.txt_time.text = os.date("%Y-%m-%d", self.userInfo.CreateTime)
  local _, curHeadFrameInfo = Logic.playerHeadFrameLogic:GetNowHeadFrame()
  local icon, qualityIcon = Data.userData:GetUserHeadIcon(self.userInfo)
  UIHelper.SetImage(self.tab_Widgets.im_headback, qualityIcon)
  UIHelper.SetImage(self.tab_Widgets.im_head, icon)
  if curHeadFrameInfo then
    UIHelper.SetImage(self.tab_Widgets.img_headFrame, curHeadFrameInfo.icon)
  end
  local chapter, copyId = Logic.copyLogic:GetCurSeaChapterSection()
  local copyDisplayConfig = configManager.GetDataById("config_copy_display", copyId)
  self.tab_Widgets.tx_sea.text = copyDisplayConfig.copy_index
  chapter, copyId = Logic.copyLogic:GetCurPlotChapterSection()
  copyDisplayConfig = configManager.GetDataById("config_copy_display", copyId)
  self.tab_Widgets.tx_plot.text = copyDisplayConfig.copy_index
  local ownNum, _ = Logic.illustrateLogic:GetNormalShipNum()
  self.tab_Widgets.img_girl.text = ownNum
  self.tab_Widgets.input_content.text = self.userInfo.Message
  self.tab_Widgets.slider.value = rate
  self.tab_Widgets.slider.interactable = false
  local towerData = Data.towerData:GetData() or {}
  local flag = towerData.ChapterId and 0 < towerData.ChapterId
  if not flag then
    self.tab_Widgets.tx_num.text = UIHelper.GetString(240007)
  else
    self.tab_Widgets.tx_num.text = Logic.towerLogic:GetRecordName()
  end
  local dailyShow = {}
  local config = configManager.GetData("config_chapter")
  for k, v in pairs(config) do
    if v.class_type == ChapterType.DailyCopy then
      local chapterData = Logic.dailyCopyLogic:GetPassCopy(v.id) or {}
      local data = {}
      local passEx = Logic.dailyCopyLogic:CheckExCopyPass(v.id)
      if passEx then
        local dailyCopyData = Data.dailyCopyData:GetDailyCopyData()
        data = {
          name = v.class_name,
          num = dailyCopyData[v.id].ExStar,
          passEx = passEx
        }
      else
        data = {
          name = v.class_name,
          num = #chapterData,
          passEx = passEx
        }
      end
      table.insert(dailyShow, data)
    end
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_type, self.tab_Widgets.trans_daily, #dailyShow, function(index, tabPart)
    tabPart.tx_type.text = dailyShow[index].name
    tabPart.obj_star:SetActive(dailyShow[index].passEx)
    tabPart.tx_exStar.gameObject:SetActive(dailyShow[index].passEx)
    if dailyShow[index].passEx then
      tabPart.tx_num.text = UIHelper.GetString(920000802)
      tabPart.tx_exStar.text = dailyShow[index].num
    elseif dailyShow[index].num > 0 then
      tabPart.tx_num.text = string.format(UIHelper.GetString(290007), dailyShow[index].num)
    else
      tabPart.tx_num.text = UIHelper.GetString(240007)
    end
  end)
  if 4 < #dailyShow then
    self.tab_Widgets.copy_scroll.enabled = true
  else
    self.tab_Widgets.copy_scroll.enabled = false
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_camp, self.tab_Widgets.trans_camp, #CAMP_COLUMNS, function(index, tabPart)
    local num, marryNum = Logic.illustrateLogic:GetOwnShipNumByCamp(CAMP_COLUMNS[index])
    local maxNum = Data.illustrateData:GetShipNumByCamp(CAMP_COLUMNS[index])
    local maxPIC = math.ceil(maxNum / #CAMP_PIC[index].isHave)
    local numPIC = math.ceil((num + 1) / #CAMP_PIC[index].isHave)
    numPIC = math.max(numPIC, 1)
    numPIC = math.min(numPIC, maxPIC)
    UIHelper.CreateSubPart(tabPart.obj_camp, tabPart.trans_camp, maxPIC, function(i, subtabPart)
      UIHelper.SetImage(subtabPart.im_bg, CAMP_PIC[index].bg)
      subtabPart.im_bg.gameObject:SetActive(true)
      local n = 1
      local bgRemaining = maxNum - (i - 1) * #CAMP_PIC[index].hui
      if bgRemaining > #CAMP_PIC[index].hui then
        n = #CAMP_PIC[index].hui
      else
        n = bgRemaining
      end
      UIHelper.SetImage(subtabPart.im_hui, CAMP_PIC[index].hui[n])
      subtabPart.im_hui.gameObject:SetActive(true)
      local Remaining = num - (i - 1) * #CAMP_PIC[index].isHave
      if Remaining <= 0 then
        return
      end
      n = 1
      if Remaining > #CAMP_PIC[index].isHave then
        n = #CAMP_PIC[index].isHave
      else
        n = Remaining
      end
      UIHelper.SetImage(subtabPart.im_lan, CAMP_PIC[index].isHave[n])
      subtabPart.im_lan.gameObject:SetActive(true)
      Remaining = marryNum - (i - 1) * #CAMP_PIC[index].isMarry
      if Remaining <= 0 then
        return
      end
      n = 1
      if Remaining > #CAMP_PIC[index].isMarry then
        n = #CAMP_PIC[index].isMarry
      else
        n = Remaining
      end
      UIHelper.SetImage(subtabPart.im_fen, CAMP_PIC[index].isMarry[n])
      subtabPart.im_fen.gameObject:SetActive(true)
    end)
  end)
end

function RecordPage:_SetMessage()
  local input = self.tab_Widgets.input_content.text
  Service.userService:SendSetMessage(input)
end

function RecordPage:RegisterAllEvent()
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_changeSecretary, self._ChangeSecretary, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_left, self._ClickLeft, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_right, self._ClickRight, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_set, self._OpenDisPlaySet, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_hideMech, self._HideMech, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_user, self._UserCenter, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_changeScene, self._ChangeScene, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_choseScene, self._CloseChangeScene, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_resume, self._OpenResume, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_changename, self._OpenChangeName, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_headFrame, self._OpenHeadFrame, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_inhercode, self._GenInherCode, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_saomiao, self._ClickScanCode, self)
  UGUIEventListener.AddButtonOnClick(self.tab_Widgets.btn_bind, self._ClickBind, self)
  self:RegisterEvent(LuaEvent.UpdataUserInfo, self._UpdateUserData, self)
  self:RegisterEvent(LuaEvent.SetSecretaryFinish, self._SetFinish, self)
  self:RegisterEvent(LuaEvent.ShareOver, self._ShareOver, self)
  self:RegisterEvent(LuaEvent.ChangeNameOk, self._SetUserName, self)
  self:RegisterEvent(LuaEvent.UpdataUserInfoHead, self.SetUserInfoHead, self)
  self.tabTogs = {
    self.tab_Widgets.tog_one,
    self.tab_Widgets.tog_two
  }
  for i, tog in pairs(self.tabTogs) do
    self.tab_Widgets.tog_group:RegisterToggle(tog)
  end
  UIHelper.AddToggleGroupChangeValueEvent(self.tab_Widgets.tog_group, self, "", self._SwitchTogs)
end

function RecordPage:_OpenResume()
  self:ShareComponentShow(false)
  shareManager:Share(self:GetName(), QRCodeType.LeftDown)
end

function RecordPage:_OpenChangeName()
  local name = Data.userData:GetUserName()
  UIHelper.OpenPage("ChangeNamePage", {
    nil,
    name,
    name,
    ChangeNameType.User
  })
end

function RecordPage:_GenInherCode()
  platformManager:GetInheritCode()
end

function RecordPage:_ClickScanCode()
  platformManager:ShowScanCode()
end

function RecordPage:_ClickBind()
  platformManager:OpenBind()
end

function RecordPage:_SetUserName()
  local widgets = self:GetWidgets()
  local name = Data.userData:GetUserName()
  UIHelper.SetText(widgets.txt_name, name)
end

function RecordPage:_ShareOver()
  self:ShareComponentShow(true)
  local showUser = platformManager:isShowUserCenter()
  self.tab_Widgets.btn_user.gameObject:SetActive(showUser)
  local loginType = PlayerPrefs.GetInt("login_type", 0)
  self.tab_Widgets.btn_inhercode.gameObject:SetActive(loginType == LoginType.Device and BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
  self.tab_Widgets.btn_saomiao.gameObject:SetActive(not isWindows and BabelTimeSDK.AppleReview ~= BabelTimeSDK.IS_REVIEW)
end

function RecordPage:_OpenHeadFrame()
  UIHelper.OpenPage("PlayerHeadFramePage")
end

function RecordPage:_OpenDisPlaySet()
  UIHelper.OpenPage("DisplaySetPage")
end

function RecordPage:_UserCenter()
  platformManager:enterUserCenter()
end

function RecordPage:_HideMech()
  self.hideMech = 1 - self.hideMech
  self.tab_Widgets.txt_hideMech.text = self.hideMech == 0 and UIHelper.GetString(920000275) or UIHelper.GetString(920000276)
  if self.hideMech == 0 then
    UIHelper.SetImage(self.tab_Widgets.im_hideIcon, "uipic_ui_settings_bu_yincang")
  else
    UIHelper.SetImage(self.tab_Widgets.im_hideIcon, "uipic_ui_settings_bu_xianshi")
  end
  PlayerPrefs.SetInt("HideMech", self.hideMech)
  local dotInfo = {
    info = "ui_hideequip",
    type = tostring(1 - self.hideMech)
  }
  RetentionHelper.Retention(PlatformDotType.uilog, dotInfo)
end

function RecordPage:_ChangeSecretary()
  local heroId = Data.userData:GetUserData().SecretaryId
  local displayInfo = Logic.shipLogic:GetRidHeroId(heroId)
  Logic.homeLogic:EntryChange(heroId)
  UIHelper.OpenPage("CommonSelectPage", {
    CommonHeroItem.ChangeSecretaryFleet,
    displayInfo,
    {m_selectMax = 1}
  })
end

function RecordPage:_ShowXunZhang()
  local num = #self.xunZhangInfo - (self.index - 1) * 6
  local min
  if num < 6 then
    min = num
  elseif 6 <= num then
    min = 6
  end
  UIHelper.CreateSubPart(self.tab_Widgets.obj_xunzhang, self.tab_Widgets.trans_xunzhang, min, function(nIndex, tabPart)
    local icon = Logic.medalLogic:GetIcon(self.xunZhangInfo[nIndex + (self.index - 1) * 6])
    local data = Logic.medalLogic:GetMedal(self.xunZhangInfo[nIndex + (self.index - 1) * 6])
    UIHelper.SetImage(tabPart.im_xunzhang, icon)
    UGUIEventListener.AddButtonOnClick(tabPart.btnDrag, function()
      self:_ShowMedal(self, data)
    end)
  end)
end

function RecordPage:_ShowMedal(go, medalData)
  UIHelper.OpenPage("ItemInfoPage", ItemInfoPage.GenDisplayData(GoodsType.MEDAL, medalData.id, self.userInfo.MedalAcquiredTime))
end

function RecordPage:_ClickLeft(...)
  if self.index > 1 then
    self.index = self.index - 1
    self:_ShowXunZhang()
  else
    self.index = self.index
  end
end

function RecordPage:_ClickRight(...)
  if self.index < math.ceil(#self.xunZhangInfo / 6) then
    self.index = self.index + 1
    self:_ShowXunZhang()
  else
    self.index = self.index
  end
end

function RecordPage:_UpdateUserData()
  self:_SetInfo()
end

function RecordPage:_SetFinish()
  local tabInfo = Logic.homeLogic:GetSecretaryInfo()
  if tabInfo ~= nil then
    RetentionHelper.Retention(PlatformDotType.secretary, tabInfo)
  end
  Logic.homeLogic:SetChangeGirl(true)
  noticeManager:OpenTipPage(self, UIHelper.GetString(920000278))
end

function RecordPage:_ChangeScene()
  self.tab_Widgets.obj_choseScene:SetActive(true)
  local curType = Logic.homeLogic:GetDefaultScene()
  self.tab_Widgets.tog_group:SetActiveToggleIndex(curType - 1)
end

function RecordPage:_SwitchTogs(index)
  if not self.openScene then
    self.openScene = true
    return
  end
  PlayerPrefs.SetInt("HomeSceneType", index + 1)
  noticeManager:OpenTipPage(self, UIHelper.GetString(920000279))
  homeEnvManager:ChangeScene(SceneType.HOME, true)
  eventManager:SendEvent(LuaEvent.ChangeMainScene, true)
  self:_CloseChangeScene()
end

function RecordPage:_CloseChangeScene()
  self.openScene = false
  self.tab_Widgets.obj_choseScene:SetActive(false)
end

function RecordPage:DoOnHide()
  self:_RemoveUnityListener()
end

function RecordPage:DoOnClose()
  self:_RemoveUnityListener()
end

function RecordPage:_RemoveUnityListener()
  self.tab_Widgets.tog_group:ClearToggles()
  self.tab_Widgets.input_content.onEndEdit:RemoveAllListeners()
end

return RecordPage
