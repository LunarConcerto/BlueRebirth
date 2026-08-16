local EmailLogic = class("logic.EmailLogic")

function EmailLogic:initialize()
  self:ResetData()
end

function EmailLogic:ResetData()
  self.fullTip = true
  self.m_showDetail = false
  local reducefunc = function(value)
    return Mathf.ToInt(tonumber(value) * 0.01) .. "%"
  end
  self.m_param2func = {
    teaching_stage_id = EmailLogic.GetTeachStage,
    teaching_stage_ratio = reducefunc,
    teaching_task_id = EmailLogic.GetTeachTask,
    teaching_star_num = EmailLogic.GetTeachStar,
    teaching_star_ratio = reducefunc,
    teaching_level_ratio = reducefunc,
    item_name = EmailLogic.GetItemName
  }
end

function EmailLogic:SetShowDetail(isOn)
  self.m_showDetail = isOn
end

function EmailLogic:GetShowDetail()
  return self.m_showDetail
end

function EmailLogic:SetFullTag(param)
  self.fullTip = param
end

function EmailLogic:IsMailFull()
  local num = Data.emailData:GetDeleteNum()
  local full = 0 < num and self.fullTip
  return full, num
end

function EmailLogic:ParseEmail(mail)
  if mail.TempLateId > 0 then
    local mailConfig = configManager.GetDataById("config_parameter_mail", mail.TempLateId)
    local msg = mailConfig.mail_content
    if #mail.Params ~= 0 then
      local paramArr = {}
      for _, param in ipairs(mail.Params) do
        local ok, desc = self:GetInfoByParam(param.Key, param.Value)
        if ok then
          table.insert(paramArr, desc)
        else
          table.insert(paramArr, param.Value)
        end
      end
      msg = string.format(msg, table.unpack(paramArr))
    end
    return mailConfig.mail_title, msg
  else
    return mail.Subject, mail.Content
  end
end

function EmailLogic:_IsExpireMail(mailData)
  print("_IsExpireMail endTime : " .. tostring(mailData.DeleteTime) .. " serverTime " .. tostring(time.getSvrTime()))
  if mailData.DeleteTime == 0 then
    return false
  end
  local surplusTime = tonumber(mailData.DeleteTime) - tonumber(time.getSvrTime())
  return surplusTime <= 0
end

function EmailLogic:GetActiveMailList()
  local mailList = Data.emailData:GetMailList()
  local validMailList = {}
  for i, v in ipairs(mailList) do
    local isExpire = self:_IsExpireMail(v)
    if isExpire == false then
      table.insert(validMailList, v)
    end
  end
  return validMailList
end

function EmailLogic:GetInfoByParam(key, value)
  if self.m_param2func[key] then
    local desc = self.m_param2func[key](value)
    return true, desc
  end
  return false, ""
end

function EmailLogic:SortEmail(tabMailList)
  local tabTemp = {}
  for k, v in pairs(tabMailList) do
    tabTemp[#tabTemp + 1] = v
  end
  table.sort(tabTemp, function(data1, data2)
    if data1.haveRead ~= data2.haveRead then
      return data1.haveRead < data2.haveRead
    elseif data1.haveItem ~= data2.haveItem then
      return data1.haveItem > data2.haveItem
    elseif data1.IsGotReawrd ~= data2.IsGotReawrd then
      return data1.IsGotReawrd < data2.IsGotReawrd
    else
      return data1.ReceiveTime > data2.ReceiveTime
    end
  end)
  return tabTemp
end

function EmailLogic:FormatData(time)
  return "[" .. os.date("%Y-%m-%d", time) .. "]"
end

function EmailLogic:FormatTime(time)
  return os.date("%Y-%m-%d\t %H:%M", time)
end

function EmailLogic:Introduce(content, num)
  content = RichTextUtil.Remove(content)
  if num < utf8.len(content) then
    return utf8.sub(content, 1, num) .. "......"
  else
    return content
  end
end

function EmailLogic:GetMailById(tabMailList, mid)
  for k, v in pairs(tabMailList) do
    if v.Mid == mid then
      return v
    end
  end
  logError("\230\156\170\230\137\190\229\136\176\231\155\184\229\133\179\233\130\174\228\187\182\228\191\161\230\129\175")
  return nil
end

function EmailLogic:IsContentFull(content)
  if utf8.len(content) > 50 then
    return true
  else
    return false
  end
end

function EmailLogic:HaveItem()
end

function EmailLogic:HaveItemGet()
end

function EmailLogic:HaveTemplate()
end

function EmailLogic:FormatItem(items)
  local res = {}
  for i, info in ipairs(items) do
    local temp = {}
    temp.Type = info.Type
    temp.ConfigId = info.Id
    temp.Num = info.Num
    res[i] = temp
  end
  return res
end

function EmailLogic:CanFetchItem(mid)
  local tabReward = {}
  local mailInfoList = Data.emailData:GetMailList()
  for _, mailInfo in pairs(mailInfoList) do
    if #mailInfo.Items > 0 and mailInfo.IsGotReawrd == 0 then
      if mid ~= nil then
        if mailInfo.Mid == mid then
          for i = 1, #mailInfo.Items do
            table.insert(tabReward, {
              mailInfo.Items[i].Type,
              mailInfo.Items[i].Id,
              mailInfo.Items[i].Num
            })
          end
          break
        end
      else
        for i = 1, #mailInfo.Items do
          table.insert(tabReward, {
            mailInfo.Items[i].Type,
            mailInfo.Items[i].Id,
            mailInfo.Items[i].Num
          })
        end
      end
    end
  end
  if #tabReward == 0 then
    return MailRewardStatus.NotAward
  elseif Logic.rewardLogic:CanGotReward(tabReward, true) then
    return MailRewardStatus.GetAward
  else
    return MailRewardStatus.BagFull
  end
end

function EmailLogic:HaveMailAndNoGotReward(tid)
  local data = Data.emailData:GetMailList()
  for _, v in ipairs(data) do
    if v.TempLateId == tid then
      return v.IsGotReawrd == 0
    end
  end
  return false
end

function EmailLogic:GetIcon(index, id)
  return Logic.goodsLogic:GetIcon(id, index)
end

function EmailLogic:GetQuality(index, id)
  return Logic.goodsLogic:GetQuality(id, index)
end

function EmailLogic.GetTeachStage(value)
  local stageId = tonumber(value)
  local group = Logic.teachingLogic:GetExamConfig(stageId)
  return group and group.title or ""
end

function EmailLogic.GetTeachTask(value)
  local taskId = tonumber(value)
  local task = Logic.taskLogic:GetTaskConfig(taskId, TaskType.TeachingDaily)
  return task and task.title or ""
end

function EmailLogic.GetTeachStar(value)
  local star = tonumber(value)
  local config = configManager.GetDataById("config_parameter", 264).arrValue
  return config[star] and UIHelper.GetString(config[star]) or ""
end

function EmailLogic.GetItemName(value)
  local itemTid = tonumber(value)
  local itemConf = Logic.bagLogic:GetItemByConfig(itemTid)
  return itemConf.name
end

return EmailLogic
