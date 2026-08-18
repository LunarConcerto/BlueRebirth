local GuideStageConfig = {}
GuideStageConfig.stages = {
  {
    id = 10000,
    nodes = {
      {
        id = 110,
        condition = {
          {
            {
              34,
              nil,
              false
            },
            111
          },
          {
            {
              32,
              nil,
              false
            },
            112
          },
          {
            {
              35,
              nil,
              false
            },
            113
          },
          {
            {
              33,
              nil,
              false
            },
            114
          }
        },
        recallNodeId = 101,
        jumpCondition = {
          23,
          100,
          false
        }
      },
      {
        id = 130,
        condition = {
          {
            {
              31,
              nil,
              false
            },
            131
          },
          {
            {
              30,
              nil,
              false
            },
            132
          }
        },
        recallNodeId = 101,
        jumpCondition = {
          23,
          100,
          false
        }
      },
      {
        id = 100,
        config = {10002},
        keyPoint = 1,
        nextNodeId = 101
      },
      {
        id = 101,
        config = {
          10101,
          10102,
          10103
        },
        keyPoint = 3,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 110
      },
      {
        id = 111,
        config = {11101},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 120
      },
      {
        id = 112,
        config = {11201},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 120
      },
      {
        id = 113,
        config = {11301},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 120
      },
      {
        id = 114,
        config = {11401},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 120
      },
      {
        id = 120,
        config = {12011},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 130
      },
      {
        id = 131,
        config = {13101},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 140
      },
      {
        id = 132,
        config = {13201},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 140
      },
      {
        id = 140,
        config = {14021},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 150
      },
      {
        id = 150,
        config = {
          15011,
          15012,
          15013,
          15014,
          15015,
          15016,
          15017,
          15018
        },
        keyPoint = 8,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 160
      },
      {
        id = 160,
        config = {
          16001,
          16002,
          16003
        },
        keyPoint = 4,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 170
      },
      {
        id = 170,
        config = {17021},
        keyPoint = 1,
        jumpCondition = {
          23,
          100,
          false
        },
        recallNodeId = 101,
        nextNodeId = 200
      },
      {
        id = 200,
        config = {20010, 20011},
        keyPoint = 2,
        recallNodeId = 200,
        nextNodeId = 210
      },
      {
        id = 210,
        config = {21021, 21022},
        keyPoint = 2,
        jumpCondition = {
          23,
          2,
          false
        },
        recallNodeId = 211,
        nextNodeId = 220
      },
      {
        id = 220,
        config = {22001},
        keyPoint = 1,
        jumpCondition = {
          27,
          1,
          false
        },
        recallNodeId = 221,
        nextNodeId = 230
      },
      {
        id = 230,
        config = {23001, 23002},
        keyPoint = 2,
        jumpCondition = {
          23,
          3,
          false
        },
        recallNodeId = 231,
        nextNodeId = 300
      },
      {
        id = 211,
        config = {21101},
        keyPoint = 1,
        nextNodeId = 210
      },
      {
        id = 221,
        config = {21101},
        keyPoint = 1,
        nextNodeId = 220
      },
      {
        id = 231,
        config = {21101},
        keyPoint = 1,
        nextNodeId = 230
      },
      {
        id = 300,
        config = {30011},
        keyPoint = 1,
        jumpCondition = {
          23,
          13,
          false
        },
        nextNodeId = 310
      },
      {
        id = 310,
        config = {
          31011,
          31012,
          31013
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
        nextNodeId = 320
      },
      {
        id = 320,
        config = {
          32001,
          32002,
          32003,
          32004
        },
        keyPoint = 4,
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
        recallNodeId = 321,
        nextNodeId = 330
      },
      {
        id = 321,
        config = {31011},
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
        nextNodeId = 320
      },
      {
        id = 330,
        config = {
          33001,
          33002,
          33003
        },
        keyPoint = 3,
        jumpCondition = {
          26,
          {2, 1},
          false
        },
        nextNodeId = 400
      },
      {
        id = 400,
        config = {
          40013,
          40014,
          40015,
          40016,
          40017
        },
        keyPoint = 5,
        jumpCondition = {
          36,
          30082,
          false
        },
        recallNodeId = 401,
        nextNodeId = 500
      },
      {
        id = 401,
        config = {
          40011,
          40012,
          40013,
          40014,
          40015,
          40016,
          40017
        },
        keyPoint = 7,
        jumpCondition = {
          36,
          30082,
          false
        },
        nextNodeId = 500
      },
      {
        id = 500,
        config = {
          50014,
          50015,
          50016,
          50017
        },
        keyPoint = 4,
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
        recallNodeId = 501,
        nextNodeId = 600
      },
      {
        id = 501,
        config = {
          50011,
          50012,
          50013,
          50014,
          50015,
          50016,
          50017
        },
        keyPoint = 7,
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
        nextNodeId = 600
      },
      {
        id = 600,
        config = {
          60003,
          60004,
          60005,
          60006
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
        recallNodeId = 601,
        nextNodeId = 700
      },
      {
        id = 601,
        config = {
          60001,
          60002,
          60003,
          60004,
          60005,
          60006
        },
        keyPoint = 5,
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
        nextNodeId = 700
      },
      {
        id = 700,
        config = {
          70003,
          70004,
          70005,
          70006
        },
        keyPoint = 2,
        jumpCondition = {
          40,
          nil,
          false
        },
        recallNodeId = 701,
        nextNodeId = 800
      },
      {
        id = 701,
        config = {
          70001,
          70002,
          70003,
          70004,
          70005,
          70006
        },
        keyPoint = 4,
        jumpCondition = {
          40,
          nil,
          false
        },
        nextNodeId = 800
      },
      {
        id = 800,
        config = {
          80001,
          80003,
          80004,
          80005,
          80006
        },
        keyPoint = 4,
        jumpCondition = {
          49,
          nil,
          false
        },
        recallNodeId = 801
      },
      {
        id = 801,
        config = {
          80002,
          80003,
          80004,
          80005,
          80006
        },
        keyPoint = 4,
        jumpCondition = {
          49,
          nil,
          false
        }
      }
    },
    triggerType = {1, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 1000,
    firstNodeId = 100
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
  },
  {
    id = 140000,
    nodes = {
      {
        id = 9901,
        config = {50001, 50002},
        keyPoint = 1
      }
    },
    triggerType = {140, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 600,
    firstNodeId = 9901
  },
  {
    id = 150000,
    nodes = {
      {
        id = 1500001,
        config = {
          150000101,
          150000102,
          150000103
        },
        keyPoint = 1
      }
    },
    triggerType = {142, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 420,
    firstNodeId = 1500001
  },
  {
    id = 160000,
    nodes = {
      {
        id = 1600001,
        config = {160000101},
        keyPoint = 1,
        jumpCondition = {51, false}
      }
    },
    triggerType = {143, nil},
    condition = {
      0,
      nil,
      false
    },
    weight = 420,
    firstNodeId = 1600001
  }
}
return GuideStageConfig
