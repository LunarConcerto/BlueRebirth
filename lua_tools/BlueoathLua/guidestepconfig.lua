local GuideStepConfig = {}
require("game.Guide.Guidedefine")
GuideStepConfig.GuideItemList = {
  [10] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.PLOT,
        100
      },
      {
        GUIDE_BEHAVIOUR.ClosePage,
        "LoginPage"
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotEnd,
      {101}
    },
    Note = "\229\186\143\231\171\160\239\188\140\231\172\172\228\184\128\232\138\130\229\137\167\230\131\133"
  },
  [20] = {
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
  [50] = {
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
  [60] = {
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
      {124}
    },
    Note = "\229\186\143\231\171\160, \232\161\165\228\184\128\228\184\170\230\153\166\230\156\14890\229\137\141"
  },
  [70] = {Note = "\231\169\186"},
  [80] = {
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
      3
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
      },
      {
        GUIDE_BEHAVIOUR.SetFlagShip,
        1021051
      }
    },
    Note = "\229\186\143\231\171\160,\231\172\172\229\155\155\232\138\130 \230\136\152\230\150\151\229\137\141 120~124\230\174\181"
  },
  [100] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.ENTER_NORMAL_BATTLE,
        {1, 4}
      },
      {
        GUIDE_BEHAVIOUR.ClosePagesByLayer
      },
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.PlotTrigger,
      {1, 39}
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
  [110] = {
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
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "enemy01"
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tenemy01"
  },
  [120] = {
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
          "cv_guideCN_601",
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
          "cv_guideCN_601",
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
          "cv_guideCN_602",
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
          "cv_guideCN_602",
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
          "cv_guideCN_603",
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
          "cv_guideCN_603",
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
          "cv_guideCN_604",
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
          "cv_guideCN_604",
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
  [130] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "turn01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_03",
          true
        }
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_03",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "turn01"
      },
      {
        GUIDE_BEHAVIOUR.ReopenBattleSubUI,
        "MainRoot/BattlePage/OperationGroup"
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tturn01"
  },
  [140] = {
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_04",
          true
        }
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_04",
          false
        }
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
  [141] = {
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_05",
          true
        }
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_05",
          false
        }
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
  [142] = {
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_06",
          true
        }
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
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TurnBtnTrick"
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_06",
          false
        }
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
  [143] = {
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_07",
          true
        }
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
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "TurnBtnTrick"
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_07",
          false
        }
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
  [150] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
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
          "cv_guideCN_08",
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
          "cv_guideCN_08",
          false
        }
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\tshift_gears01"
  },
  [170] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "shift_gears02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_09",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.CHANGE_SPEED,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "shift_gears02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_09",
          false
        }
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
  [171] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.CAN_NOT_OPERATE
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "shift_gears03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_10",
          true
        }
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_10",
          false
        }
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
  [180] = {
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
          "cv_guideCN_11",
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
          "cv_guideCN_11",
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
  [200] = {
    WaitEndPoint = TRIGGER_TYPE.EnterFightInstantly,
    EndBehaviour = {
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
  [210] = {
    WaitStartPoint = TRIGGER_TYPE.BATTLE_FIGHT,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "distance01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_12",
          true
        }
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
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_12",
          false
        }
      }
    },
    Note = "\230\136\152\229\156\186\229\156\136\232\175\180\230\152\142\tdistance01"
  },
  [220] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "distance02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_13",
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
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_13",
          false
        }
      }
    },
    Note = "\230\136\152\229\156\186\229\156\136\232\175\180\230\152\142\tdistance02"
  },
  [230] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "distance03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_14",
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
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_14",
          false
        }
      }
    },
    Note = "\230\136\152\229\156\186\229\156\136\232\175\180\230\152\142\tdistance03"
  },
  [240] = {
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
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_501",
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
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "aim01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_501",
          false
        }
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
  [250] = {
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_16",
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
        GUIDE_BEHAVIOUR.SHOW_OPTIONAL_BTN,
        false
      },
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "aim02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_16",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "main_gun_hit"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_17",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      }
    },
    Note = "\228\184\187\231\130\174\231\158\132\229\135\134\229\156\136\232\175\180\230\152\142\taim02"
  },
  [260] = {
    BeginBehaviour = {
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
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_17",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [270] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.DISABLE_SKILL,
        1
      },
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
        1
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_18",
          true
        }
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.CouldRequestSkill,
      SkillType.MainGun
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "hurt01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_18",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [272] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "hurt02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_19",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        1
      }
    },
    WaitStartPoint = {
      TRIGGER_TYPE.AttackAnimBegin,
      {
        skillType = SkillAnimType.MainGun,
        isSelf = 1
      }
    },
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "hurt02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_19",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\228\184\187\231\130\174\229\176\132\229\135\187"
  },
  [280] = {
    WaitStartPoint = {
      TRIGGER_TYPE.PassCopyTrigger,
      4
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
          "cv_guideCN_20",
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
          "cv_guideCN_20",
          false
        }
      }
    },
    Note = "equip_re01"
  },
  [310] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re02"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_21",
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
          "cv_guideCN_21",
          false
        }
      }
    },
    Note = "equip_re02"
  },
  [311] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_48",
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
          "cv_guideCN_48",
          false
        }
      }
    },
    Note = "equip_re03"
  },
  [312] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_22",
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
          "cv_guideCN_22",
          false
        }
      }
    },
    Note = "equip_re04"
  },
  [313] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_24",
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
          "cv_guideCN_24",
          false
        }
      }
    },
    Note = "equip_re05"
  },
  [314] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_25",
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
          "cv_guideCN_25",
          false
        }
      }
    },
    Note = "equip_re06"
  },
  [315] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_re07"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_26",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.equip_re07
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.OnPageHide,
      "EquipChangePage"
    },
    EndBehaviour = {
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
          "cv_guideCN_26",
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
          "cv_guideCN_27",
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
          "cv_guideCN_27",
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
          "cv_guideCN_28",
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
          "cv_guideCN_28",
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
  [319] = {
    CompID = GUIDE_COMPONENT_ID.enterplot_beginning,
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "enterplot"
      }
    },
    WaitEndPoint = {
      TRIGGER_TYPE.IsPageOpen,
      "CopyPage"
    },
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "enterplot"
      }
    },
    Note = "\232\191\155\229\133\165\229\167\139\229\138\168\231\175\135\229\137\167\230\131\133\231\171\160\232\138\130 enterplot"
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
          "cv_guideCN_29",
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
          "cv_guideCN_29",
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
          "cv_guideCN_30",
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
          "cv_guideCN_30",
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
          "cv_guideCN_31",
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
          "cv_guideCN_31",
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
  [301] = {
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
          "cv_guideCN_33",
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
          "cv_guideCN_33",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\232\136\176\233\152\159\tformation"
  },
  [302] = {
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
          "cv_guideCN_34",
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
          "cv_guideCN_34",
          false
        }
      }
    },
    Note = "\230\139\150\230\139\189\228\184\138\233\152\181\tlisted"
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
          "cv_guideCN_35",
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
          "cv_guideCN_35",
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
          "cv_guideCN_36",
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
          "cv_guideCN_36",
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
          "cv_guideCN_37",
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
          "cv_guideCN_37",
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
          "cv_guideCN_38",
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
          "cv_guideCN_38",
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
          "cv_guideCN_39",
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
          "cv_guideCN_39",
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
          "cv_guideCN_40",
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
          "cv_guideCN_40",
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
          "cv_guideCN_41",
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
          "cv_guideCN_41",
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
          "cv_guideCN_42",
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
          "cv_guideCN_42",
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
          "cv_guideCN_43",
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
          "cv_guideCN_43",
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
          "cv_guideCN_44",
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
          "cv_guideCN_44",
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
          "cv_guideCN_46",
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
          "cv_guideCN_46",
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
          "cv_guideCN_47",
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
          "cv_guideCN_47",
          false
        }
      }
    },
    Note = "equip_Str02"
  },
  [370] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str03"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_48",
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
          "cv_guideCN_48",
          false
        }
      }
    },
    Note = "equip_Str03"
  },
  [380] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str04"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_49",
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
          "cv_guideCN_49",
          false
        }
      }
    },
    Note = "equip_Str04"
  },
  [390] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str05"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_50",
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
          "cv_guideCN_50",
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
          "cv_guideCN_52",
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
          "cv_guideCN_52",
          false
        }
      }
    },
    Note = "equip_Str05_1"
  },
  [400] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str06"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_201",
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
          "cv_guideCN_201",
          false
        }
      }
    },
    Note = "equip_Str06"
  },
  [410] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "equip_Str09_1"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_54",
          true
        }
      }
    },
    CompID = GUIDE_COMPONENT_ID.equip_Str09_1,
    EndBehaviour = {
      {
        GUIDE_BEHAVIOUR.HIDE_SIMPLE_TIP,
        "equip_Str09_1"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
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
          "cv_guideCN_54",
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
          "cv_guideCN_55",
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
          "cv_guideCN_55",
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
          "cv_guideCN_56",
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
          "cv_guideCN_56",
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
          "cv_guideCN_57",
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
          "cv_guideCN_57",
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
          "cv_guideCN_58",
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
          "cv_guideCN_58",
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
          "cv_guideCN_60",
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
          "cv_guideCN_61",
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
          "cv_guideCN_61",
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
          "cv_guideCN_61",
          false
        }
      }
    },
    Note = "\230\150\176\230\137\139\230\149\153\231\168\139\230\136\152\230\150\1511\ttorpedo"
  },
  [950] = {
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
  [970] = {
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
  [980] = {
    BeginBehaviour = {
      {
        GUIDE_BEHAVIOUR.WaitTime,
        1
      },
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_65",
          true
        }
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
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_65",
          false
        }
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
      },
      {
        GUIDE_BEHAVIOUR.CANCEL_DISABLE_SKILL,
        3
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
          "cv_guideCN_66",
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
          "cv_guideCN_66",
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
          "cv_guideCN_67",
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
          "cv_guideCN_67",
          false
        }
      }
    },
    Note = "dockpage_ship"
  },
  [1041] = {
    OperateBehaviour = {
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "GirlShowPage"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_141",
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
          "cv_guideCN_141",
          false
        }
      }
    },
    Note = "equip_\230\138\128\232\131\189\228\185\16601"
  },
  [1042] = {
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
          "cv_guideCN_132",
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
          "cv_guideCN_132",
          false
        }
      }
    },
    Note = "equip_\230\138\128\232\131\189\228\185\16602"
  },
  [1043] = {
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
        "btn_levelup01"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_133",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.ShowComponent,
        GUIDE_COMPONENT_ID.btn_levelup01
      }
    },
    WaitEndPoint = {
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
          "cv_guideCN_133",
          false
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        false
      }
    },
    Note = "equip_\230\138\128\232\131\189\228\185\16603"
  },
  [1044] = {
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
          "cv_guideCN_68",
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
          "cv_guideCN_68",
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
          "cv_guideCN_69",
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
          "cv_guideCN_69",
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
          "cv_guideCN_73",
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
          "cv_guideCN_73",
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
          "cv_guideCN_74",
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
          "cv_guideCN_74",
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
  [1140] = {
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
          "cv_guideCN_75",
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
          "cv_guideCN_75",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\231\170\129\231\160\180\230\140\137\233\146\174"
  },
  [1150] = {
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
          "cv_guideCN_76",
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
          "cv_guideCN_76",
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
  [1160] = {
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
  [1170] = {
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
          "cv_guideCN_77",
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
          "cv_guideCN_55",
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
          "cv_guideCN_55",
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
          "cv_guideCN_42",
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
          "cv_guideCN_42",
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
          "cv_guideCN_78",
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
          "cv_guideCN_78",
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
          "cv_guideCN_44",
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
          "cv_guideCN_44",
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
          "cv_guideCN_81",
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
          "cv_guideCN_81",
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
          "cv_guideCN_606",
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
          "cv_guideCN_607",
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
          "cv_guideCN_607",
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
          "cv_guideCN_607",
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
          "cv_guideCN_82",
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
          "cv_guideCN_82",
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
          "cv_guideCN_83",
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
          "cv_guideCN_83",
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
          "cv_guideCN_84",
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
          "cv_guideCN_84",
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
          "cv_guideCN_85",
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
          "cv_guideCN_85",
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
          "cv_guideCN_86",
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
          "cv_guideCN_86",
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
          "cv_guideCN_87",
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
          "cv_guideCN_87",
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
          "cv_guideCN_88",
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
          "cv_guideCN_88",
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
  [1520] = {
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
  [1530] = {
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
  [1570] = {
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
      13
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
  [1651] = {
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
          "cv_guideCN_55",
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
          "cv_guideCN_55",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\229\135\186\229\190\129\230\140\137\233\146\174"
  },
  [1652] = {
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
        "copypage_btn_haiyu"
      },
      {
        GUIDE_BEHAVIOUR.PlayAudio,
        {
          "cv_guideCN_89",
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
          "cv_guideCN_89",
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
          "cv_guideCN_90",
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
          "cv_guideCN_90",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\181\183\229\159\159\231\172\172\228\184\128\229\133\179"
  },
  [16531] = {
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
          "cv_guideCN_90",
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
          "cv_guideCN_90",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187\230\181\183\229\159\1591_A"
  },
  [16532] = {
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
          "cv_guideCN_91",
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
          "cv_guideCN_91",
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
  [1610] = {
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
          "cv_guideCN_92",
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
          "cv_guideCN_92",
          false
        }
      }
    },
    Note = "\230\137\147\229\188\128home_build_btn"
  },
  [1611] = {
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
          "cv_guideCN_93",
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
          "cv_guideCN_93",
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
  [1612] = {
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
          "cv_guideCN_94",
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
          "cv_guideCN_94",
          false
        }
      }
    },
    Note = "\230\137\147\229\188\128home_build_btn"
  },
  [1620] = {
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
          "cv_guideCN_95",
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
          "cv_guideCN_95",
          false
        }
      }
    },
    Note = "\231\130\185\229\135\187buildShipPage_btn"
  },
  [1630] = {
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
          "cv_guideCN_96",
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
          "cv_guideCN_96",
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
  [1640] = {
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
  [1650] = {
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
          "cv_guideCN_134",
          true
        }
      },
      {
        GUIDE_BEHAVIOUR.SHOW_SIMPLE_TIP,
        "Ship_btn_close"
      },
      {
        GUIDE_BEHAVIOUR.SHOW_BLACK_MASK,
        true
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
          "cv_guideCN_134",
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
          "cv_guideCN_142",
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
          "cv_guideCN_142",
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
          "cv_guideCN_135",
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
          "cv_guideCN_135",
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
          "cv_guideCN_136",
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
          "cv_guideCN_136",
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
  [1681] = {
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
          "cv_guideCN_219",
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
          "cv_guideCN_219",
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
          "cv_guideCN_220",
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
          "cv_guideCN_220",
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
          "cv_guideCN_210",
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
          "cv_guideCN_210",
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
          "cv_guideCN_211",
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
          "cv_guideCN_211",
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
          "cv_guideCN_212",
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
          "cv_guideCN_212",
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
          "cv_guideCN_213",
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
          "cv_guideCN_213",
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
          "cv_guideCN_214",
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
          "cv_guideCN_214",
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
          "cv_guideCN_215",
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
          "cv_guideCN_215",
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
          "cv_guideCN_216",
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
          "cv_guideCN_216",
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
          "cv_guideCN_205",
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
          "cv_guideCN_205",
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
          "cv_guideCN_206",
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
          "cv_guideCN_206",
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
          "cv_guideCN_207",
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
          "cv_guideCN_207",
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
          "cv_guideCN_208",
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
          "cv_guideCN_208",
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
          "cv_guideCN_206",
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
          "cv_guideCN_206",
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
          "cv_guideCN_207",
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
          "cv_guideCN_207",
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
          "cv_guideCN_120",
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
          "cv_guideCN_120",
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
          "cv_guideCN_121",
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
          "cv_guideCN_121",
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
          "cv_guideCN_125",
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
          "cv_guideCN_125",
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
          "cv_guideCN_126",
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
          "cv_guideCN_126",
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
          "cv_guideCN_127",
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
          "cv_guideCN_127",
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
          "cv_guideCN_128",
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
          "cv_guideCN_128",
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
          "cv_guideCN_122",
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
          "cv_guideCN_122",
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
          "cv_guideCN_123",
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
          "cv_guideCN_123",
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
          "cv_guideCN_124",
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
          "cv_guideCN_124",
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
          "cv_guideCN_221",
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
          "cv_guideCN_221",
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
          "cv_guideCN_222",
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
          "cv_guideCN_222",
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
          "cv_guideCN_202",
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
          "cv_guideCN_202",
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
          "cv_guideCN_203",
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
          "cv_guideCN_203",
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
          "cv_guideCN_223",
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
          "cv_guideCN_223",
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
          "cv_guideCN_224",
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
          "cv_guideCN_224",
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
          "cv_guideCN_225",
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
          "cv_guideCN_225",
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
          "cv_guideCN_226",
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
          "cv_guideCN_226",
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
          "cv_guideCN_227",
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
          "cv_guideCN_227",
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
          "cv_guideCN_228",
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
          "cv_guideCN_228",
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
          "cv_guideCN_229",
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
          "cv_guideCN_229",
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
          "cv_guideCN_230",
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
          "cv_guideCN_230",
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
          "cv_guideCN_231",
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
          "cv_guideCN_231",
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
          "cv_guideCN_209",
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
          "cv_guideCN_209",
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
          "cv_guideCN_204",
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
          "cv_guideCN_204",
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
          "cv_guideCN_232",
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
          "cv_guideCN_232",
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
          "cv_guideCN_233",
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
          "cv_guideCN_233",
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
          "cv_guideCN_234",
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
          "cv_guideCN_234",
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
          "cv_guideCN_235",
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
          "cv_guideCN_235",
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
          "cv_guideCN_236",
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
          "cv_guideCN_236",
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
          "cv_guideCN_237",
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
          "cv_guideCN_237",
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
          "cv_guideCN_238",
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
          "cv_guideCN_238",
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
          "cv_guideCN_239",
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
          "cv_guideCN_239",
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
          "cv_guideCN_240",
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
          "cv_guideCN_240",
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
          "cv_guideCN_241",
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
          "cv_guideCN_241",
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
          "cv_guideCN_242",
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
          "cv_guideCN_242",
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
          "cv_guideCN_243",
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
          "cv_guideCN_243",
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
          "cv_guideCN_244",
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
          "cv_guideCN_244",
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
          "cv_guideCN_245",
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
          "cv_guideCN_245",
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
          "cv_guideCN_246",
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
          "cv_guideCN_246",
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
          "cv_guideCN_247",
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
          "cv_guideCN_247",
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
          "cv_guideCN_248",
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
          "cv_guideCN_248",
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
          "cv_guideCN_217",
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
          "cv_guideCN_217",
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
          "cv_guideCN_218",
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
          "cv_guideCN_218",
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
          "cv_guideCN_250",
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
          "cv_guideCN_250",
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
          "cv_guideCN_251",
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
          "cv_guideCN_251",
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
          "cv_guideCN_252",
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
          "cv_guideCN_252",
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
          "cv_guideCN_253",
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
          "cv_guideCN_253",
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
          "cv_guideCN_254",
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
          "cv_guideCN_254",
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
          "cv_guideCN_255",
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
          "cv_guideCN_255",
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
          "cv_guideCN_303",
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
          "cv_guideCN_303",
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
          "cv_guideCN_256",
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
          "cv_guideCN_256",
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
          "cv_guideCN_257",
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
          "cv_guideCN_257",
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
          "cv_guideCN_258",
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
          "cv_guideCN_258",
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
          "cv_guideCN_259",
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
          "cv_guideCN_259",
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
          "cv_guideCN_260",
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
          "cv_guideCN_260",
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
          "cv_guideCN_261",
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
          "cv_guideCN_261",
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
          "cv_guideCN_310",
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
          "cv_guideCN_310",
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
          "cv_guideCN_311",
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
          "cv_guideCN_311",
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
          "cv_guideCN_312",
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
          "cv_guideCN_312",
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
          "cv_guideCN_130",
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
          "cv_guideCN_130",
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
          "cv_guideCN_313",
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
          "cv_guideCN_313",
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
          "cv_guideCN_262",
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
          "cv_guideCN_262",
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
          "cv_guideCN_263",
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
          "cv_guideCN_263",
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
          "cv_guideCN_264",
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
          "cv_guideCN_264",
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
          "cv_guideCN_265",
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
          "cv_guideCN_265",
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
          "cv_guideCN_270",
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
          "cv_guideCN_270",
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
          "cv_guideCN_271",
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
          "cv_guideCN_271",
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
          "cv_guideCN_271",
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
          "cv_guideCN_272",
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
          "cv_guideCN_272",
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
          "cv_guideCN_273",
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
          "cv_guideCN_273",
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
          "cv_guideCN_274",
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
          "cv_guideCN_274",
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
          "cv_guideCN_275",
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
          "cv_guideCN_275",
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
          "cv_guideCN_276",
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
          "cv_guideCN_276",
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
          "cv_guideCN_276",
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
          "cv_guideCN_277",
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
          "cv_guideCN_277",
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
          "cv_guideCN_278",
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
          "cv_guideCN_278",
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
          "cv_guideCN_279",
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
          "cv_guideCN_279",
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
          "cv_guideCN_280",
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
          "cv_guideCN_280",
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
          "cv_guideCN_281",
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
          "cv_guideCN_281",
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
          "cv_guideCN_281",
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
          "cv_guideCN_283",
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
          "cv_guideCN_283",
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
          "cv_guideCN_130",
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
          "cv_guideCN_130",
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
          "cv_guideCN_284",
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
          "cv_guideCN_284",
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
          "cv_guideCN_285",
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
          "cv_guideCN_285",
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
          "cv_guideCN_286",
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
          "cv_guideCN_286",
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
          "cv_guideCN_287",
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
          "cv_guideCN_287",
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
          "cv_guideCN_134",
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
          "cv_guideCN_134",
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
          "cv_guideCN_289",
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
          "cv_guideCN_289",
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
          "cv_guideCN_290",
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
          "cv_guideCN_290",
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
          "cv_guideCN_290",
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
          "cv_guideCN_232",
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
          "cv_guideCN_232",
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
          "cv_guideCN_219",
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
          "cv_guideCN_219",
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
          "cv_guideCN_292",
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
          "cv_guideCN_292",
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
          "cv_guideCN_293",
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
          "cv_guideCN_293",
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
          "cv_guideCN_294",
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
          "cv_guideCN_294",
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
          "cv_guideCN_295",
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
          "cv_guideCN_295",
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
          "cv_guideCN_130",
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
          "cv_guideCN_130",
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
          "cv_guideCN_304",
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
          "cv_guideCN_304",
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
          "cv_guideCN_296",
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
          "cv_guideCN_296",
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
          "cv_guideCN_297",
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
          "cv_guideCN_297",
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
          "cv_guideCN_298",
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
          "cv_guideCN_298",
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
          "cv_guideCN_299",
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
          "cv_guideCN_299",
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
          "cv_guideCN_300",
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
          "cv_guideCN_300",
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
          "cv_guideCN_301",
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
          "cv_guideCN_301",
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
          "cv_guideCN_302",
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
          "cv_guideCN_302",
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
          "cv_guideCN_305",
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
          "cv_guideCN_305",
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
          "cv_guideCN_130",
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
          "cv_guideCN_130",
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
          "cv_guideCN_309",
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
          "cv_guideCN_403",
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
          "cv_guideCN_402",
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
  }
}
return GuideStepConfig
