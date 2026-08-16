local GuideStageConfig = {}
GuideStageConfig.stages = {
  {
    id = 10000,
    nodes = {
      {
        id = 6,
        condition = {
          {
            {
              34,
              nil,
              false
            },
            60001
          },
          {
            {
              32,
              nil,
              false
            },
            60002
          },
          {
            {
              35,
              nil,
              false
            },
            60003
          },
          {
            {
              33,
              nil,
              false
            },
            60004
          }
        },
        recallNodeId = 5,
        jumpCondition = {
          23,
          4,
          false
        }
      },
      {
        id = 8,
        condition = {
          {
            {
              31,
              nil,
              false
            },
            80001
          },
          {
            {
              30,
              nil,
              false
            },
            80002
          }
        },
        recallNodeId = 5,
        jumpCondition = {
          23,
          4,
          false
        }
      },
      {
        id = 1,
        config = {10, 20},
        keyPoint = 2,
        jumpCondition = {
          23,
          2,
          false
        },
        nextNodeId = 2
      },
      {
        id = 2,
        config = {30, 40},
        keyPoint = 2,
        nextNodeId = 3
      },
      {
        id = 3,
        config = {50},
        keyPoint = 1,
        jumpCondition = {
          27,
          1,
          false
        },
        nextNodeId = 4
      },
      {
        id = 4,
        config = {
          60,
          70,
          80
        },
        keyPoint = 3,
        jumpCondition = {
          23,
          3,
          false
        },
        nextNodeId = 5
      },
      {
        id = 11,
        config = {
          318,
          319,
          320,
          330,
          340,
          341,
          342,
          343,
          344,
          345,
          346,
          347,
          348,
          349
        },
        keyPoint = 13,
        jumpCondition = {
          23,
          6,
          false
        },
        nextNodeId = 15
      },
      {
        id = 12,
        config = {
          301,
          302,
          303
        },
        keyPoint = 3,
        jumpCondition = {
          26,
          {2, 1},
          false
        },
        nextNodeId = 10
      },
      {
        id = 5,
        config = {
          90,
          100,
          110,
          120,
          121,
          122,
          123,
          124,
          130
        },
        keyPoint = 9,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 4001,
        nextNodeId = 6
      },
      {
        id = 60001,
        config = {140},
        keyPoint = 1,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 7
      },
      {
        id = 60002,
        config = {141},
        keyPoint = 1,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 7
      },
      {
        id = 60003,
        config = {142},
        keyPoint = 1,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 7
      },
      {
        id = 60004,
        config = {143},
        keyPoint = 1,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 7
      },
      {
        id = 7,
        config = {150},
        keyPoint = 1,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 8
      },
      {
        id = 80001,
        config = {160, 170},
        keyPoint = 2,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 9
      },
      {
        id = 80002,
        config = {160, 171},
        keyPoint = 2,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 9
      },
      {
        id = 9,
        config = {
          180,
          190,
          200,
          210,
          220,
          230,
          240,
          250,
          260,
          270,
          271,
          272,
          280,
          290,
          300
        },
        keyPoint = 13,
        jumpCondition = {
          23,
          4,
          false
        },
        recallNodeId = 5,
        nextNodeId = 12
      },
      {
        id = 10,
        config = {
          309,
          310,
          311,
          312,
          313,
          314,
          315,
          316,
          317
        },
        keyPoint = 7,
        jumpCondition = {
          36,
          30082,
          false
        },
        nextNodeId = 11
      },
      {
        id = 15,
        config = {
          350,
          360,
          370,
          380,
          390,
          400,
          410,
          420,
          430
        },
        keyPoint = 6,
        jumpCondition = {
          38,
          {
            3,
            {
              {
                1,
                60000,
                3
              }
            }
          },
          false
        },
        nextNodeId = 17
      },
      {
        id = 17,
        config = {
          490,
          319,
          500,
          510,
          520,
          750,
          760,
          770,
          810,
          820,
          830,
          840,
          850,
          860,
          870,
          880,
          890,
          900,
          910,
          920,
          930,
          940,
          950,
          970,
          980,
          990,
          1000,
          1010,
          1020
        },
        keyPoint = 26,
        jumpCondition = {
          23,
          7,
          false
        },
        nextNodeId = 179
      },
      {
        id = 18,
        config = {
          1041,
          1042,
          1043,
          1044
        },
        keyPoint = 3,
        jumpCondition = {
          25,
          {
            {
              15,
              150001,
              1
            }
          },
          false
        },
        recallNodeId = 179,
        nextNodeId = 181
      },
      {
        id = 19,
        config = {
          1140,
          1150,
          1160,
          1170,
          1171
        },
        keyPoint = 2,
        jumpCondition = {
          40,
          nil,
          false
        },
        recallNodeId = 189,
        nextNodeId = 20
      },
      {
        id = 189,
        config = {1030, 1040},
        keyPoint = 2,
        jumpCondition = {
          22,
          {2, 1},
          false
        },
        nextNodeId = 19
      },
      {
        id = 20,
        config = {
          1180,
          319,
          1190,
          1191,
          1192,
          1280,
          1290,
          1300,
          1310,
          1320,
          1330
        },
        keyPoint = 10,
        jumpCondition = {
          23,
          9,
          false
        },
        nextNodeId = 22
      },
      {
        id = 22,
        config = {
          1340,
          1350,
          1360
        },
        keyPoint = 3,
        jumpCondition = {
          23,
          10,
          false
        },
        nextNodeId = 23
      },
      {
        id = 23,
        config = {
          1380,
          1390,
          1400,
          1401,
          1402,
          1410,
          1420,
          1430,
          1440,
          1450,
          1460,
          1470,
          1480,
          1490,
          1500,
          1510,
          1520
        },
        keyPoint = 15,
        jumpCondition = {
          23,
          11,
          false
        },
        nextNodeId = 24
      },
      {
        id = 24,
        config = {
          1530,
          1540,
          1550
        },
        keyPoint = 1,
        jumpCondition = {
          23,
          13,
          false
        },
        recallNodeId = 239,
        nextNodeId = 25
      },
      {
        id = 239,
        config = {15201},
        jumpCondition = {
          23,
          13,
          false
        },
        nextNodeId = 24
      },
      {
        id = 25,
        config = {1560, 1570},
        keyPoint = 2,
        jumpCondition = {
          23,
          13,
          false
        },
        recallNodeId = 249,
        nextNodeId = 27
      },
      {
        id = 249,
        config = {1520, 1530},
        keyPoint = 1,
        jumpCondition = {
          23,
          13,
          false
        },
        nextNodeId = 25
      },
      {
        id = 26,
        config = {
          1652,
          16531,
          16532
        },
        keyPoint = 4,
        jumpCondition = {
          51,
          nil,
          false
        },
        recallNodeId = 269,
        nextNodeId = 30
      },
      {
        id = 27,
        config = {
          1610,
          1611,
          1612
        },
        keyPoint = 2,
        jumpCondition = {
          25,
          {
            {
              1,
              10181,
              10
            }
          },
          false
        },
        nextNodeId = 28
      },
      {
        id = 279,
        config = {1610},
        keyPoint = 1,
        jumpCondition = {
          25,
          {
            {
              1,
              10007,
              10
            }
          },
          false
        },
        nextNodeId = 28
      },
      {
        id = 28,
        config = {
          1620,
          1630,
          1640,
          1650
        },
        keyPoint = 2,
        jumpCondition = {
          25,
          {
            {
              1,
              10007,
              10
            }
          },
          false
        },
        recallNodeId = 279,
        nextNodeId = 269
      },
      {
        id = 181,
        config = {
          1050,
          1060,
          1100,
          1110,
          1120,
          1130
        },
        keyPoint = 8,
        jumpCondition = {
          39,
          10210111,
          false
        },
        recallNodeId = 1801,
        nextNodeId = 19
      },
      {
        id = 1801,
        config = {1030, 1040},
        keyPoint = 2,
        jumpCondition = {
          39,
          10210111,
          false
        },
        nextNodeId = 181
      },
      {
        id = 179,
        config = {1030, 1040},
        keyPoint = 2,
        jumpCondition = {
          25,
          {
            {
              15,
              150001,
              1
            }
          },
          false
        },
        nextNodeId = 18
      },
      {
        id = 269,
        config = {1651},
        keyPoint = 1,
        jumpCondition = {
          49,
          nil,
          false
        },
        nextNodeId = 26
      },
      {
        id = 30,
        config = {1681},
        keyPoint = 1
      },
      {
        id = 4001,
        config = {60, 80},
        keyPoint = 2,
        nextNodeId = 5
      }
    },
    triggerType = {1, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 1000,
    firstNodeId = 1
  },
  {
    id = 100000,
    nodes = {
      {
        id = 210,
        condition = {
          {
            {
              28,
              nil,
              false
            },
            230
          },
          {
            {
              29,
              nil,
              false
            },
            220
          }
        }
      },
      {
        id = 220,
        config = {4000},
        keyPoint = 1
      },
      {
        id = 230,
        config = {4001},
        keyPoint = 1
      }
    },
    triggerType = {136, nil},
    exitTrigger = {94, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 500,
    firstNodeId = 210
  },
  {
    id = 1000000,
    nodes = {
      {
        id = 510,
        config = {10000, 10001},
        keyPoint = 1
      }
    },
    triggerType = {101, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 50,
    firstNodeId = 510
  },
  {
    id = 99995,
    nodes = {
      {
        id = 10501,
        config = {
          191051,
          191052,
          191053,
          191054,
          191055
        },
        keyPoint = 1
      }
    },
    triggerType = {135, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 50,
    firstNodeId = 10501
  },
  {
    id = 99998,
    nodes = {
      {
        id = 10801,
        config = {191081, 191082},
        keyPoint = 1
      }
    },
    triggerType = {130, 160080000},
    condition = {
      0,
      nil,
      false
    },
    weight = 500,
    firstNodeId = 10801
  },
  {
    id = 99992,
    nodes = {
      {
        id = 20201,
        config = {
          191091,
          191092,
          191093,
          1653,
          1654,
          1655
        },
        keyPoint = 1
      }
    },
    triggerType = {
      129,
      {
        passedCopy = 1601000,
        notPassCopy = 1610100,
        curChapterId = 1002
      }
    },
    condition = {
      0,
      nil,
      false
    },
    weight = 500,
    firstNodeId = 20201
  },
  {
    id = 1200000,
    nodes = {
      {
        id = 722,
        condition = {
          {
            {
              46,
              34,
              false
            },
            723
          },
          {
            {
              47,
              34,
              false
            },
            724
          }
        },
        recallNodeId = 721,
        jumpCondition = {
          23,
          400000,
          false
        }
      },
      {
        id = 721,
        config = {
          17001,
          17002,
          17003,
          17004,
          17005,
          17006,
          17106,
          17007,
          17008,
          17009,
          17010,
          17011,
          17012
        },
        keyPoint = 1,
        jumpCondition = {
          23,
          400000,
          false
        },
        nextNodeId = 722
      },
      {
        id = 723,
        config = {
          1701211,
          1701212,
          1701213,
          1711214,
          1701214,
          17013,
          17014
        },
        keyPoint = 1,
        jumpCondition = {
          23,
          400000,
          false
        },
        recallNodeId = 721
      },
      {
        id = 724,
        config = {17013, 17014},
        keyPoint = 1,
        jumpCondition = {
          23,
          400000,
          false
        },
        recallNodeId = 721
      }
    },
    triggerType = {114, nil},
    condition = {
      23,
      500000,
      true
    },
    weight = 58,
    firstNodeId = 721
  },
  {
    id = 14000,
    nodes = {
      {
        id = 14001,
        config = {
          14000,
          14001,
          14002,
          14003,
          14004,
          14005,
          14006,
          14007,
          14008,
          14009,
          14010,
          14011,
          14012,
          14013
        },
        keyPoint = 1
      }
    },
    triggerType = {107, nil},
    condition = {
      23,
      20201,
      true
    },
    weight = 50,
    firstNodeId = 14001
  },
  {
    id = 200000,
    nodes = {
      {
        id = 240,
        config = {
          6000,
          6001,
          6002,
          6003,
          6004
        },
        keyPoint = 1
      }
    },
    triggerType = {88, 160010000},
    exitTrigger = {94, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 500,
    firstNodeId = 240
  },
  {
    id = 22001,
    nodes = {
      {
        id = 601,
        config = {15001, 15002},
        keyPoint = 1
      }
    },
    triggerType = {108, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 10,
    firstNodeId = 601
  },
  {
    id = 300000,
    nodes = {
      {
        id = 300,
        config = {8000, 8001},
        keyPoint = 1
      }
    },
    triggerType = {97, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 500,
    firstNodeId = 300
  },
  {
    id = 40001,
    nodes = {
      {
        id = 41,
        config = {2020},
        keyPoint = 1
      }
    },
    triggerType = {51, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 500,
    firstNodeId = 41
  },
  {
    id = 700000,
    nodes = {
      {
        id = 7001,
        config = {
          11000,
          11001,
          11021,
          11002,
          11003,
          11004,
          11005
        },
        keyPoint = 1
      }
    },
    triggerType = {102, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 460,
    firstNodeId = 7001
  },
  {
    id = 800000,
    nodes = {
      {
        id = 8001,
        config = {
          12001,
          2040,
          2050,
          2051,
          2052,
          2053,
          2054,
          2060
        },
        keyPoint = 1
      }
    },
    triggerType = {105, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 420,
    firstNodeId = 8001
  },
  {
    id = 910000,
    nodes = {
      {
        id = 250,
        config = {
          7000,
          7001,
          7002
        },
        keyPoint = 1
      }
    },
    triggerType = {
      87,
      {
        5011,
        5012,
        5013,
        5014,
        15011,
        15012,
        15013,
        15014
      }
    },
    condition = {
      0,
      nil,
      false
    },
    weight = 500,
    firstNodeId = 250
  },
  {
    id = 92000,
    nodes = {
      {
        id = 9201,
        config = {
          12004,
          12005,
          2210
        },
        keyPoint = 1
      }
    },
    triggerType = {106, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 100,
    firstNodeId = 9201
  },
  {
    id = 93000,
    nodes = {
      {
        id = 8801,
        config = {18001},
        keyPoint = 1,
        nextNodeId = 8802
      },
      {
        id = 8802,
        config = {
          18002,
          19001,
          1900111,
          19002,
          19003,
          19004,
          19005,
          19006,
          18003,
          18004,
          18005,
          18006
        },
        keyPoint = 1,
        recallNodeId = 8801,
        nextNodeId = 8803
      },
      {
        id = 8803,
        config = {
          18007,
          18008,
          180821,
          18009,
          18010,
          18011
        },
        keyPoint = 2,
        jumpCondition = {
          43,
          {2, 2},
          false
        },
        recallNodeId = 18803,
        nextNodeId = 8804
      },
      {
        id = 18803,
        config = {18001},
        keyPoint = 1,
        nextNodeId = 8803
      },
      {
        id = 8804,
        config = {
          18012,
          18013,
          181321,
          18014,
          18015,
          18016
        },
        keyPoint = 2,
        jumpCondition = {
          43,
          {3, 6},
          false
        },
        recallNodeId = 18804,
        nextNodeId = 8805
      },
      {
        id = 18804,
        config = {18001},
        keyPoint = 1,
        nextNodeId = 8804
      },
      {
        id = 8805,
        config = {
          18017,
          18018,
          181821,
          18019
        },
        keyPoint = 2,
        jumpCondition = {
          43,
          {4, 3},
          false
        },
        recallNodeId = 18805,
        nextNodeId = 8806
      },
      {
        id = 18805,
        config = {18001},
        keyPoint = 1,
        nextNodeId = 8805
      },
      {
        id = 8806,
        config = {
          18020,
          18020111,
          18021,
          18022,
          18023,
          18024,
          18025,
          18252,
          182521
        },
        keyPoint = 5,
        jumpCondition = {
          44,
          4,
          false
        },
        recallNodeId = 18806,
        nextNodeId = 8807
      },
      {
        id = 18806,
        config = {18001},
        keyPoint = 1,
        nextNodeId = 8806
      },
      {
        id = 8807,
        config = {
          18026,
          18027,
          182721,
          18028
        },
        keyPoint = 2,
        jumpCondition = {
          43,
          {5, 4},
          false
        },
        recallNodeId = 18807,
        nextNodeId = 8808
      },
      {
        id = 18807,
        config = {18001},
        keyPoint = 1,
        nextNodeId = 8807
      },
      {
        id = 8808,
        config = {18029, 18030},
        keyPoint = 1,
        recallNodeId = 18808
      },
      {
        id = 18808,
        config = {18001},
        keyPoint = 1,
        nextNodeId = 8808
      }
    },
    triggerType = {115, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 465,
    firstNodeId = 8801
  },
  {
    id = 94000,
    nodes = {
      {
        id = 8809,
        config = {
          180291,
          180301,
          18031
        },
        keyPoint = 1
      }
    },
    triggerType = {123, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 50,
    firstNodeId = 8809
  },
  {
    id = 95000,
    nodes = {
      {
        id = 8810,
        config = {
          18032,
          18032111,
          18322,
          18033,
          18034,
          18035,
          18036,
          18037,
          18038,
          18039
        },
        keyPoint = 1
      }
    },
    triggerType = {124, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 53,
    firstNodeId = 8810
  },
  {
    id = 96000,
    nodes = {},
    triggerType = {0, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 0,
    firstNodeId = 0
  },
  {
    id = 97000,
    nodes = {},
    triggerType = {0, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 0,
    firstNodeId = 0
  },
  {
    id = 98000,
    nodes = {
      {
        id = 98011,
        config = {21001},
        keyPoint = 1
      }
    },
    triggerType = {127, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 10,
    firstNodeId = 98011
  },
  {
    id = 99000,
    nodes = {
      {
        id = 9901,
        config = {
          20000,
          20001,
          20002,
          20003
        },
        keyPoint = 1
      }
    },
    triggerType = {126, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 600,
    firstNodeId = 9901
  },
  {
    id = 110000,
    nodes = {
      {
        id = 9901,
        config = {
          30001,
          30002,
          30003,
          30004
        },
        keyPoint = 1
      }
    },
    triggerType = {
      137,
      {160090000}
    },
    condition = {
      0,
      nil,
      false
    },
    weight = 600,
    firstNodeId = 9901
  },
  {
    id = 120000,
    nodes = {
      {
        id = 9901,
        config = {31001},
        keyPoint = 1,
        nextNodeId = 9902
      },
      {
        id = 9902,
        condition = {
          {
            {
              41,
              "FleetPage",
              false
            },
            9905
          },
          {
            {
              42,
              "FleetPage",
              false
            },
            9904
          }
        },
        recallNodeId = 9903
      },
      {
        id = 9903,
        config = {30},
        keyPoint = 1
      },
      {
        id = 9904,
        config = {
          31002,
          31003,
          31004,
          31005
        },
        keyPoint = 1
      },
      {
        id = 9905,
        config = {
          31003,
          31004,
          31005
        },
        keyPoint = 1
      }
    },
    triggerType = {138, nil},
    condition = {
      50,
      1611000,
      false
    },
    weight = 600,
    firstNodeId = 9901
  },
  {
    id = 130000,
    nodes = {
      {
        id = 9901,
        config = {
          40000,
          40001,
          40002,
          40003
        },
        keyPoint = 1
      }
    },
    triggerType = {131, 162070000},
    condition = {
      0,
      nil,
      false
    },
    weight = 600,
    firstNodeId = 9901
  }
}
return GuideStageConfig
