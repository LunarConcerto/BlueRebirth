NoticeHelper = {}
local noticeData

function NoticeHelper.SetNoticeData(data)
  noticeData = data
  PlayerPrefs.SetBool("noticeData_supply", data.supplyInTwelve)
  PlayerPrefs.SetBool("noticeData_wishwall", data.wishWall)
  PlayerPrefs.SetBool("noticeData_supportfleet", data.supportFleet)
  PlayerPrefs.SetBool("noticeData_build", data.build)
  PlayerPrefs.SetBool("noticeData_bath", data.bath)
  PlayerPrefs.SetBool("noticeData_mood", data.mood)
  PlayerPrefs.SetBool("noticeData_produce", data.produce)
  PlayerPrefs.SetBool("noticeData_oil", data.oil)
  PlayerPrefs.SetBool("noticeData_gold", data.gold)
  PlayerPrefs.SetBool("noticeData_freebuildship", data.freeBuildShip)
  local dotInfo = {
    push_getsupply = data.supplyInTwelve and 1 or 0,
    push_vowopen = data.wishWall and 1 or 0,
    push_buildfinish = data.build and 1 or 0,
    push_bathfinish = data.bath and 1 or 0,
    push_supportfinish = data.supportFleet and 1 or 0,
    push_freeextract = data.freeBuildShip and 1 or 0,
    push_workqueue = data.produce and 1 or 0,
    push_fullgold = data.gold and 1 or 0,
    push_fullsupply = data.oil and 1 or 0,
    push_lowmood = data.mood and 1 or 0
  }
  RetentionHelper.Retention("Push.local", dotInfo)
end

function NoticeHelper.GetNoticeData()
  local data = {}
  data.supplyInTwelve = PlayerPrefs.GetBool("noticeData_supply", true)
  data.supplyInEighteen = PlayerPrefs.GetBool("noticeData_supply", true)
  data.wishWall = PlayerPrefs.GetBool("noticeData_wishwall", true)
  data.supportFleet = PlayerPrefs.GetBool("noticeData_supportfleet", true)
  data.build = PlayerPrefs.GetBool("noticeData_build", true)
  data.bath = PlayerPrefs.GetBool("noticeData_bath", true)
  data.mood = PlayerPrefs.GetBool("noticeData_mood", true)
  data.produce = PlayerPrefs.GetBool("noticeData_produce", true)
  data.oil = PlayerPrefs.GetBool("noticeData_oil", true)
  data.gold = PlayerPrefs.GetBool("noticeData_gold", true)
  return data
end
