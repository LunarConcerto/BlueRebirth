local m = class("SelectTextbookItem")

function m:SetData(data, part, index)
  self.data = data
  self.part = part
  self.m_selected = data.bSelect
  self.index = index
end

function m:Display()
  local data = self.data
  local part = self.part
  local index = self.index
  UIHelper.SetImage(part.img_bg, QualityIcon[data.quality])
  UIHelper.SetText(part.txt_num, "x" .. math.tointeger(data.bookNum))
  UIHelper.SetImage(part.img_icon, data.bookIcon)
  part.txt_spExp.gameObject:SetActive(data.spExp)
  UIHelper.SetText(part.txt_spExp, math.tointeger(data.expRatio * 100) .. "%")
  part.txt_Exp.gameObject:SetActive(data.spExp)
end

function m:OnSelect()
end

function m:OnUnSelect()
end

return m
