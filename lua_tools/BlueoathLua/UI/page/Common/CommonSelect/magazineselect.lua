local MagazineSelect = class("ui.page.Common.CommonSelect.MagazineSelect")

function MagazineSelect:initialize()
end

function MagazineSelect:Init(page, tabParams)
  local ChangeConfirm = function()
    local heroId = page.m_tabSelectShip[1] or 0
    Service.magazineService:SendMagazineAddHero({
      Index = page.magazineIndex,
      HeroId = heroId,
      MagazineId = page.magazineId
    })
    UIHelper.Back()
  end
  local ChangeCancel = function()
    UIHelper.Back()
  end
  page:OpenTopPage("CommonSelectPage", 1, UIHelper.GetString(920000162), page, true, ChangeCancel)
  UGUIEventListener.AddButtonOnClick(page.m_tabWidgets.btn_ok, ChangeConfirm)
  UGUIEventListener.AddButtonOnClick(page.m_tabWidgets.btn_cancal, ChangeCancel)
  page.m_tabSelectShip = tabParams.m_selectedIdList or {}
end

return MagazineSelect
