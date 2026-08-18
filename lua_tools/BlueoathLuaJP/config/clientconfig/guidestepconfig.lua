local GuideStepConfig = {}
require("game.Guide.Guidedefine")
GuideStepConfig.GuideItemList = {
  [10002] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PLOT,
        200
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "LoginPage"
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {200}
    },
    Note = "\231\172\172\228\184\128\229\156\186\230\136\152\230\150\151\229\137\141\231\154\132\229\137\167\230\131\133\229\133\179\239\188\154\231\169\134\228\188\175\232\131\140\230\153\175\228\187\139\231\187\141"
  },
  [20010] = {
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    Note = "\231\173\137\229\190\133\232\191\155\229\133\165MainStage"
  },
  [20011] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetCanPlayLogin,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PLOT,
        201
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {201}
    },
    Note = "\231\172\172\228\184\128\229\156\186\230\136\152\230\150\151\229\144\142\231\154\132\229\137\167\230\131\133\229\133\179\239\188\154\229\137\167\230\131\133\229\176\134\230\151\182\233\151\180\232\161\148\230\142\165\228\185\139\230\149\176\230\156\136\229\144\142\231\154\132\230\137\128\231\189\151\233\151\168\229\159\186\229\156\176"
  },
  [21021] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PLOT,
        100
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "LoginPage"
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.PlotEnd,
      {101}
    },
    Note = "\229\186\143\231\171\160\239\188\140\231\172\172\228\184\128\232\138\130\229\137\167\230\131\133"
  },
  [21101] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      }
    },
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetCanPlayLogin,
        false
      }
    },
    Note = "\228\184\173\230\150\173\229\144\142\233\156\128\232\166\129\229\133\136\231\173\137\229\190\133main stage\232\191\155\229\133\165\230\137\141\232\131\189\229\190\128\228\184\139\230\137\167\232\161\140"
  },
  [21022] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      2
    },
    Note = "\229\186\143\231\171\160\239\188\140\231\172\1722\232\138\130\232\138\130\233\128\154\232\191\135"
  },
  [30] = {Note = "\231\169\186"},
  [40] = {Note = "\231\169\186"},
  [22001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "CreateCharacterPage"
      }
    },
    WaitStartPoint = TRIGGER_TYPE.ChangeNameOk,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "CreateCharacterPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black"
      }
    },
    Note = "\231\142\169\229\174\182\232\181\183\229\144\141"
  },
  [23001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        108
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "CreateCharacterPage"
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {119}
    },
    Note = "\229\186\143\231\171\160, \232\161\165\228\184\128\228\184\170\230\153\166\230\156\14890\229\137\141"
  },
  [70] = {Note = "\231\169\186"},
  [23002] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.ItemUpdate
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\186\143\231\171\160\239\188\140\231\172\172\228\184\137\232\138\130\233\128\154\232\191\135"
  },
  [90] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SearchCamModelToNear
      }
    },
    Note = "\229\186\143\231\171\160,\231\172\172\229\155\155\232\138\130 \230\136\152\230\150\151\229\137\141 120~124\230\174\181"
  },
  [10101] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ENTER_NORMAL_BATTLE,
        {999, 100}
      },
      {
        GUIDE_BEHAVIOUR.ClosePagesByLayer
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {1, 1000}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.BATTLE_CAN_COST_TIME,
        false
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\t\229\188\128\229\144\175"
  },
  [10102] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "map_mask"
      }
    },
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.StartFPSCheck
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "enemy01"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.Switch3DCamMode,
        0
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "enemy01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_01",
          false
        }
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tenemy01"
  },
  [10103] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "enemy02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "enemy02"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SwitchKeyboard,
        false
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tenemy02"
  },
  [121] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "camera_01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_601",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    CompID = GUIDE_COMPONENT_ID.camera_01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.Switch3DCamMode,
        1
      }
    },
    Note = "camera_01"
  },
  [122] = {
    WaitStartPoint = {
      TRIGGER_TYPE.Search3DCamModeSwithDone,
      1
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "camera_01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_601",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "camera_02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_602",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.camera_01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.Switch3DCamMode,
        2
      }
    },
    Note = "camera_02"
  },
  [123] = {
    WaitStartPoint = {
      TRIGGER_TYPE.Search3DCamModeSwithDone,
      2
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "camera_02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_602",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "camera_03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_603",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.camera_01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.Switch3DCamMode,
        3
      }
    },
    Note = "camera_03"
  },
  [124] = {
    WaitStartPoint = {
      TRIGGER_TYPE.Search3DCamModeSwithDone,
      3
    },
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "camera_03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_603",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "camera_04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_604",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "camera_04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_604",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SwitchKeyboard,
        true
      }
    },
    Note = "camera_04"
  },
  [10104] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "turn01"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        {
          "GuideSettingsPage",
          nil,
          2,
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {2, 600}
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.OnPageHide,
      "GuideSettingsPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {2, 300}
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "turn01"
      },
      {
        GUIDE_BEHAVIOUR.ReopenBattleSubUI,
        "MainRoot/BattlePage/OperationGroup"
      },
      {
        GUIDE_BEHAVIOUR.SwitchKeyboard,
        true
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tturn01"
  },
  [11101] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "rudder01"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        1
      }
    },
    WaitEndPoint = TRIGGER_TYPE.OpeTurn,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        1
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "rudder01"
      },
      {
        GUIDE_BEHAVIOUR.PART_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\trudder01"
  },
  [11201] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "rudder02"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        1
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", true}
      }
    },
    WaitEndPoint = TRIGGER_TYPE.OpeTurn,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", false}
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        1
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "rudder02"
      },
      {
        GUIDE_BEHAVIOUR.PART_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\trudder01"
  },
  [11301] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "left_right01"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        159
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", true}
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TurnBtnTrick"
      }
    },
    WaitEndPoint = TRIGGER_TYPE.OpeTurn,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", false}
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        159
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "left_right01"
      },
      {
        GUIDE_BEHAVIOUR.PART_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.SwitchKeyboard,
        true
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\trudder01"
  },
  [11401] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "left_right02"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        159
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", true}
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TurnBtnTrick"
      }
    },
    WaitEndPoint = TRIGGER_TYPE.OpeTurn,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", false}
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        159
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "left_right02"
      },
      {
        GUIDE_BEHAVIOUR.PART_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.SwitchKeyboard,
        true
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\trudder01"
  },
  [12011] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TurnBtnTrick"
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\trudder01\tWaitTime"
  },
  [160] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PART_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "shift_gears01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_08",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "shift_gears01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_08",
          false
        }
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tshift_gears01"
  },
  [13101] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "shift_gears02"
      }
    },
    CompID = GUIDE_COMPONENT_ID.CHANGE_SPEED,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "shift_gears02"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SET_PLAYER_SPEED,
        2
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tshift_gears02"
  },
  [13201] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "shift_gears03"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        8
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", true}
      }
    },
    WaitEndPoint = TRIGGER_TYPE.OpeSpeed,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {"InputTrick", false}
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        8
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "shift_gears03"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SET_PLAYER_SPEED,
        2
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tshift_gears03"
  },
  [14021] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\231\173\137\229\190\133\231\142\169\229\174\182\231\167\187\229\138\168\230\131\133\229\134\181"
  },
  [190] = {
    WaitStartPoint = TRIGGER_TYPE.EnemyInSight,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "encounter01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_11",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "encounter01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_11",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tencounter01"
  },
  [15011] = {
    WaitEndPoint = TRIGGER_TYPE.EnterFightInstantly,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "map_mask"
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        1
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        2
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        3
      }
    },
    Note = "\230\136\152\230\150\151\233\152\182\230\174\181\228\184\141\232\131\189\228\189\191\231\148\168\233\177\188\233\155\183"
  },
  [15012] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_FIGHT,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "distance01"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "distance01"
      }
    },
    Note = "\230\136\152\229\156\186\229\156\136\232\175\180\230\152\142\tdistance01"
  },
  [15013] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "distance02"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "distance02"
      }
    },
    Note = "\230\136\152\229\156\186\229\156\136\232\175\180\230\152\142\tdistance02"
  },
  [15014] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "distance03"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "distance03"
      }
    },
    Note = "\230\136\152\229\156\186\229\156\136\232\175\180\230\152\142\tdistance03"
  },
  [15015] = {
    WaitStartPoint = TRIGGER_TYPE.MAINGUN_ENTER_RANGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "aim01"
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "aim01"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "aim02_1"
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        1
      }
    },
    Note = "\228\184\187\231\130\174\231\158\132\229\135\134\229\156\136\232\175\180\230\152\142\taim01"
  },
  [15016] = {
    WaitStartPoint = TRIGGER_TYPE.MAINGUN_AIM,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "aim02_1"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "aim02"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "aim02"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_16",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "main_gun_hit"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      }
    },
    Note = "\228\184\187\231\130\174\231\158\132\229\135\134\229\156\136\232\175\180\230\152\142\taim02"
  },
  [15017] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.MAINGUN_FIRE
      }
    },
    WaitStartPoint = TRIGGER_TYPE.MainGunFire,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        GUIDE_COMPONENT_ID.MAINGUN_FIRE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "main_gun_hit"
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [15018] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.AttackAnimEnd,
      {
        skillType = SkillAnimType.MainGun,
        isSelf = 1
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [271] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "hurt01"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        2
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "hurt01"
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [272] = {
    WaitStartPoint = {
      TRIGGER_TYPE.CouldRequestSkill,
      SkillType.MainGun
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "hurt02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_19",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        1
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "hurt02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_19",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [17021] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      100
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CheckFPSResult
      }
    },
    Note = "\231\187\147\230\157\159fleet\239\188\15490050\230\136\152\230\150\151"
  },
  [290] = {
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\231\173\137\229\190\133\229\155\158\229\136\176\228\184\187\229\156\186\230\153\175"
  },
  [300] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        128
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {130, 131}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    Note = "\229\137\167\230\131\133\239\188\140128"
  },
  [309] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_20",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_20",
          false
        }
      }
    },
    Note = "equip_re01"
  },
  [3091] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re02,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          false
        }
      }
    },
    Note = "equip_re02"
  },
  [40013] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_48",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re03,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_48",
          false
        }
      }
    },
    Note = "equip_re03"
  },
  [40014] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_49",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re04,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_49",
          false
        }
      }
    },
    Note = "equip_re04"
  },
  [40015] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_605",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re05,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_605",
          false
        }
      }
    },
    Note = "equip_re05"
  },
  [40016] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_25",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re06,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_25",
          false
        }
      }
    },
    Note = "equip_re06"
  },
  [40017] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_26",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.equip_re07
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.OnPageHide,
      "EquipChangePage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        GUIDE_COMPONENT_ID.equip_re07
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_26",
          false
        }
      }
    },
    Note = " equip_re07"
  },
  [316] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re08"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_27",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        167
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "DockPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        167
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re08"
      }
    },
    Note = " equip_re08 return1"
  },
  [317] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        206
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re09"
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "HomePage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        206
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_re09"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_27",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = " equip_re09 return2"
  },
  [318] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wait_for_expedition"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_28",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CopyPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wait_for_expedition"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_28",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129\230\140\137\233\146\174"
  },
  [320] = {
    CompID = GUIDE_COMPONENT_ID.PlotCopyPage_1,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "plotcopy01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_29",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "PlotCopyDetailPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "plotcopy01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_29",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160 plotcopy01"
  },
  [330] = {
    CompID = GUIDE_COMPONENT_ID.chapterPlot_5,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "chapterPlot05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_30",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "LevelDetailsPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "chapterPlot05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_30",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160\231\172\172\228\186\148\229\133\179"
  },
  [340] = {
    CompID = GUIDE_COMPONENT_ID.leveldetails_chuzheng,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "leveldetails01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_31",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "leveldetails01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_31",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\229\137\175\230\156\172\231\149\140\233\157\162\229\135\186\229\190\129"
  },
  [33001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SetFlagShip,
        1021051
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.LEFT_FLEET_BTN,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\232\136\176\233\152\159\tformation"
  },
  [33002] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "FleetPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetFleetPageCanMove,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "listed"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_34",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.GIRL_IN_BATTLE,
      2
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "listed"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_34",
          false
        }
      }
    },
    Note = "\230\139\150\230\139\189\228\184\138\233\152\181\tlisted"
  },
  [33003] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        282
      },
      {
        GUIDE_BEHAVIOUR.SHIP_CANT_DRAG,
        true
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GirlInfo"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        282
      },
      {
        GUIDE_BEHAVIOUR.SHIP_CANT_DRAG,
        false
      }
    },
    Note = "\231\130\185\229\135\187\229\165\165\229\133\139\229\133\176\230\137\147\229\188\128\232\163\133\229\164\135\231\149\140\233\157\162"
  },
  [40011] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.LEFT_FLEET_BTN,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          false
        }
      }
    },
    Note = "\230\155\180\230\141\162\228\184\187\231\130\174-\231\130\185\229\135\187\228\184\187\231\149\140\233\157\162\232\136\176\233\152\159\230\140\137\233\146\174"
  },
  [40012] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        282
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GirlInfo"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        282
      }
    },
    Note = "\231\130\185\229\135\187\229\165\165\229\133\139\229\133\176\230\137\147\229\188\128\232\163\133\229\164\135\231\149\140\233\157\162"
  },
  [50011] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.LEFT_FLEET_BTN,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          false
        }
      }
    },
    Note = "\230\155\180\230\141\162\228\184\187\231\130\174-\231\130\185\229\135\187\228\184\187\231\149\140\233\157\162\232\136\176\233\152\159\230\140\137\233\146\174"
  },
  [50012] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        282
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GirlInfo"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        282
      }
    },
    Note = "\231\130\185\229\135\187\229\165\165\229\133\139\229\133\176\230\137\147\229\188\128\232\163\133\229\164\135\231\149\140\233\157\162"
  },
  [60001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.LEFT_FLEET_BTN,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          false
        }
      }
    },
    Note = "\230\155\180\230\141\162\228\184\187\231\130\174-\231\130\185\229\135\187\228\184\187\231\149\140\233\157\162\232\136\176\233\152\159\230\140\137\233\146\174"
  },
  [60002] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        282
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GirlInfo"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        282
      }
    },
    Note = "\231\130\185\229\135\187\229\165\165\229\133\139\229\133\176\230\137\147\229\188\128\232\163\133\229\164\135\231\149\140\233\157\162"
  },
  [70001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.LEFT_FLEET_BTN,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "formation"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_33",
          false
        }
      }
    },
    Note = "\230\155\180\230\141\162\228\184\187\231\130\174-\231\130\185\229\135\187\228\184\187\231\149\140\233\157\162\232\136\176\233\152\159\230\140\137\233\146\174"
  },
  [70002] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        282
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GirlInfo"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_show"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_21",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        282
      }
    },
    Note = "\231\130\185\229\135\187\229\165\165\229\133\139\229\133\176\230\137\147\229\188\128\232\163\133\229\164\135\231\149\140\233\157\162"
  },
  [303] = {
    CompID = GUIDE_COMPONENT_ID.fleet_close,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "fleet_close"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_35",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "fleet_close"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_35",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\228\187\142\231\188\150\233\152\159\231\149\140\233\157\162\232\191\148\229\155\158"
  },
  [304] = {
    CompID = GUIDE_COMPONENT_ID.ship_head_bu,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "ship_head_bu"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_36",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "ship_head_bu"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_36",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\231\130\185\229\135\187\232\191\155\229\133\165\232\174\190\231\189\174\233\157\162\230\157\191"
  },
  [305] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "LvliPage"
    },
    CompID = GUIDE_COMPONENT_ID.secretarial_ship,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "secretarial_ship"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_37",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "secretarial_ship"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_37",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\155\180\230\141\162\231\167\152\228\185\166\232\136\176"
  },
  [306] = {
    CompID = GUIDE_COMPONENT_ID.common_select,
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CommonSelectPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "common_select"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_38",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "common_select"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_38",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\155\180\230\141\162\231\167\152\228\185\166\232\136\176"
  },
  [307] = {
    CompID = GUIDE_COMPONENT_ID.common_select_ok,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "common_select_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_39",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "common_select_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_39",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\155\180\230\141\162\231\167\152\228\185\166\232\136\176"
  },
  [308] = {
    CompID = GUIDE_COMPONENT_ID.BACKBTN,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "btn_close"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_40",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "btn_close"
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_40",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\232\191\148\229\155\158\229\136\176\228\184\187\231\149\140\233\157\162"
  },
  [490] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wait_for_expedition02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_41",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CopyPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wait_for_expedition02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_41",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129\230\140\137\233\146\174 \231\130\185\231\172\172\229\133\173\229\133\179"
  },
  [500] = {
    CompID = GUIDE_COMPONENT_ID.PlotCopyPage_1,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "plotcopy02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_42",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "PlotCopyDetailPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "plotcopy02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_42",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160 \231\130\185\231\172\172\229\133\173\229\133\179"
  },
  [510] = {
    CompID = GUIDE_COMPONENT_ID.chapterPlot_6,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "chapterPlot06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_43",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "LevelDetailsPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "chapterPlot06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_43",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160\231\172\172\229\133\173\229\133\179 "
  },
  [520] = {
    CompID = GUIDE_COMPONENT_ID.leveldetails_chuzheng,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "leveldetails02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_44",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "leveldetails02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_44",
          false
        }
      }
    },
    Note = "\229\137\175\230\156\172\231\149\140\233\157\162\229\135\186\229\190\129"
  },
  [341] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {1, 59}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.BATTLE_CAN_COST_TIME,
        false
      }
    },
    Note = "\232\191\155\229\133\165\230\136\152\230\150\1512\239\188\140\229\137\175\230\156\172\230\151\182\233\151\180\230\154\130\229\129\156"
  },
  [342] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    Note = "\232\191\155\229\133\165\230\181\183\229\159\159"
  },
  [343] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        132
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {132}
    },
    Note = "\232\167\166\229\143\145\229\137\167\230\131\133 132"
  },
  [344] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\230\136\152\230\150\151\233\152\182\230\174\181\228\184\141\232\131\189\228\189\191\231\148\168\233\177\188\233\155\183"
  },
  [345] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {4, 90053}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    Note = "\232\167\166\229\143\145\229\137\167\230\131\133"
  },
  [346] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        133
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {133}
    },
    Note = "\229\137\167\230\131\133133"
  },
  [347] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    WaitStartPoint = TRIGGER_TYPE.EnterFightInstantly,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        2
      }
    },
    Note = "\230\136\152\230\150\151\233\152\182\230\174\181\228\184\141\232\131\189\228\189\191\231\148\168\233\177\188\233\155\183"
  },
  [348] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      6
    },
    Note = "\231\187\147\230\157\159fleet\239\188\15490053\230\136\152\230\150\151"
  },
  [349] = {
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    Note = "\228\187\142\229\137\175\230\156\172\233\128\137\230\139\169\231\149\140\233\157\162\232\191\148\229\155\158"
  },
  [350] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "HomePage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_46",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_46",
          false
        }
      }
    },
    Note = "equip_Str01"
  },
  [360] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_47",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1.5
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re02,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_47",
          false
        }
      }
    },
    Note = "equip_Str02"
  },
  [50013] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_48",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        162
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {
        "GirlInfo",
        "Equipment_Page"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        162
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_48",
          false
        }
      }
    },
    Note = "equip_Str03"
  },
  [50014] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_49",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1.5
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_re04,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_49",
          false
        }
      }
    },
    Note = "equip_Str04"
  },
  [50015] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_50",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_Str05,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_50",
          false
        }
      }
    },
    Note = "equip_Str05"
  },
  [669] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str07_1"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_52",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.btn_Retrofit,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str07_1"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_52",
          false
        }
      }
    },
    Note = "equip_Str05_1"
  },
  [50016] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_201",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        169
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.EquipEnhaceLv,
      3
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        169
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_201",
          false
        }
      }
    },
    Note = "equip_Str06"
  },
  [50017] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str09_1"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_54",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_Str09_1,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str09_1"
      }
    },
    Note = " equip_Str09_1"
  },
  [420] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str09"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        167
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "DockPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        167
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str09"
      }
    },
    Note = " equip_Str09"
  },
  [430] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str09_dockReturn"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        206
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "HomePage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        206
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str09_dockReturn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_54",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = " equip_Str09"
  },
  [710] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wait_for_expedition03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {
        "CopyPage",
        "PlotCopyPage"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wait_for_expedition03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129\230\140\137\233\146\174"
  },
  [720] = {
    CompID = GUIDE_COMPONENT_ID.PlotCopyPage_1,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "plotcopy03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_56",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "PlotCopyDetailPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "plotcopy03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_56",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160"
  },
  [1191] = {
    CompID = GUIDE_COMPONENT_ID.chapterPlot_7,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "chapterPlot07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_57",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "LevelDetailsPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "chapterPlot07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_57",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160\231\172\1727\229\133\179"
  },
  [1192] = {
    CompID = GUIDE_COMPONENT_ID.leveldetails_chuzheng,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "leveldetails03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_58",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "leveldetails03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_58",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\229\137\175\230\156\172\231\149\140\233\157\162\229\135\186\229\190\129"
  },
  [750] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {1, 69}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.BATTLE_CAN_COST_TIME,
        false
      }
    },
    Note = "\232\191\155\229\133\165\230\136\152\230\150\1512\239\188\140\229\137\175\230\156\172\230\151\182\233\151\180\230\154\130\229\129\156"
  },
  [760] = {Note = "\231\169\186"},
  [770] = {Note = "\231\169\186"},
  [810] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {4, 90056}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        135
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    Note = "\229\137\167\230\131\133\239\188\140135"
  },
  [820] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {135}
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\230\129\162\229\164\141\230\184\184\230\136\143"
  },
  [830] = {
    WaitStartPoint = TRIGGER_TYPE.EnterFightInstantly,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        1
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "maingun"
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        2
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        3
      },
      {
        GUIDE_BEHAVIOUR.NpcCanAttack,
        false
      }
    },
    Note = "\230\136\152\230\150\151\233\152\182\230\174\181\228\184\141\232\131\189\228\189\191\231\148\168\233\177\188\233\155\183"
  },
  [840] = {
    WaitStartPoint = TRIGGER_TYPE.MAINGUN_ENTER_RANGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        1
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "maingun"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      }
    },
    Note = "\232\191\155\229\133\165\229\176\132\231\168\139"
  },
  [850] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "main_gun_hit01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_60",
          true
        }
      }
    },
    WaitStartPoint = TRIGGER_TYPE.MAINGUN_AIM,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    Note = "\232\191\155\229\133\165\229\176\132\231\168\139"
  },
  [860] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [870] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        9
      }
    },
    WaitStartPoint = TRIGGER_TYPE.MainGunFire,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "main_gun_hit01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_61",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.NpcCanAttack,
        true
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        9
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.AttackAnimEnd,
      {
        skillType = SkillAnimType.MainGun,
        isSelf = 1
      }
    },
    Note = "\231\173\137\229\190\133\232\191\155\229\133\165\231\130\174\229\135\187\231\187\147\230\158\156"
  },
  [880] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        136
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {136}
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        2
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        3
      }
    },
    Note = "\229\137\167\230\131\133\239\188\140136"
  },
  [890] = {
    WaitStartPoint = {
      TRIGGER_TYPE.AttackAnimEnd,
      {
        skillType = SkillAnimType.MainGun,
        isSelf = 0
      }
    },
    Note = "\229\137\167\230\131\133\239\188\1408031"
  },
  [900] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        137
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\137\167\230\131\133\239\188\1408031"
  },
  [910] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.AddNewShip
      }
    },
    Note = "\229\138\160\229\133\165\231\165\158\233\128\154"
  },
  [920] = {Note = "\231\169\186"},
  [930] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {138}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        1
      },
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        3
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.PART_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.NpcCanAttack,
        false
      }
    },
    Note = "Npc\228\184\141\232\131\189\230\148\187\229\135\187"
  },
  [940] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.RefreshTorpedoBtn
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "TorpedoMask",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SetObjActive,
        {
          "MainRoot/BattlePage/BattleOpeGroup/TorpedoUIState0/Box",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        2
      }
    },
    WaitStartPoint = TRIGGER_TYPE.TORPEDO_IN_RINGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "torpedo"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_61",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "torpedo"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_61",
          false
        }
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\ttorpedo"
  },
  [16001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.RefreshTorpedoBtn
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "TorpedoMask",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SetObjActive,
        {
          "MainRoot/BattlePage/BattleOpeGroup/TorpedoUIState0/Box",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        2
      }
    },
    WaitStartPoint = TRIGGER_TYPE.TORPEDO_IN_RINGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "TorpedoMask",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SetObjActive,
        {
          "MainRoot/BattlePage/BattleOpeGroup/TorpedoUIState0/Box",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "TorpedoBtnTrick_obj",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.TORPEDO_FILL,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "torpedo_click"
      }
    },
    CompID = GUIDE_COMPONENT_ID.TORPEDO,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "TorpedoBtnTrick_obj",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "TorpedoBtnTrick",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "torpedo_click"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\136\135\230\141\162\233\177\188\233\155\183"
  },
  [16002] = {
    WaitStartPoint = {
      TRIGGER_TYPE.AttackAnimEnd,
      {
        skillType = SkillAnimType.Torpedo,
        isSelf = 1
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.AttackAnimEnd,
      {
        skillType = SkillAnimType.Torpedo,
        isSelf = 1
      }
    },
    Note = "\231\173\137\229\190\133\232\191\155\229\133\165\233\177\188\233\155\183\231\187\147\230\158\156"
  },
  [16003] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "torpedo_number"
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "torpedo_number"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        1
      }
    },
    Note = "\229\137\169\228\189\153\233\177\188\233\155\183\230\149\176\232\175\180\230\152\142"
  },
  [990] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ServiceReturn,
        "copy.PassBase"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.NpcCanAttack,
        true
      },
      {
        GUIDE_BEHAVIOUR.TORPEDO_FILL,
        false
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      7
    },
    Note = "\231\187\147\230\157\159\230\136\152\230\150\151"
  },
  [1000] = {
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    Note = "\229\155\158\229\136\176\228\184\187\231\149\140\233\157\162"
  },
  [1010] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.PLOT,
        139
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\137\167\230\131\133 139"
  },
  [1020] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {139}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      }
    },
    Note = "\229\137\167\230\131\133\239\188\140139\t\231\187\147\230\157\159"
  },
  [1030] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.UnLockShip,
        10210111
      }
    },
    CompID = GUIDE_COMPONENT_ID.home_ship_btn,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "home_ship_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_66",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "home_ship_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_66",
          false
        }
      }
    },
    Note = "home_ship_btn"
  },
  [1040] = {
    CompID = GUIDE_COMPONENT_ID.dockpage_ship,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dockpage_ship"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_67",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GirlInfo"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dockpage_ship"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_67",
          false
        }
      }
    },
    Note = "dockpage_ship"
  },
  [60003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "GirlShowPage"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_141",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        179
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {
        "GirlInfo",
        "GirlShowPage"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        179
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "GirlShowPage"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_141",
          false
        }
      }
    },
    Note = "equip_\230\138\128\232\131\189\228\185\16601"
  },
  [60004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "btn_levelup"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_132",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.btn_levelup
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "ShipLevelupPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        GUIDE_COMPONENT_ID.btn_levelup
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "btn_levelup"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_132",
          false
        }
      }
    },
    Note = "equip_\230\138\128\232\131\189\228\185\16602"
  },
  [60005] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "btn_levelup01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_133",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.btn_levelup01
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.ShipLV5
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        GUIDE_COMPONENT_ID.btn_levelup01
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "btn_levelup01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_133",
          false
        }
      }
    },
    Note = "equip_\230\138\128\232\131\189\228\185\16603"
  },
  [60006] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ShipLevelupPage"
      }
    },
    Note = "equip_\230\138\128\232\131\189\228\185\16603"
  },
  [1050] = {
    CompID = GUIDE_COMPONENT_ID.QIANGHUA_BTN,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ShipLevelupPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "qianghua_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_68",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {
        "GirlInfo",
        "Strengthen_Page"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "qianghua_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_68",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\229\188\186\229\140\150\230\140\137\233\146\174"
  },
  [1060] = {
    CompID = GUIDE_COMPONENT_ID.Strengthen_add,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "strengthen_ship"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_69",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "strengthen_ship"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_69",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\233\128\137\230\139\169\230\136\152\229\167\172\231\180\160\230\157\144"
  },
  [1100] = {
    CompID = GUIDE_COMPONENT_ID.Qianghua_Confirm_BTN,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Strengthen_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_73",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitServiceEvent,
        {
          GuideServiceEvent.EventHeroIntensify,
          1
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_73",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Strengthen_btn"
      }
    },
    Note = "\231\130\185\229\135\187\229\188\186\229\140\150"
  },
  [1110] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "EquipDismantleTip"
    },
    Note = "\231\173\137\229\190\133\229\188\186\229\140\150\231\187\147\230\158\156"
  },
  [1120] = {
    CompID = GUIDE_COMPONENT_ID.EquipDismantleTip_ok,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equipdismantletip_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_74",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equipdismantletip_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_74",
          false
        }
      }
    },
    Note = "\231\161\174\229\174\154\230\139\134\232\167\163"
  },
  [1130] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.WaitTime,
        2.5
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "GetRewardsPage"
      }
    },
    Note = "\231\161\174\229\174\154\230\139\134\232\167\163 \229\174\140\230\136\144"
  },
  [70003] = {
    CompID = GUIDE_COMPONENT_ID.tupo,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "GetRewardsPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "tupo_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_75",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {"GirlInfo", "Break_Page"}
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "GetRewardsPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "tupo_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_75",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\231\170\129\231\160\180\230\140\137\233\146\174"
  },
  [70004] = {
    CompID = GUIDE_COMPONENT_ID.tupo_Confirm,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "tupo_Confirm"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_76",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitServiceEvent,
        {
          GuideServiceEvent.EventHeroAdvanceLv,
          1
        }
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "GetRewardsPage"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "tupo_Confirm"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_76",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "GetRewardsPage"
      }
    },
    Note = "\231\130\185\229\135\187\231\170\129\231\160\180"
  },
  [70005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "GetRewardsPage"
      }
    },
    Note = "\231\173\137\229\190\133\231\170\129\231\160\180\231\187\147\230\158\156"
  },
  [70006] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "btn_close_tupo"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_77",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        167
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "FleetPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        167
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "btn_close_tupo"
      }
    },
    Note = " \228\187\142\228\191\161\230\129\175\231\149\140\233\157\162\232\191\148\229\155\158"
  },
  [1171] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        206
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "btn_close_tupo01"
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "HomePage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        206
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "btn_close_tupo01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = " \228\187\142\228\191\161\230\129\175\231\149\140\233\157\162\232\191\148\229\155\1582"
  },
  [1180] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wait_for_expedition03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CopyPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wait_for_expedition03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129\230\140\137\233\146\174"
  },
  [1190] = {
    CompID = GUIDE_COMPONENT_ID.PlotCopyPage_1,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "plotcopy02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_42",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "PlotCopyDetailPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "plotcopy02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_42",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160"
  },
  [1200] = {
    CompID = GUIDE_COMPONENT_ID.chapterPlot_7,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "chapterPlot07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_78",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "LevelDetailsPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "chapterPlot08"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_78",
          false
        }
      }
    },
    Note = "\233\128\137\230\139\169\229\186\143\231\171\160\231\172\172\229\133\173\229\133\179"
  },
  [1210] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "leveldetails02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_44",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "leveldetails02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_44",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "\229\137\175\230\156\172\231\149\140\233\157\162\229\135\186\229\190\129"
  },
  [1280] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {1, 89}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\232\191\155\229\133\165\230\136\152\230\150\1511\239\188\140\229\137\175\230\156\172\230\151\182\233\151\180\230\154\130\229\129\156"
  },
  [1290] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BATTLE_CAN_COST_TIME,
        false
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    Note = "\232\191\155\229\133\165\230\136\152\230\150\1511\239\188\140\229\137\175\230\156\172\230\151\182\233\151\180\230\154\130\229\129\156"
  },
  [1300] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        140
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {140}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\229\137\167\230\131\133\239\188\140140"
  },
  [1310] = {
    WaitStartPoint = TRIGGER_TYPE.MAINGUN_ENTER_RANGE,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "elizabeth01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_81",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "elizabeth01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_81",
          false
        }
      }
    },
    Note = "QE\231\137\155\233\128\188\232\175\180\230\152\142"
  },
  [1320] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      9
    },
    Note = "\231\187\147\230\157\159\230\136\152\230\150\151"
  },
  [1330] = {
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    Note = "\229\137\167\230\131\133\239\188\140142"
  },
  [1340] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        142
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\137\167\230\131\133\239\188\140142"
  },
  [1350] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {146, 1461}
    },
    Note = "\229\137\167\230\131\133\239\188\140143"
  },
  [1360] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      10
    },
    Note = "\229\137\167\230\131\133\239\188\14011010"
  },
  [1380] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ENTER_NORMAL_BATTLE,
        {1, 11}
      },
      {
        GUIDE_BEHAVIOUR.ClosePagesByLayer
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {1, 109}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\232\191\155\229\133\165\230\136\152\230\150\1511\239\188\140\229\137\175\230\156\172\230\151\182\233\151\180\230\154\130\229\129\156"
  },
  [1390] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetGuideInfluenceData,
        {
          BabelTime.GD.Guide.GuideInfluenceType.AirAttackCanReleaseRange,
          1
        }
      }
    },
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetGuideInfluenceData,
        {
          BabelTime.GD.Guide.GuideInfluenceType.AirAttackCanReleaseRange,
          0
        }
      },
      {
        GUIDE_BEHAVIOUR.BATTLE_CAN_COST_TIME,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search_enemy"
      },
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SwitchKeyboard,
        false
      }
    },
    Note = "\232\191\155\229\133\165\230\136\152\230\150\1511\239\188\140\229\137\175\230\156\172\230\151\182\233\151\180\230\154\130\229\129\156"
  },
  [1400] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        147
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search_enemy"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {147}
    },
    Note = "\229\137\167\230\131\133\239\188\140142"
  },
  [1401] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "click_small_map"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_606",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.click_small_map,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "click_small_map"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_607",
          true
        }
      }
    },
    Note = "\231\130\185\229\135\187\229\176\143\229\156\176\229\155\190"
  },
  [1402] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "enemy03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_607",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SET_PLAYER_SPEED,
        1
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "enemy03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_607",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\231\180\162\230\149\140\230\140\137\233\146\174"
  },
  [1410] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_82",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_82",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\231\130\185\229\135\187\231\180\162\230\149\140\230\140\137\233\146\174"
  },
  [1420] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_83",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.SEARCH_BTN,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search_btn"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_83",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search_enemy"
      }
    },
    Note = "\231\130\185\229\135\187\231\180\162\230\149\140\230\140\137\233\146\174"
  },
  [1430] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search_area"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_84",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.SEARCH_AREA,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search_area"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_84",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\231\180\162\230\149\140\229\140\186\229\159\159"
  },
  [1440] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_85",
          true
        }
      }
    },
    WaitEndPoint = TRIGGER_TYPE.ClickAirSearchOrAttack,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_85",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.AllowMoveInterval,
        6
      }
    },
    Note = "\231\130\185\229\135\187\229\143\145\228\187\164\230\140\137\233\146\174"
  },
  [1450] = {
    WaitStartPoint = {
      TRIGGER_TYPE.CouldRequestSkill,
      SkillType.AirAttack
    },
    Note = "\231\173\137\229\190\133\232\191\155\232\161\140\228\184\139\228\184\128\230\173\165"
  },
  [1460] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search_enemy"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "air_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_86",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.AIR_ATTACK,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "air_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_86",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\231\130\185\229\135\187\231\180\162\230\149\140\230\140\137\233\146\174"
  },
  [1470] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search_air_area"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_87",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "search_enemy"
      }
    },
    CompID = GUIDE_COMPONENT_ID.SEARCH_AREA,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search_air_area"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_87",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_AIRATTACK_TIP,
        true
      }
    },
    Note = "\231\130\185\229\135\187\231\180\162\230\149\140\229\140\186\229\159\159"
  },
  [1480] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "air_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_88",
          true
        }
      }
    },
    WaitEndPoint = TRIGGER_TYPE.ClickAirSearchOrAttack,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "air_ok"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_88",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "search_enemy"
      }
    },
    Note = "\231\130\185\229\135\187\229\143\145\228\187\164\230\140\137\233\146\174"
  },
  [1490] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.FLEET_CAN_MOVE,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SwitchKeyboard,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_AIRATTACK_TIP,
        false
      }
    },
    Note = "\229\137\141\229\142\187\229\135\187\232\180\165\230\149\140\228\186\186\229\144\167"
  },
  [1500] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      11
    },
    Note = "\231\187\147\230\157\159\230\136\152\230\150\151"
  },
  [1510] = {
    Note = "\229\137\167\230\131\133\239\188\140148"
  },
  [30101] = {
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.SetCanPlayLogin,
        false
      }
    },
    Note = "\233\187\145\229\185\149\233\129\174\230\140\161"
  },
  [15201] = {
    WaitStartPoint = TRIGGER_TYPE.ENTER_MAINSTAGE,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.SetCanPlayLogin,
        false
      }
    },
    Note = "\233\187\145\229\185\149\233\129\174\230\140\161"
  },
  [30102] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.PLOT,
        148
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {150}
    },
    Note = "\229\137\167\230\131\133\239\188\140148"
  },
  [1540] = {Note = "\231\169\186"},
  [1550] = {Note = "\231\169\186"},
  [1560] = {Note = "\229\176\190\229\163\1762"},
  [30011] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      }
    },
    Note = "\230\137\147\229\188\128\228\184\187\229\156\186\230\153\175\231\149\140\233\157\162"
  },
  [80001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "start_battle"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        283
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CopyPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "start_battle"
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        283
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129\230\140\137\233\146\174"
  },
  [80002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "start_battle_home"
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        284
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CopyPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "start_battle_home"
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        284
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_55",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129\230\140\137\233\146\174"
  },
  [80003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "copypage_btn_haiyu"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_89",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.copypage_btn_haiyu
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {
        "CopyPage",
        "SeaCopyPage"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HideComponent,
        GUIDE_COMPONENT_ID.copypage_btn_haiyu
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "copypage_btn_haiyu"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_89",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\181\183\229\159\159\230\140\137\233\146\174"
  },
  [1653] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "02_4"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_90",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.copysea_01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "02_4"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_90",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\181\183\229\159\159\231\172\172\228\184\128\229\133\179"
  },
  [80004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "1A_01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_90",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.haiyu1_A,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "1A_01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_90",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\181\183\229\159\1591_A"
  },
  [80005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "1A_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.haiyu1_A2,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "1A_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129"
  },
  [1600] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "btn_close_bu"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_91",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "btn_close_bu"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_91",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.OpenPage,
        "HomePage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "\228\187\142\228\191\161\230\129\175\231\149\140\233\157\162\232\191\148\229\155\158"
  },
  [31011] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "home_build_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_92",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.home_build_btn,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "home_build_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_92",
          false
        }
      }
    },
    Note = "\230\137\147\229\188\128home_build_btn"
  },
  [31012] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetBuildPageTog,
        BuildShipPageId.Equip
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "BuildEquipPage"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_93",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.BuildEquipPage,
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GetRewardsPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "BuildEquipPage"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_93",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "black_bue"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\230\137\147\229\188\128home_build_btn"
  },
  [31013] = {
    WaitStartPoint = {
      TRIGGER_TYPE.OnPageHide,
      "GetRewardsPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "black_bue"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "BuildEquip_ship"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_94",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.BuildEquip_ship,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "BuildEquip_ship"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_94",
          false
        }
      }
    },
    Note = "\230\137\147\229\188\128home_build_btn"
  },
  [32001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "buildShipPage_10_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_95",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SetBuildPageTog,
        BuildShipPageId.NewPlayer
      }
    },
    CompID = GUIDE_COMPONENT_ID.buildShipPage_10_btn,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "buildShipPage_10_btn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_95",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187buildShipPage_btn"
  },
  [32002] = {
    WaitStartPoint = TRIGGER_TYPE.INTO_Tsansuo_MAP,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_96",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "into_tsansuo_map"
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        false
      }
    },
    CompID = GUIDE_COMPONENT_ID.TANSUO_MAP,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "into_tsansuo_map"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_96",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\231\130\185\229\135\187into_tsansuo_map"
  },
  [32003] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "ShowGirlPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SetCanPlayLogin,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\188\128\229\144\175\230\136\152\229\167\172\229\177\149\231\164\186"
  },
  [32004] = {
    WaitStartPoint = TRIGGER_TYPE.BuildTenShipReturn,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SetCanPlayLogin,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_134",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Ship_btn_close"
      }
    },
    CompID = GUIDE_COMPONENT_ID.Ship_btn_close,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Ship_btn_close"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_134",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\231\130\185\229\135\187\232\191\148\229\155\158"
  },
  [1660] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_142",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "ship_head_bu02"
      }
    },
    CompID = GUIDE_COMPONENT_ID.ship_head_bu,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "ship_head_bu02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_142",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\232\191\155\229\133\165\229\177\165\229\142\134"
  },
  [1670] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_135",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "btn_settings"
      }
    },
    CompID = GUIDE_COMPONENT_ID.btn_settings,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "btn_settings"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_135",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\232\191\155\229\133\165\232\174\190\231\189\174"
  },
  [1680] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_136",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "high_definition"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "high_definition"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_136",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "\232\175\180\230\152\142"
  },
  [80006] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        false
      }
    },
    Note = "\229\174\140\230\136\144\229\188\149\229\175\188"
  },
  [2010] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CommonHeroPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "bathroom01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_219",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "bathroom01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_219",
          false
        }
      }
    },
    Note = "\230\181\180\229\174\164\229\175\185\232\175\157 1"
  },
  [2020] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "bathroom02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_220",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_220",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "bathroom02"
      }
    },
    Note = "\230\181\180\229\174\164\229\175\185\232\175\157 2"
  },
  [2030] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "StudyPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "studypage01"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "studypage01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\229\173\166\233\153\162\229\175\185\232\175\157 1"
  },
  [2040] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "WishPage"
    },
    CompID = GUIDE_COMPONENT_ID.wish_tog_btn,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wishpage01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_210",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wishpage01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_210",
          false
        }
      }
    },
    Note = "\232\174\184\230\132\191\229\162\153\229\175\185\232\175\157 1"
  },
  [2050] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wishpage02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_211",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wishpage02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_211",
          false
        }
      }
    },
    Note = "\232\174\184\230\132\191\229\162\153\229\175\185\232\175\157 2"
  },
  [2051] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wishpage03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_212",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wishpage03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_212",
          false
        }
      }
    },
    Note = "\232\174\184\230\132\191\229\162\153\229\175\185\232\175\157 3"
  },
  [2052] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wishpage04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_213",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wishpage04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_213",
          false
        }
      }
    },
    Note = "\232\174\184\230\132\191\229\162\153\229\175\185\232\175\157 4"
  },
  [2053] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wishpage05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_214",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wishpage05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_214",
          false
        }
      }
    },
    Note = "\232\174\184\230\132\191\229\162\153\229\175\185\232\175\157 5"
  },
  [2054] = {
    CompID = GUIDE_COMPONENT_ID.wish_tog_switch,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wishpage06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_215",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wishpage06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_215",
          false
        }
      }
    },
    Note = "\232\174\184\230\132\191\229\162\153\229\175\185\232\175\157 6"
  },
  [2060] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "wishpage07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_216",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "wishpage07"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_216",
          false
        }
      }
    },
    Note = "\232\174\184\230\132\191\229\162\153\229\175\185\232\175\157 7"
  },
  [2070] = {
    CompID = GUIDE_COMPONENT_ID.im_kuang,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "assist01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_205",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "assist01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_205",
          false
        }
      }
    },
    Note = "\230\148\175\230\143\180\232\136\176\233\152\159 1"
  },
  [2071] = {
    CompID = GUIDE_COMPONENT_ID.btn_use,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "assist02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_206",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "assist02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_206",
          false
        }
      }
    },
    Note = "\230\148\175\230\143\180\232\136\176\233\152\159 2"
  },
  [2072] = {
    CompID = GUIDE_COMPONENT_ID.btn_commend,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "assist03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_207",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "assist03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_207",
          false
        }
      }
    },
    Note = "\230\148\175\230\143\180\232\136\176\233\152\159 3"
  },
  [2073] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "assist04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_208",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "assist04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_208",
          false
        }
      }
    },
    Note = "\230\148\175\230\143\180\232\136\176\233\152\159 4"
  },
  [2080] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "assist02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_206",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "assist02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_206",
          false
        }
      }
    },
    Note = "\230\148\175\230\143\180\232\136\176\233\152\159 2"
  },
  [2090] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "assist03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_207",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "assist03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_207",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\230\148\175\230\143\180\232\136\176\233\152\159 3"
  },
  [2100] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy01"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy01"
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17201"
  },
  [2110] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy02"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy02"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17202"
  },
  [2111] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_FIGHT,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy03"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy03"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17203"
  },
  [2120] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy04"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy04"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17204"
  },
  [2130] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy04_1"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy04_1"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17205"
  },
  [2140] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy05"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy05"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17206"
  },
  [2150] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy06_1"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy06_1"
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17207"
  },
  [2160] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy06_2"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy06_2"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17208"
  },
  [2170] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy06_3"
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy06_3"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\230\175\143\230\151\165\229\137\175\230\156\17208"
  },
  [2180] = {
    CompID = GUIDE_COMPONENT_ID.SuperStrategyPage_btn,
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "SuperStrategyPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "SuperStrategy01"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "SuperStrategy01"
      }
    },
    Note = "\230\136\152\230\156\175 1"
  },
  [2190] = {
    CompID = GUIDE_COMPONENT_ID.SuperStrategyPage_ok,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "SuperStrategy02"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "SuperStrategy02"
      }
    },
    Note = "\230\136\152\230\156\175 2"
  },
  [2200] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "SuperStrategy03"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "SuperStrategy03"
      }
    },
    Note = "\230\136\152\230\156\175 3"
  },
  [2210] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "SuperStrategy04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_120",
          true
        }
      }
    },
    WaitEndPoint = TRIGGER_TYPE.StrategyEndDrag,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "SuperStrategy04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_120",
          false
        }
      }
    },
    Note = "\230\136\152\230\156\175 3"
  },
  [4000] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {1, 50}
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      }
    },
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    CompID = GUIDE_COMPONENT_ID.auto_on,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "autoBtnTrick_root",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "auto"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_121",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "autoBtnTrick_root",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "auto"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_121",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {2, 300}
      }
    },
    Note = "\232\135\170\229\190\139\229\188\149\229\175\188"
  },
  [4001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {1, 50}
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      }
    },
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "autoBtnTrick_root",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "auto"
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "autoBtnTrick_root",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "auto"
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {2, 300}
      }
    },
    Note = "\229\143\150\230\182\136\232\135\170\229\190\139"
  },
  [6000] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {1, 50}
      }
    },
    WaitStartPoint = TRIGGER_TYPE.BATTLE_FIGHT,
    CompID = GUIDE_COMPONENT_ID.n_speed,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "n_speed"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_125",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "n_speed"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_125",
          false
        }
      }
    },
    Note = "\229\128\141\233\128\159\229\188\149\229\175\188"
  },
  [6001] = {
    CompID = GUIDE_COMPONENT_ID.ExitBtn,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "ExitBtn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_126",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "ExitBtn"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_126",
          true
        }
      }
    },
    Note = "\229\128\141\233\128\159\229\188\149\229\175\188"
  },
  [6002] = {
    CompID = GUIDE_COMPONENT_ID.BtnSetting,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {2, 300}
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "BtnSetting"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_127",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "BtnSetting"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_127",
          false
        }
      }
    },
    Note = "\229\128\141\233\128\159\229\188\149\229\175\188"
  },
  [6003] = {
    CompID = GUIDE_COMPONENT_ID.tog_others,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "tog_others"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_128",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "tog_others"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_128",
          false
        }
      }
    },
    Note = "\229\128\141\233\128\159\229\188\149\229\175\188"
  },
  [6004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "jump_anim"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "jump_anim"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "\232\183\179\232\191\135\229\138\168\231\148\187\229\188\149\229\175\188"
  },
  [6500] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ChatPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "cartoon"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "cartoon01"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "cartoon01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "cartoon01"
  },
  [6501] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "cartoon02"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "cartoon02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "cartoon02"
  },
  [6502] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "cartoon03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "cartoon03"
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "cartoon"
      }
    },
    Note = "cartoon03"
  },
  [7000] = {
    CompID = GUIDE_COMPONENT_ID.fail_open,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "fail_open"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_122",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "fail_open"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_122",
          false
        }
      }
    },
    Note = "\228\189\156\230\136\152\229\164\177\232\180\165 \231\130\185\229\135\187\232\136\176\229\168\152\231\170\129\231\160\180"
  },
  [7001] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {"GirlInfo", "Break_Page"}
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Break_teaching_01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_123",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Break_teaching_01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_123",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "\228\189\156\230\136\152\229\164\177\232\180\165 \231\130\185\229\135\187\232\136\176\229\168\152\231\170\129\231\160\1802"
  },
  [7002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Break_teaching_02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_124",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Break_teaching_02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_124",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "\228\189\156\230\136\152\229\164\177\232\180\165 \231\130\185\229\135\187\232\136\176\229\168\152\231\170\129\231\160\1803"
  },
  [8000] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "love01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_221",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "love01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_221",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "love01"
  },
  [8001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "love02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_222",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "love02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_222",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "love02"
  },
  [1654] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "SafeSlider01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_202",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.SafeSlider,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "SafeSlider01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_202",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "SafeSlider01"
  },
  [1655] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "SafeInfoPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "SafeSlider02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_203",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "SafeSlider02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_203",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "SafeSlider02"
  },
  [10000] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "jineng01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_223",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.jineng,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "jineng01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_223",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "jineng01"
  },
  [10001] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "SkillLevelupPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "jineng02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_224",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.5
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "jineng02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_224",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "jineng02"
  },
  [11000] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Challenge01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_225",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.btn_battle,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Challenge01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_225",
          false
        }
      }
    },
    Note = "Challenge01"
  },
  [11001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Challenge02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_226",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.Btn_zhiyuan,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Challenge02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_226",
          false
        }
      }
    },
    Note = "Challenge02"
  },
  [11021] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Challenge02_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_227",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    CompID = GUIDE_COMPONENT_ID.Challenge02_2,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Challenge02_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_227",
          false
        }
      }
    },
    Note = "Challenge02_2"
  },
  [11002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Challenge03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_228",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Challenge03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_228",
          false
        }
      }
    },
    Note = "Challenge03"
  },
  [11003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Challenge04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_229",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Challenge04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_229",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "Challenge04"
  },
  [11004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Challenge05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_230",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Challenge05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_230",
          false
        }
      }
    },
    Note = "Challenge05"
  },
  [11005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Challenge06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_231",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.BtnChallenge,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Challenge06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_231",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "Challenge06"
  },
  [12001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "GetintoVow"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_209",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.GetintoVow,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "GetintoVow"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_209",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "GetintoVow"
  },
  [12002] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "GetintoSupport"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_204",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.GetintoSupport,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "GetintoSupport"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_204",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "GetintoSupport"
  },
  [12003] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "GetintoShower"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_232",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.GetintoShower,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "GetintoShower"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_232",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "GetintoShower"
  },
  [12004] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TacticalOpen01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_233",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.LEFT_FLEET_BTN,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TacticalOpen01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_233",
          false
        }
      }
    },
    Note = "TacticalOpen01"
  },
  [12005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TacticalOpen02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_234",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.bu_tactic,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TacticalOpen02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_234",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "TacticalOpen02"
  },
  [14000] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_235",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.btn_battle,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_235",
          false
        }
      }
    },
    Note = "daily01"
  },
  [14001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_236",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.Btn_meiri,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_236",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "daily02"
  },
  [14002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_237",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_237",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "daily03"
  },
  [14003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_238",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_238",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "daily04"
  },
  [14004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_239",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_239",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "daily05"
  },
  [14005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_240",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily06"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_240",
          false
        }
      }
    },
    Note = "daily06"
  },
  [14006] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_241",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_241",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "daily07"
  },
  [14007] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily08"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_242",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.bu_copy4,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily08"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_242",
          false
        }
      }
    },
    Note = "daily06"
  },
  [14008] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily09"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_243",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily09"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_243",
          false
        }
      }
    },
    Note = "daily09"
  },
  [14009] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily10"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_244",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily10"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_244",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "daily10"
  },
  [14010] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily11"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_245",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.ShopButtonList,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily11"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_245",
          false
        }
      }
    },
    Note = "daily11"
  },
  [14011] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily12"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_246",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily12"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_246",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "daily12"
  },
  [14012] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily13"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_247",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.btn_close,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily13"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_247",
          false
        }
      }
    },
    Note = "daily13"
  },
  [14013] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "daily14"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_248",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.DailyCopyDetailPage,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "daily14"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_248",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "daily14"
  },
  [15001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "sea_treasure_chest01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_217",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.sea_treasure_chest01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "sea_treasure_chest01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_217",
          false
        }
      }
    },
    Note = "sea_treasure_chest01"
  },
  [15002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "sea_treasure_chest02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_218",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.sea_treasure_chest02,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "sea_treasure_chest02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_218",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "sea_treasure_chest02"
  },
  [17001] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_250",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.TowerRoad01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_250",
          false
        }
      }
    },
    Note = "TowerRoad01"
  },
  [17002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_251",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.TowerRoad02,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_251",
          false
        }
      }
    },
    Note = "TowerRoad02"
  },
  [17003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_252",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.TowerRoad03,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_252",
          false
        }
      }
    },
    Note = "TowerRoad03"
  },
  [17004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_253",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_253",
          false
        }
      }
    },
    Note = "TowerRoad04"
  },
  [17005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_254",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_254",
          false
        }
      }
    },
    Note = "TowerRoad05"
  },
  [17006] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad06"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_255",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad06"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_255",
          false
        }
      }
    },
    Note = "TowerRoad06"
  },
  [17106] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad06_2"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_303",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad06_2"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_303",
          false
        }
      }
    },
    Note = "TowerRoad06_2"
  },
  [17007] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad07"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_256",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad07"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_256",
          false
        }
      }
    },
    Note = "TowerRoad07"
  },
  [17008] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad08"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_257",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad08"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_257",
          false
        }
      }
    },
    Note = "TowerRoad08"
  },
  [17009] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad09"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_258",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.TowerRoad08,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad09"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_258",
          false
        }
      }
    },
    Note = "TowerRoad09"
  },
  [17010] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad10"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_259",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.TowerRoad09,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad10"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_259",
          false
        }
      }
    },
    Note = "TowerRoad10"
  },
  [17011] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad11"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_260",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad11"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_260",
          false
        }
      }
    },
    Note = "TowerRoad11"
  },
  [17012] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad12"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_261",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad12"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_261",
          false
        }
      }
    },
    Note = "TowerRoad12"
  },
  [1701211] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad_add01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_310",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        true
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.TowerGirlInBattle,
      1
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad_add01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_310",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    Note = "TowerRoad_add01"
  },
  [1701212] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad_add02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_311",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.TowerRoad_add02,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad_add02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_311",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "TowerRoad_add02"
  },
  [1701213] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad_add03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_312",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "NoticePage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad_add03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_312",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    Note = "TowerRoad_add03"
  },
  [1711214] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "NoticePage01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    CompID = GUIDE_COMPONENT_ID.NoticePage01,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "NoticePage01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        false
      }
    },
    Note = "NoticePage01"
  },
  [1701214] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad_add04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_313",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    CompID = GUIDE_COMPONENT_ID.TowerRoad_add04,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad_add04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_313",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        false
      }
    },
    Note = "TowerRoad_add04"
  },
  [17013] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad13"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_262",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad13"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_262",
          false
        }
      }
    },
    Note = "TowerRoad13"
  },
  [17014] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "TowerRoad14"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_263",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TowerRoad14"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_263",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.DONT_CLICK,
        false
      }
    },
    Note = "TowerRoad14"
  },
  [18001] = {
    CompID = GUIDE_COMPONENT_ID.building01,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "ModuleOpenPage"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_264",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_264",
          false
        }
      }
    },
    Note = "building01"
  },
  [18002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToLeft
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_265",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_265",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "2_building02"
  },
  [18003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "2_building03"
  },
  [18004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "2_building04"
  },
  [18005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "2_building05"
  },
  [18006] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building06"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building06"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "2_building06"
  },
  [18007] = {
    CompID = GUIDE_COMPONENT_ID.building07,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToLeft
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_270",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_270",
          false
        }
      }
    },
    Note = "3_building07"
  },
  [18008] = {
    CompID = GUIDE_COMPONENT_ID.building08,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building08"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_271",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building08"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_271",
          false
        }
      }
    },
    Note = "3_building08"
  },
  [18082] = {
    CompID = GUIDE_COMPONENT_ID.building08_2,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building08_2"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building08_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_271",
          false
        }
      }
    },
    Note = "3_building08_2"
  },
  [180821] = {
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\173\152\229\130\1683_building08_2"
  },
  [18009] = {
    WaitStartPoint = {
      TRIGGER_TYPE.OnPageHide,
      "BuildingOpenPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building09"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_272",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building09"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_272",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "3_building09"
  },
  [18010] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building10"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_273",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building10"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_273",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "3_building10"
  },
  [18011] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building11"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_274",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building11"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_274",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "3_building11"
  },
  [18012] = {
    CompID = GUIDE_COMPONENT_ID.building12,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToLeft
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building12"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_275",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building12"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_275",
          false
        }
      }
    },
    Note = "4_building12"
  },
  [18013] = {
    CompID = GUIDE_COMPONENT_ID.building13,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building13"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_276",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building13"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_276",
          false
        }
      }
    },
    Note = "4_building13"
  },
  [18132] = {
    CompID = GUIDE_COMPONENT_ID.building13_2,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building13_2"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building13_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_276",
          false
        }
      }
    },
    Note = "4_building13_2"
  },
  [181321] = {
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\173\152\229\130\1684_building08_2"
  },
  [18014] = {
    WaitStartPoint = {
      TRIGGER_TYPE.OnPageHide,
      "BuildingOpenPage"
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building14"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_277",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building14"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_277",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "4_building14"
  },
  [18015] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building15"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_278",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building15"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_278",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "4_building15"
  },
  [18016] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building16"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_279",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building16"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_279",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "4_building16"
  },
  [18017] = {
    CompID = GUIDE_COMPONENT_ID.building17,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToLeft
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building17"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_280",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building17"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_280",
          false
        }
      }
    },
    Note = "5_building17"
  },
  [18018] = {
    CompID = GUIDE_COMPONENT_ID.building18,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building18"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_281",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building18"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_281",
          false
        }
      }
    },
    Note = "5_building18"
  },
  [18182] = {
    CompID = GUIDE_COMPONENT_ID.building18_2,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building18_2"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building18_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_281",
          false
        }
      }
    },
    Note = "5_building18_2"
  },
  [181821] = {
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\173\152\229\130\1684_building08_2"
  },
  [18019] = {
    WaitStartPoint = {
      TRIGGER_TYPE.OnPageHide,
      "BuildingOpenPage"
    },
    Note = "5_building19"
  },
  [18020] = {
    CompID = GUIDE_COMPONENT_ID.building20,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToLeft
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building20"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_283",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building20"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_283",
          false
        }
      }
    },
    Note = "6_building20"
  },
  [18020111] = {
    CompID = GUIDE_COMPONENT_ID.building_details,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_details"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_details"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          false
        }
      }
    },
    Note = "9_building_office01 building_details"
  },
  [18021] = {
    CompID = GUIDE_COMPONENT_ID.building21,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building21"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_284",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building21"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_284",
          false
        }
      }
    },
    Note = "6_building21"
  },
  [18022] = {
    CompID = GUIDE_COMPONENT_ID.building22,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building22"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_285",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building22"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_285",
          false
        }
      }
    },
    Note = "6_building22"
  },
  [18023] = {
    CompID = GUIDE_COMPONENT_ID.building23,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building23"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_286",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building23"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_286",
          false
        }
      }
    },
    Note = "6_building23"
  },
  [18024] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building24"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_287",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building24"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_287",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "6_building24"
  },
  [18025] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building25"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building25"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "6_building25"
  },
  [18252] = {
    CompID = GUIDE_COMPONENT_ID.building25_2,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building25_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_134",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building25_2"
      }
    },
    Note = "6_building25_2"
  },
  [182521] = {
    CompID = GUIDE_COMPONENT_ID.building_office06,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_office06"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_office06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_134",
          false
        }
      }
    },
    Note = "9_building_office06"
  },
  [18026] = {
    CompID = GUIDE_COMPONENT_ID.building26,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToLeft
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building26"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_289",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building26"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_289",
          false
        }
      }
    },
    Note = "7_building26"
  },
  [18027] = {
    CompID = GUIDE_COMPONENT_ID.building27,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building27"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_290",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building27"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_290",
          false
        }
      }
    },
    Note = "7_building27"
  },
  [18272] = {
    CompID = GUIDE_COMPONENT_ID.building27_2,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building27_2"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building27_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_290",
          false
        }
      }
    },
    Note = "7_building27_2"
  },
  [182721] = {
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "\229\173\152\229\130\1684_building08_2"
  },
  [18028] = {
    WaitStartPoint = {
      TRIGGER_TYPE.OnPageHide,
      "BuildingOpenPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    Note = "7_building28"
  },
  [18029] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToLeft
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_GetintoShower"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_232",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.building_GetintoShower,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_GetintoShower"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_232",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "7_building_GetintoShower"
  },
  [18030] = {
    WaitStartPoint = {
      TRIGGER_TYPE.IsPageOpen,
      {
        "BathRoomPage",
        "CommonHeroPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "bathroom01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_219",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "bathroom01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_219",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "7_\230\181\180\229\174\164\229\175\185\232\175\157 1"
  },
  [180291] = {
    CompID = GUIDE_COMPONENT_ID.DormRoomPath,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToRight
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building29"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_292",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building29"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_292",
          false
        }
      }
    },
    Note = "8_building29"
  },
  [180301] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building30"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_293",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building30"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_293",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "8_building30"
  },
  [18031] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building31"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_294",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building31"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_294",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "8_building31"
  },
  [18032] = {
    CompID = GUIDE_COMPONENT_ID.ItemFactoryPath,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.BuildingMainToRight
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building32"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_295",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building32"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_295",
          false
        }
      }
    },
    Note = "8_building32"
  },
  [18032111] = {
    CompID = GUIDE_COMPONENT_ID.production_info,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "production_info"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "production_info"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          false
        }
      }
    },
    Note = "9_building_office01 production_info"
  },
  [18322] = {
    CompID = GUIDE_COMPONENT_ID.building32_2,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building32_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_304",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building32_2"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_304",
          false
        }
      }
    },
    Note = "8_building32_2"
  },
  [18033] = {
    CompID = GUIDE_COMPONENT_ID.building33,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building33"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_296",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building33"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_296",
          false
        }
      }
    },
    Note = "8_building33"
  },
  [18034] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building34"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_297",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building34"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_297",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "8_building34"
  },
  [18035] = {
    CompID = GUIDE_COMPONENT_ID.building35,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building35"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_298",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building35"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_298",
          false
        }
      }
    },
    Note = "8_building35"
  },
  [18036] = {
    CompID = GUIDE_COMPONENT_ID.building36,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building36"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_299",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building36"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_299",
          false
        }
      }
    },
    Note = "8_building36"
  },
  [18037] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building37"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_300",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building37"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_300",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "BuildingOpenPage"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "8_building37"
  },
  [18038] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "BuildingOpenPage"
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building38"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_301",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building38"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_301",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "8_building38"
  },
  [18039] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building39"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_302",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building39"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_302",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "8_building38"
  },
  [19001] = {
    CompID = GUIDE_COMPONENT_ID.building_office01,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_office01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_305",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_office01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_305",
          false
        }
      }
    },
    Note = "9_building_office01"
  },
  [1900111] = {
    CompID = GUIDE_COMPONENT_ID.building_details,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_details"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          true
        }
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_details"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_130",
          false
        }
      }
    },
    Note = "9_building_office01 building_details"
  },
  [19002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_office02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_office02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "9_building_office02"
  },
  [19003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_office03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_office03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "9_building_office03"
  },
  [19004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_office04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_office04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "9_building_office04"
  },
  [19005] = {
    CompID = GUIDE_COMPONENT_ID.building_office05,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_office05"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_office05"
      }
    },
    Note = "9_building_office05"
  },
  [19006] = {
    CompID = GUIDE_COMPONENT_ID.building_office06,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "building_office06"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "building_office06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_309",
          false
        }
      }
    },
    Note = "9_building_office06"
  },
  [20000] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_SEARCH,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    Note = "\232\191\155\229\133\165\229\137\175\230\156\172 204050 "
  },
  [20001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "air_dayly_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "air_dayly_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "air_dayly_01"
  },
  [20002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "air_dayly_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "air_dayly_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "air_dayly_02"
  },
  [191051] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "1_5_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "1_5_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "1_5_01"
  },
  [191052] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "1_5_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "1_5_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "1_5_02"
  },
  [191053] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "1_5_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "1_5_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "1_5_03"
  },
  [191054] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "1_5_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "1_5_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "1_5_04"
  },
  [191055] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "1_5_05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.changeEnemyFleet,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "1_5_05"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "1_5_05"
  },
  [191081] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "enemy07"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "enemy07"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "enemy05"
  },
  [191082] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "enemy06"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "enemy06"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      }
    },
    Note = "enemy06"
  },
  [191091] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "02_1"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "02_1"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "02_1"
  },
  [191092] = {
    CompID = GUIDE_COMPONENT_ID.b02,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "02_2"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "02_2"
      }
    },
    Note = "02_2"
  },
  [191093] = {
    CompID = GUIDE_COMPONENT_ID.b03,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "02_3"
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "02_3"
      }
    },
    Note = "02_3"
  },
  [191094] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "02_4"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "02_4"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "02_4"
  },
  [20003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "air_dayly_03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_403",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "air_dayly_03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideJP_402",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "air_dayly_03"
  },
  [21001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Preset_fleet01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "Preset_fleet01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "Preset_fleet01"
  },
  [30001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "quit_battle_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {1, 50}
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "quit_battle_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "quit_battle_01"
  },
  [30002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "quit_battle_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "quit_battle_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "quit_battle_02"
  },
  [30003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "quit_battle_03"
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.ExitBtn,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "quit_battle_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "quit_battle_03"
  },
  [30004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "quit_battle_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SetGuidePageSort,
        {2, 300}
      }
    },
    CompID = GUIDE_COMPONENT_ID.quit_battle_3,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "quit_battle_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "quit_battle_04"
  },
  [31001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "attack_num_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RefreshFleetItem
      }
    },
    CompID = GUIDE_COMPONENT_ID.attack_num_cancel,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "attack_num_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "attack_num_01"
  },
  [31002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "attack_num_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "LevelFleetItemTrick",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ClickLevelFleetItemTrick
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.attack_num_firstgirl
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "FleetPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "attack_num_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "LevelFleetItemTrick",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        GUIDE_COMPONENT_ID.attack_num_firstgirl
      }
    },
    Note = "attack_num_02"
  },
  [31003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "attack_num_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "ClickFleetFirstGirlTrick",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.ClickFleetFirstGirlTrick
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.attack_num_fleetfirstgirl
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "GirlInfo"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "attack_num_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.ShowSpecial,
        {
          "ClickFleetFirstGirlTrick",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HideComponent,
        GUIDE_COMPONENT_ID.attack_num_fleetfirstgirl
      }
    },
    Note = "attack_num_03"
  },
  [31004] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SwitchGirlinfoTag
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "attack_num_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    CompID = GUIDE_COMPONENT_ID.attack_num,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "attack_num_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "attack_num_04"
  },
  [31005] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "attack_num_05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    CompID = GUIDE_COMPONENT_ID.attack_num_firepower,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "attack_num_05"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "attack_num_05"
  },
  [40000] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.WaitTime,
        0.3
      }
    },
    Note = "change_formation_0"
  },
  [40001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "3_G_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.PAUSE_BATTLE,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "3_G_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      }
    },
    Note = "change_formation_1"
  },
  [40002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "3_G_02"
      }
    },
    CompID = GUIDE_COMPONENT_ID.change_formation_1,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "3_G_02"
      }
    },
    Note = "change_formation_2"
  },
  [40003] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "3_G_03"
      }
    },
    CompID = GUIDE_COMPONENT_ID.change_formation_2,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "3_G_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.RESUME_BATTLE,
        true
      }
    },
    Note = "change_formation_3"
  },
  [50001] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy_ex_1"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.dailycopy_ex_1,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy_ex_1"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "daily ex 1"
  },
  [50002] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "dailycopy_ex_2"
      }
    },
    CompID = GUIDE_COMPONENT_ID.dailycopy_ex_2,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "dailycopy_ex_2"
      },
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      }
    },
    Note = "daily ex 2"
  },
  [150000101] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "nvn_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "nvn_01"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "nvn \230\173\165\233\170\1641"
  },
  [150000102] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "nvn_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "nvn_02"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "nvn \230\173\165\233\170\1642"
  },
  [150000103] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "nvn_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        true
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "nvn_03"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "nvn \230\173\165\233\170\1643"
  },
  [160000101] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "nvn_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
      }
    },
    CompID = GUIDE_COMPONENT_ID.nvn_random_factor,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "nvn_04"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "nvn \230\137\147\229\188\128\231\170\129\229\143\152\229\155\160\229\173\144\231\149\140\233\157\162"
  }
}
return GuideStepConfig
