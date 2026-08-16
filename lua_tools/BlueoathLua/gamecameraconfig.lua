return {
  [GameCameraType.RoomSceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 20,
        Pos = Vector3.New(0, 1.472, 1.6),
        Eur = Vector3.New(6.78, -180, 0),
        cullingMask = LayerMask.GetMask("MainSceneShip"),
        clearFlags = 3,
        depth = 1,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/3dcamerawithouttodlogic"
      },
      {
        Fov = 39,
        Pos = Vector3.New(0, 1.472, 1.6),
        Eur = Vector3.New(6.78, -180, 0),
        cullingMask = LayerMask.GetMask("Default", "Water", "Scene", "Floor", "Sky", "Scene_Outside", "Scene_Interactive"),
        clearFlags = 1,
        depth = 0,
        bMulti = false
      },
      {
        Fov = 35,
        Pos = Vector3.New(0, 1.472, 1.6),
        Eur = Vector3.New(6.78, -180, 0),
        cullingMask = LayerMask.GetMask(),
        clearFlags = 4,
        depth = 2,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.MagazineSceneCamera] = {
    bMulti = true,
    priority = -1,
    subCameras = {
      {
        Fov = 19,
        Pos = Vector3.New(4.38, 1.1, 0.87),
        Eur = Vector3.New(0, -89.9, 0),
        cullingMask = LayerMask.GetMask("Default", "Scene", "MainSceneShip", "Scene_Outside", "Scene_Outside", "Scene_Interactive"),
        clearFlags = 3,
        depth = 1
      },
      {
        Fov = 35,
        Pos = Vector3.New(0, 1.472, 1.6),
        Eur = Vector3.New(6.78, -180, 0),
        cullingMask = LayerMask.GetMask(),
        clearFlags = 4,
        depth = 2,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.MiniGameSceneCamera] = {
    bMulti = true,
    priority = -1,
    subCameras = {
      {
        Fov = 60,
        Pos = Vector3.New(1.34, 1.21, -100),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = LayerMask.GetMask("Default", "Scene"),
        clearFlags = 3,
        depth = -1
      },
      {
        Fov = 35,
        Pos = Vector3.New(0, 1.472, 1.6),
        Eur = Vector3.New(6.78, -180, 0),
        cullingMask = LayerMask.GetMask(),
        clearFlags = 4,
        depth = 2,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.RemouldSceneCamera] = {
    bMulti = true,
    priority = -1,
    subCameras = {
      {
        Fov = 35,
        Pos = Vector3.New(0, 0.3, -10),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = LayerMask.GetMask("Default", "Scene"),
        clearFlags = 2,
        depth = 1,
        templatePath = "commonmodels/normalcameratemplate/remouldcamera"
      }
    }
  },
  [GameCameraType.BuildSceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 45,
        Pos = Vector3.New(0, 1.5, 2.6),
        Eur = Vector3.New(-5, 180, 0),
        cullingMask = LayerMask.GetMask("Default", "Water", "Scene", "MainScenePlayer", "Scene_Outside", "Scene_Interactive")
      },
      {
        Fov = 35,
        Pos = Vector3.New(0, 1.472, 1.6),
        Eur = Vector3.New(6.78, -180, 0),
        cullingMask = LayerMask.GetMask(),
        clearFlags = 4,
        depth = 2,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.BathRoomSceneCamera] = {
    Fov = 37.29902,
    Pos = Vector3.New(0, 0, 0),
    Eur = Vector3.New(0, 0, 0),
    cullingMask = LayerMask.GetMask("Default", "Water", "Scene")
  },
  [GameCameraType.MarrySceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = LayerMask.GetMask("Default", "Water", "Scene", "MainSceneShip"),
        depth = 0
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = LayerMask.GetMask("Default", "Water", "Scene", "MainSceneShip"),
        depth = 1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        depth = 2
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.UI3DModel] = {
    cullingMask = LayerMask.GetMask("UI3DObject"),
    clearFlags = 2,
    templatePath = "commonmodels/normalcameratemplate/ui3dcamera",
    depth = 1
  },
  [GameCameraType.UI3DModelRemould] = {
    cullingMask = LayerMask.GetMask("UI3DObject"),
    clearFlags = 2,
    templatePath = "commonmodels/normalcameratemplate/remouldcamera_ui",
    depth = 1
  },
  [GameCameraType.InfrastructureSceneCamera] = {
    Fov = 25,
    Pos = Vector3.New(19.4, 11.0, 19.3),
    Eur = Vector3.New(22.518, -134.373, 0),
    cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "NavMesh"),
    depth = -1
  },
  [GameCameraType.TowerSceneCamera] = {
    Fov = 60,
    Pos = Vector3.New(2.04, 4.163683, -17.43457),
    Eur = Vector3.New(22.632, -0.951, 0),
    cullingMask = LayerMask.GetMask("Default", "Water", "Sky", "ShipLayer"),
    depth = -1,
    templatePath = "commonmodels/normalcameratemplate/towercamera"
  },
  [GameCameraType.OfficeSceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 25,
        virtualNode = {
          {
            Pos = Vector3.New(-1.47, 0.99, 0.1)
          },
          {
            Pos = Vector3.New(5.753952, 3.200955, 8.895394),
            Eur = Vector3.New(16.812, -147.103, 0.0)
          }
        },
        cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "Scene_Interactive", "NavMesh"),
        depth = -1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.ElectricFactorySceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 25,
        virtualNode = {
          {
            Pos = Vector3.New(-4.4, 2.1, -1.0)
          },
          {
            Pos = Vector3.New(21.5, 4.5, -0.2),
            Eur = Vector3.New(11.9, 270.6, 0.0)
          }
        },
        cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "Scene_Interactive", "NavMesh"),
        depth = -1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.OilFactorySceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 25,
        virtualNode = {
          {
            Pos = Vector3.New(2.8, 0.2, -1.3)
          },
          {
            Pos = Vector3.New(-12.5, 9.1, 14.3),
            Eur = Vector3.New(25.6, 138.9, 0.0)
          }
        },
        cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "Scene_Interactive", "NavMesh"),
        depth = -1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.ResourceFactorySceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 25,
        virtualNode = {
          {
            Pos = Vector3.New(-3.7, 0.0, -3.7)
          },
          {
            Pos = Vector3.New(12.4, 3.8, 15.3),
            Eur = Vector3.New(11.1, 219, 0.0)
          }
        },
        cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "Scene_Interactive", "NavMesh"),
        depth = -1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.DormRoomSceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 25,
        virtualNode = {
          {
            Pos = Vector3.New(1.29, 1.288, -0.41)
          },
          {
            Pos = Vector3.New(8.150471, 3.323221, 6.258279),
            Eur = Vector3.New(17.921, -127.519, 0.0)
          }
        },
        cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "Scene_Interactive", "NavMesh"),
        depth = -1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.FoodFactorySceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 25,
        virtualNode = {
          {
            Pos = Vector3.New(-0.4, 0.051, 0.49)
          },
          {
            Pos = Vector3.New(-10.48835, 3.624092, 10.0926),
            Eur = Vector3.New(13.981, 133.898, 0.0)
          }
        },
        cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "Scene_Interactive", "NavMesh"),
        depth = -1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.ItemFactorySceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 25,
        virtualNode = {
          {
            Pos = Vector3.New(-0.07, 0.33, 0.13)
          },
          {
            Pos = Vector3.New(6.724433, 4.704345, 10.08222),
            Eur = Vector3.New(21.215, -146.298, 0.0)
          }
        },
        cullingMask = LayerMask.GetMask("Default", "Scene_Outside", "Scene", "Scene_Interactive", "NavMesh"),
        depth = -1
      },
      {
        Fov = 45,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = 0,
        clearFlags = 4,
        depth = 3,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/postprocesscamera"
      }
    }
  },
  [GameCameraType.MubarSceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 35,
        Pos = Vector3.New(0, 0, 0),
        Eur = Vector3.New(0, 0, 0),
        cullingMask = LayerMask.GetMask("Default", "Scene"),
        clearFlags = 3,
        depth = 1,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/cj_mb_camera"
      }
    }
  },
  [GameCameraType.MultiPveSceneCamera] = {
    bMulti = true,
    subCameras = {
      {
        Fov = 60,
        Pos = Vector3.New(0, 2, 1.6),
        Eur = Vector3.New(6.78, -180, 0),
        cullingMask = LayerMask.GetMask("MainSceneShip"),
        clearFlags = 3,
        depth = 1,
        bMulti = false,
        templatePath = "commonmodels/normalcameratemplate/3dcamerawithouttodlogic"
      },
      {
        Fov = 60,
        Pos = Vector3.New(10.12, 1.581, -2.253),
        Eur = Vector3.New(1.757, -13.968, 0.199),
        cullingMask = LayerMask.GetMask("Default", "Water", "Sky", "MainSceneShip"),
        depth = -1,
        bMulti = false
      }
    }
  }
}
