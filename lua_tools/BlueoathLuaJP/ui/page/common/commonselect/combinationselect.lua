local CombinationSelect = class("ui.page.Common.CommonSelect.CombinationSelect")

function CombinationSelect:Init(page, tabParams)
  self.uiTab = tabParams
  
  local function ChangeConfirm()
    local mainHeroId = tabParams.MainHeroId
    local DeputyHeroId = page.m_tabSelectShip[1] or 0
    if 0 < DeputyHeroId then
      local combData = Logic.shipCombinationLogic:GetCombineData(DeputyHeroId)
      if 0 < combData.ComLv then
        Service.heroService:_SendCombineHero({MainHero = mainHeroId, DeputyHero = DeputyHeroId})
        UIHelper.Back()
      else
        local tabParams = {
          msgType = NoticeType.TwoButton,
          callback = function(bool)
            if bool then
              local heros = {}
              for k, v in pairs(Data.heroData:GetHeroData()) do
                table.insert(heros, v.HeroId)
              end
              UIHelper.OpenPage("GirlInfo", {
                DeputyHeroId,
                heros,
                jumpToggle = 6
              })
            end
          end
        }
        noticeManager:ShowMsgBox(UIHelper.GetString(4900026), tabParams)
      end
    else
      local mainHeroCombineData = Logic.shipCombinationLogic:GetCombineData(mainHeroId)
      if 0 < mainHeroCombineData.Combine then
        Service.heroService:_SendCombineHero({MainHero = mainHeroId, DeputyHero = 0})
      end
      UIHelper.Back()
    end
  end
  
  local function ChangeCancel()
    UIHelper.Back()
  end
  
  page:OpenTopPage("CommonSelectPage", 1, UIHelper.GetString(920000162), page, true, ChangeCancel)
  UGUIEventListener.AddButtonOnClick(page.m_tabWidgets.btn_ok, ChangeConfirm)
  UGUIEventListener.AddButtonOnClick(page.m_tabWidgets.btn_cancal, ChangeCancel)
  page.m_tabSelectShip = tabParams.m_selectedIdList or {}
end

return CombinationSelect
