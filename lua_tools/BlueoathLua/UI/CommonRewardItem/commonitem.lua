local CommonRewardItem = class("UI.CommonRewardItem")

function CommonRewardItem:initialize(...)
end

function CommonRewardItem:Init(nIndex, data, tabPart)
  self.m_index = nIndex
  self:SetData(data)
  self:SetPart(tabPart)
  self:SetWidgets()
end

function CommonRewardItem:SetWidgets()
  local widgets = self.m_part
  local txt_name = widgets.txt_name
  local img_icon = widgets.img_icon
  local raw_icon = widgets.raw_icon
  local img_frame = widgets.img_frame
  local txt_num = widgets.txt_num
  local data = self.m_data
  local display = self.m_display
  if txt_name then
    widgets.txt_name.text = display.name
  end
  if img_icon then
    UIHelper.SetImage(img_icon, display.texIcon)
  end
  if img_frame then
    UIHelper.SetImage(img_frame, QualityIcon[display.quality])
  end
  if txt_num then
    if type(display.Num) == "string" then
      txt_num.text = "x" .. display.Num
    else
      local totalNum = math.tointeger(display.Num)
      txt_num.text = "x" .. totalNum
    end
  end
end

function CommonRewardItem:SetData(data)
  self.m_data = data
  self.m_display = Logic.goodsLogic.AnalyGoods(data)
end

function CommonRewardItem:SetPart(tabPart)
  self.m_part = tabPart
end

return CommonRewardItem
