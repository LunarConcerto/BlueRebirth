local TeachingData = class("data.TeachingData", Data.BaseData)

function TeachingData:initialize()
  self.teachingData = {}
  self.myTeacherTab = {}
  self.myStudentTab = {}
  self.m_ranks = {}
  self.applyInfo = {}
  self.applyDetails = {}
  self.m_rmdPlayers = {}
  self.m_rmdIsTeacher = false
  self.m_otherInfos = {}
  self.m_bSetTeach = false
  self.m_bSetStudy = false
  self.applyRedState = false
end

function TeachingData:SetData(data)
  self.teachingData = data
  self:SetApplyDetails(data.Apply)
  if next(self.teachingData.Relation) ~= nil then
    if Logic.teachingLogic:CheckIsTeacher() then
      self:SetMyStudent(self.teachingData.Relation)
    else
      self:SetMyTeacher(self.teachingData.Relation[1])
    end
  end
  self.applyRedState = next(self.teachingData) ~= nil and next(self.teachingData.ApplyInfo) ~= nil
end

function TeachingData:GetData()
  return self.teachingData
end

function TeachingData:SetMyTeacher(param)
  self.myTeacherTab = {}
  if param.Uid ~= 0 and param.TeachingStatus == ETeachingState.TEACHER then
    self.myTeacherTab = {param}
  end
  self.m_bSetTeach = true
end

function TeachingData:GetMyTeacher()
  return self.myTeacherTab
end

function TeachingData:SetMyStudent(param)
  for i, v in ipairs(param) do
    if v.TeachingStatus == ETeachingState.STUDENT then
      table.insert(self.myStudentTab, v)
    else
      for j, k in ipairs(self.myStudentTab) do
        if k.Uid == v.Uid then
          table.remove(self.myStudentTab, j)
        end
      end
    end
  end
  self.m_bSetStudy = true
  self:_SortStudent(self.myStudentTab)
end

function TeachingData:_SortStudent(students)
  table.sort(students, function(data1, data2)
    if data1.CreateTime ~= data2.CreateTime then
      return data1.CreateTime > data2.CreateTime
    elseif data1.TeachingStatus ~= data2.TeachingStatus then
      return data1.TeachingStatus < data2.TeachingStatus
    elseif data1.GraduationTime ~= data2.GraduationTime then
      return data1.GraduationTime > data2.GraduationTime
    else
      return data1.Uid < data2.Uid
    end
  end)
end

function TeachingData:SaveStudents(data)
  self.myStudentTab = data
  self.m_bSetStudy = true
  self:_SortStudent(self.myStudentTab)
end

function TeachingData:GetMyStudent()
  return self.myStudentTab
end

function TeachingData:GetStudentById(uid)
  for _, teach in ipairs(self.myStudentTab) do
    if teach.UserInfo.Uid == uid then
      return teach
    end
  end
  return nil
end

function TeachingData:SetRanks(ranks)
  self.m_ranks = ranks
end

function TeachingData:GetRanks()
  return self.m_ranks
end

function TeachingData:SetRmdPlayers(players, isTeacher)
  self.m_rmdPlayers = players
  self.m_rmdIsTeacher = isTeacher
end

function TeachingData:GetRmdPlayers(isTeacher)
  if isTeacher ~= self.m_rmdIsTeacher then
    return false, nil
  end
  local num = self:_GetRmdUnitNum()
  local len = #self.m_rmdPlayers
  if len == 0 then
    return false, nil
  end
  local res = {}
  num = Mathf.Min(len, num)
  while 0 < num do
    table.insert(res, self.m_rmdPlayers[1])
    table.remove(self.m_rmdPlayers, 1)
    num = num - 1
  end
  return true, res
end

function TeachingData:_GetRmdUnitNum()
  return 3
end

function TeachingData:SetApplyDetails(info)
  if next(info) ~= nil then
    for _, v in ipairs(info) do
      if v.TeachingStatus ~= ETeachingState.NONE then
        self.applyDetails[v.Uid] = v
      end
    end
  end
  if self.teachingData.Relation ~= nil and next(self.teachingData.Relation) ~= nil then
    for _, v in ipairs(self.teachingData.Relation) do
      self.applyDetails[v.Uid] = nil
      return
    end
  end
end

function TeachingData:DeleteApplyByUid(param)
  self.applyDetails[param.applyUid] = nil
end

function TeachingData:DeleteApplyInfoByUid(param)
  for i, v in ipairs(self.teachingData.ApplyInfo) do
    if v.ApplyUid == param.applyUid then
      table.remove(self.teachingData.ApplyInfo, i)
      return
    end
  end
end

function TeachingData:GetApplyDetails()
  local applyTab = {}
  for k, v in pairs(self.applyDetails) do
    table.insert(applyTab, v)
  end
  self:_SortStudent(applyTab)
  return applyTab
end

function TeachingData:SetOtherInfo(uid, info)
  self.m_otherInfos[uid] = info
end

function TeachingData:HaveOtherInfo(uid)
  return self.m_otherInfos[uid] ~= nil
end

function TeachingData:GetOtherInfo(uid)
  return self.m_otherInfos[uid]
end

function TeachingData:HaveSetTeach()
  return self.m_bSetTeach
end

function TeachingData:HaveSetStudy()
  return self.m_bSetStudy
end

function TeachingData:SetApplyRedState()
  self.applyRedState = false
end

function TeachingData:GetApplyRedState()
  return self.applyRedState
end

return TeachingData
