DataVersion = 1
NoticeType = {OneButton = 1, TwoButton = 2}
GlobalQuality = {
  None = -1,
  Low = 0,
  Medium = 1,
  High = 2,
  SuperHigh = 3,
  Custom = 4
}
QualityType = {
  ShaderQuality = "Shader",
  ActionQuality = "Action",
  ShadowQuality = "Shadow",
  AntiAliasingQuality = "AntiAliasing",
  ResolutionQuality = "Resolution",
  PostProcessQuality = "PostProcess",
  OutlineQuality = "Outline",
  FpsQuality = "Fps"
}
ResolutionQuality = {
  Low = 0,
  Middle = 1,
  High = 2
}
PostProcessQuality = {Close = 0, Open = 1}
OutlineQuality = {Close = 0, Open = 1}
SkyOceanQuality = {
  Low = 0,
  Middle = 1,
  High = 2
}
ShaderQuality = {
  Low = 0,
  Middle = 1,
  High = 2
}
AntiAliasingQuality = {
  Low = 0,
  Middle = 1,
  High = 2,
  SuperHigh = 3
}
BlendWeights = {
  OneBone = 1,
  TwoBones = 2,
  FourBones = 4
}
ShadowQuality = {
  Disable = 0,
  HardOnly = 1,
  All = 2
}
FpsQuality = {Low = 0, High = 1}
EStageType = {
  eStageLogin = 1,
  eStageMain = 2,
  eStageSimpleBattle = 3,
  eStagePvpBattle = 4,
  eStageLaunch = 5,
  eStageReplayBattle = 7,
  eStageResumeBattle = 8
}
AttrType = {
  HP = 1,
  ATTACK = 8,
  DEFENSE = 9,
  TORPEDO_ATTACK = 10,
  TORPEDO_DEFENSE = 11,
  TO_AIR_ATTACK = 12,
  TO_TORPEDO_ATTACK = 13,
  SHIP_BOMB_ATTACK = 14,
  SHIP_TORPEDO_ATTACK = 15,
  SHIP_AIR_CONTROL = 16,
  CRIT = 17,
  ANTICRIT = 18,
  HIT = 19,
  DODGE = 20,
  GUN_RANGE = 21,
  FATE = 22,
  VIEW_RANGE = 23,
  MAIN_GUN_CD = 24,
  TORPEDO_NUM = 25,
  SPEED = 27,
  CARRY = 37,
  TORPEDO_RANGE = 39,
  PLANE_BOMB = 43,
  PLANE_TORPEDO = 44,
  PLANE_RANGE = 47,
  SPARE_PLANE = 62,
  PLANE_CD = 63,
  FIGHTPLANE = 88,
  TORPEDOPLANE = 89,
  BOMBPLANE = 90,
  SUPPLE_COST = 3100,
  ATTACK_GRADE = 3101
}
BreakAttr = {
  AttrType.HP,
  AttrType.ATTACK,
  AttrType.DEFENSE,
  AttrType.TORPEDO_ATTACK,
  AttrType.TORPEDO_DEFENSE,
  AttrType.TO_AIR_ATTACK,
  AttrType.SHIP_BOMB_ATTACK,
  AttrType.SHIP_TORPEDO_ATTACK,
  AttrType.SHIP_AIR_CONTROL
}
EquipSortType = {
  Rarity = 1,
  Intensify = 2,
  Star = 3
}
HeroSortType = {
  Rarity = 1,
  Lvl = 2,
  Property = 3,
  CreateTime = 4,
  Lock = 5,
  SpecialShip = 6,
  TemplateId = 7,
  Fleet = 8,
  Advance = 9,
  Recommend = 10,
  SpecialShipType = 11,
  AttackGrade = 12,
  Count = 13,
  Mood = 14,
  BuildingEffect = 15,
  Status = 16,
  BuildingSelect = 17,
  BuildingCharacter = 18,
  RecipeType = 19,
  BuildingDorm = 20,
  BuildingHeroMood = 21,
  IllustrateEquip = 22,
  FASHION_Own = 101,
  BathFleet = 999
}
BuildingSortKey = {BuildingList = "BLP", BuildingHero = "BHS"}
HeroFilterType = {
  Index = 1,
  Camp = 2,
  Rarity = 3,
  Lock = 4,
  Recommend = 5,
  Building = 6,
  EquipType = 7,
  EquipIndex = 8,
  Count = 8
}
HeroIndexType = {
  Destroyer = 1,
  LightCruiser = 2,
  HeavyCruiser = 3,
  Battlecruiser = 4,
  Battleship = 5,
  HeavyAircraftCarrier = 6,
  Count = 6
}
HeroBuildingIndexType = {
  NotSet = 1,
  Office = 2,
  ElectricFactory = 3,
  OilFactory = 4,
  ResourceFactory = 5,
  DormRoom = 6,
  FoodFactory = 7,
  ModifyMat = 8,
  WishStone = 9,
  SodaWater = 10,
  EquipPart = 11,
  SkillBook = 12,
  BuildingMat = 13
}
HeroCampType = {
  America = 1,
  Japan = 2,
  England = 3,
  Germany = 4,
  Franch = 5,
  Italian = 6,
  Turkish = 7,
  USSR = 8,
  China = 9,
  Count = 10
}
HeroRarityType = {
  N = 1,
  R = 2,
  SR = 3,
  SSR = 4,
  UR = 5,
  Count = 6
}
HeroHpState = {
  NONE = 0,
  XiaoPo = 1,
  ZhongPo = 2,
  DaPo = 3,
  JiChen = 4,
  Count = 5
}
ShipTypeNameMap = {
  [HeroIndexType.Destroyer] = "\233\169\177\233\128\144",
  [HeroIndexType.LightCruiser] = "\232\189\187\229\183\161",
  [HeroIndexType.HeavyCruiser] = "\233\135\141\229\183\161",
  [HeroIndexType.Battlecruiser] = "\230\136\152\229\183\161",
  [HeroIndexType.Battleship] = "\230\136\152\229\136\151",
  [HeroIndexType.HeavyAircraftCarrier] = "\232\136\170\230\175\141"
}
GoodsType = {
  ITEM = 1,
  EQUIP = 2,
  SHIP = 3,
  DROP = 4,
  CURRENCY = 5,
  EQUIP_ENHANCE_ITEM = 6,
  TALENT_UPGRADE_ITEM = 7,
  ITEM_SELECTED = 8,
  BATH = 9,
  COMMAND = 10,
  WISH = 11,
  Fragment = 12,
  GIFT = 13,
  EXPAND_ITEM = 14,
  REWARD_SHIPLEVELUP_ITEM = 15,
  MEDAL = 16,
  CARD = 17,
  FASHION = 18,
  RECHARGE = 19,
  VALENTINE_GIFT = 23,
  DISCOUNT = 22,
  PLAYER_HEAD_FRAME = 24,
  INTERACTION_BAG_ITEM = 25
}
CurrencyType = {
  GOLD = 1,
  DIAMOND = 2,
  BULLET = 3,
  GAS = 4,
  SUPPLY = 5,
  ShipExp = 6,
  UserExp = 7,
  MAINGUN = 8,
  TORPEDO = 9,
  PLANE = 10,
  OTHER = 11,
  RETIRE = 12,
  SPA = 13,
  STRATEGY = 14,
  MEDAL = 15,
  RMB = 16,
  MERITS = 17,
  TOWER = 18,
  ELECTRIC = 19,
  FOOD = 20,
  STRENGTH = 21,
  EXERCISES = 22,
  FASHION = 23,
  CONTRIBUTE = 24,
  LUCKY = 25,
  TEACHINGMERITS = 26,
  TEACHINGPOP = 27,
  BATTLEPASSEXP = 28,
  BATTLEPASSGOLD = 29
}
NewHpStatusImg = {
  "uipic_ui_newfleetpage_im_xuetiao_lv",
  "uipic_ui_newfleetpage_im_xuetiao_lv",
  "uipic_ui_newfleetpage_im_xuetiao_huang",
  "uipic_ui_newfleetpage_im_xuetiao_hong",
  "uipic_ui_newfleetpage_im_xuetiao_hong"
}
NewCardHpStatus = {
  "uipic_ui_card_im_xuetiao_lv",
  "uipic_ui_card_im_xuetiao_lv",
  "uipic_ui_card_im_xuetiao_huang",
  "uipic_ui_card_im_xuetiao_hong",
  "uipic_ui_card_im_xuetiao_hong"
}
UI3DModelType = {Common = 1}
DamageLevel = {
  NonDamage = 0,
  SmallDamage = 1,
  MiddleDamage = 2,
  BigDamage = 3,
  Sinking = 4
}
GirlQualityBgTexture = {
  "uipic_ui_common_bg_baisepinzhi",
  "uipic_ui_common_bg_lansepinzhi",
  "uipic_ui_common_bg_zisepinzhi",
  "uipic_ui_common_bg_jinsepinzhi",
  "uipic_ui_common_bg_caisepinzhi"
}
ShipQuality = {
  N = 1,
  R = 2,
  SR = 3,
  SSR = 4,
  UR = 5
}
ShipQualityColor = {
  [ShipQuality.N] = "8d8d8d",
  [ShipQuality.R] = "1e9bda",
  [ShipQuality.SR] = "995fee",
  [ShipQuality.SSR] = "ea8a00",
  [ShipQuality.UR] = "FF465C"
}
EquipQualityIcon = {
  "uipic_ui_newfleetpage_bg_tubiaodi_hui",
  "uipic_ui_newfleetpage_bg_tubiaodi_lan",
  "uipic_ui_newfleetpage_bg_tubiaodi_zi",
  "uipic_ui_newfleetpage_bg_tubiaodi_cheng",
  "uipic_ui_newfleetpage_bg_tubiaodi_cai"
}
QualityIcon = {
  "uipic_ui_attribute_bg_zhuangbeikuang_hui",
  "uipic_ui_attribute_bg_zhuangbeikuang_lan",
  "uipic_ui_attribute_bg_zhuangbeikuang_zi",
  "uipic_ui_attribute_bg_zhuangbeikuang_jin",
  "uipic_ui_common_bg_zhuangbeikuang_cai"
}
BuildingQualityIcon = {
  "uipic_ui_building_bg_n",
  "uipic_ui_building_bg_r",
  "uipic_ui_building_bg_sr",
  "uipic_ui_building_bg_ssr",
  "uipic_ui_newfleetpage_bg_caisebeijing_ur_xiao"
}
GirlEquipQualityBgTexture = {
  "uipic_ui_common_bg_baisepinzhi",
  "uipic_ui_common_bg_lansepinzhi",
  "uipic_ui_common_bg_zisepinzhi",
  "uipic_ui_common_bg_jinsepinzhi",
  "uipic_ui_common_bg_caisepinzhi"
}
FleetCardQualityImg = {
  "uipic_ui_newfleetpage_bg_fan_kabei_bai",
  "uipic_ui_newfleetpage_bg_fan_kabei_lan",
  "uipic_ui_newfleetpage_bg_fan_kabei_zi",
  "uipic_ui_newfleetpage_bg_fan_kabei_jin",
  "uipic_newfleetpage_bg_fan_kabei_cai",
  nil
}
FleetSmallCardQualityImg = {
  "uipic_ui_newfleetpage_bg_baisebeijing_n_xiao",
  "uipic_ui_newfleetpage_bg_lansebeijing_r_xiao",
  "uipic_ui_newfleetpage_bg_zisebeijing_sr_xiao",
  "uipic_ui_newfleetpage_bg_jinsebeijing_ssr_xiao",
  "uipic_ui_newfleetpage_bg_caisebeijing_ur_xiao",
  nil
}
FleetBottomCardQulity = {
  "uipic_ui_newfleetpage_bg_baisebeijing_n_xiao",
  "uipic_ui_newfleetpage_bg_lansebeijing_r_xiao",
  "uipic_ui_newfleetpage_bg_zisebeijing_sr_xiao",
  "uipic_ui_newfleetpage_bg_jinsebeijing_ssr_xiao",
  "uipic_ui_newfleetpage_bg_caisebeijing_ur_xiao",
  nil
}
FleetLevelDetsCardQulity = {
  "uipic_ui_newfleetpage_bg_fan_kabei_bai",
  "uipic_ui_newfleetpage_bg_fan_kabei_lan",
  "uipic_ui_newfleetpage_bg_fan_kabei_zi",
  "uipic_ui_newfleetpage_bg_fan_kabei_jin",
  "uipic_newfleetpage_bg_fan_kabei_cai",
  nil
}
HorizontalCardQulity = {
  "uipic_ui_newfleetpage_bg_baisebeijing_n_chang",
  "uipic_ui_newfleetpage_bg_lansebeijing_r_chang",
  "uipic_ui_newfleetpage_bg_zisebeijing_sr_chang",
  "uipic_ui_newfleetpage_bg_jinsebeijing_ssr_chang",
  "uipic_newfleetpage_bg_zisebeijing_ur_chang",
  nil
}
VerCardType = {
  Normal = 1,
  Fleet = 2,
  FleetSmall = 3,
  FleetBottom = 4,
  LevelDetails = 5
}
VerCardQualityImg = {
  "uipic_ui_girllist_bg_baisebeijing_n_da",
  "uipic_ui_girllist_bg_lansebeijing_r_da",
  "uipic_ui_girllist_bg_zisebeijing_sr_da",
  "uipic_ui_girllist_bg_jinsebeijing_ssr_da",
  "uipic_ui_girllist_bg_caisebeijing_ur_da",
  nil
}
UserHeadQualityImg = {
  "uipic_ui_common_bg_jianniangpinzhi_n",
  "uipic_ui_common_bg_jianniangpinzhi_r",
  "uipic_ui_common_bg_jianniangpinzhi_sr",
  "uipic_ui_common_bg_jianniangpinzhi_ssr",
  "uipic_ui_common_bg_jianniangpinzhi_ur"
}
NewCardShipTypeImg = {
  [1] = "uipic_ui_common_im_quzhu_da",
  [2] = "uipic_ui_common_im_qingxun_da",
  [3] = "uipic_ui_common_im_zhongxun_da",
  [4] = "uipic_ui_common_im_zhanlie_da",
  [5] = "uipic_ui_common_im_zhanlie_da",
  [6] = "uipic_ui_common_im_hangmu_da",
  [101] = "uipic_ui_common_im_gui",
  [102] = "uipic_ui_common_im_fu"
}
CardShipTypeImgMin = {
  [1] = "uipic_ui_common_im_quzhu",
  [2] = "uipic_ui_common_im_qingxun",
  [3] = "uipic_ui_common_im_zhongxun",
  [4] = "uipic_ui_common_im_zhanlie",
  [5] = "uipic_ui_common_im_zhanlie",
  [6] = "uipic_ui_common_im_hangmu",
  [101] = "uipic_ui_common_im_gui",
  [102] = "uipic_ui_common_im_fu"
}
CardFashionTypeImg = {
  [5] = "uipic_ui_fashion_bg_cai_da",
  [4] = "uipic_ui_fashion_bg_jin_da",
  [3] = "uipic_ui_fashion_bg_zi_da",
  [2] = "",
  [1] = ""
}
CardFashionNameImg = {
  [5] = "uipic_ui_fashion_bg_mingzidi_cai",
  [4] = "uipic_ui_fashion_bg_mingzidi_jin",
  [3] = "uipic_ui_fashion_bg_mingzidi_zi",
  [2] = "",
  [1] = ""
}
ShipBattleHpState = {
  [1] = "uipic_ui_newaccounts_fo_xiaopo",
  [2] = "uipic_ui_newaccounts_fo_zhongpo",
  [3] = "uipic_ui_newaccounts_fo_dapo",
  [4] = "uipic_ui_newaccounts_fo_jichen"
}
ETweenType = {
  ETT_POSITION = 1,
  ETT_ALPHA = 2,
  ETT_SCALE = 3,
  ETT_ROTATION = 4,
  ETT_NUMBER = 5,
  ETT_SIZEDELTA = 6
}
BagType = {
  ITEM_BAG = 1,
  EQUIP_BAG = 2,
  DECORATE_BAG = 3
}
BagItemType = {
  ITEM = 1,
  EQUIP = 2,
  SHIP = 3,
  DROP = 4,
  CURRENCY = 5,
  EQUIP_ENHANCE = 6,
  SHIP_TALENT_UPGRADE = 7
}
OrderRecord = {EQUIP_BAG = 1}
GameCameraType = {
  RoomSceneCamera = 1,
  BuildSceneCamera = 2,
  BathRoomSceneCamera = 3,
  MarrySceneCamera = 4,
  UI3DModel = 5,
  InfrastructureSceneCamera = 6,
  TowerSceneCamera = 7,
  OfficeSceneCamera = 8,
  ElectricFactorySceneCamera = 9,
  OilFactorySceneCamera = 10,
  ResourceFactorySceneCamera = 11,
  DormRoomSceneCamera = 12,
  FoodFactorySceneCamera = 13,
  ItemFactorySceneCamera = 14,
  MagazineSceneCamera = 15,
  MiniGameSceneCamera = 16,
  RemouldSceneCamera = 17,
  UI3DModelRemould = 18,
  MubarSceneCamera = 19,
  MultiPveSceneCamera = 20
}
HomeStateID = {
  NULL = 1,
  MAIN = 2,
  STUDY = 3,
  BUILD = 4,
  BATHROOM = 5,
  MARRY = 6,
  INFRASTRUCTURE = 7,
  TOWER = 8,
  MiniGame = 9,
  REMOULD = 10,
  MUBARCOPY = 11,
  MULTIPVEACT = 12
}
EquipToBagSign = {
  RISE_STAR = "RiseStar",
  CHANGE_EQUIP = "ChangeEquip",
  ADD_EQUIP = "AddEquip",
  DISMANTLE_EQUIP = "DismantleEquip"
}
CamDataType = {
  Settle = 1,
  Display = 2,
  Detaile = 3,
  Study = 4,
  Animoji = 5
}
CrusadeType = {Daily = 1, Limit = 2}
DockListType = {
  All = 1,
  OutSelf = 2,
  SameTid = 3,
  SameTidOutSelf = 4,
  SpecificType = 5
}
CrusadeStatus = {
  Todo = 0,
  Doing = 1,
  Finish = 2
}
CrusadeCompleteType = {
  Normal = 1,
  Quick = 2,
  Cancel = 3
}
ShopFuncType = {
  Normal = 1,
  Recharge = 2,
  Activity = 3,
  MonthCard = 5
}
ShopType = {
  Permanent = 1,
  LimitTime = 2,
  Period = 3
}
ShopPeriodParam = {
  SerialMonth = 1,
  NoSerialMonth = 2,
  SerialWeek = 3,
  NoSerialWeek = 4,
  SerialDay = 5,
  NoSerialDay = 6
}
ShopTimerType = {
  Open = 1,
  Close = 2,
  ReFresh = 3
}
ShopShelfType = {
  ShopShelf = 1,
  SupplyShelf = 2,
  Count = 3
}
HeroStatus = {Default = 0, Crusade = 1}
EnterCopySign = {
  Home = 1,
  Other = 2,
  Crusade = 3
}
LockGirlStatus = {
  [true] = "uipic_ui_handbook_bu_suoding",
  [false] = "uipic_ui_handbook_bu_jiesuo"
}
LockShip = {
  [true] = "uipic_ui_lock_bg_suodingdi_xiao"
}
LockTipInfo = {
  [true] = "<color=#%s>%s</color>\233\148\129\229\174\154\230\136\144\229\138\159",
  [false] = "<color=#%s>%s</color>\229\143\150\230\182\136\233\148\129\229\174\154"
}
ChatWay = {TextInput = 1, VoiceInput = 2}
ChatChannel = {
  Guild = 101,
  Friend = 102,
  Personal = 103,
  System = 104,
  Team = 105,
  WorldBase = 900
}
ChatChannelStr = {
  [ChatChannel.WorldBase] = "\228\184\150\231\149\140",
  [ChatChannel.Guild] = "\229\164\167\232\136\176\233\152\159",
  [ChatChannel.Friend] = "\229\165\189\229\143\139",
  [ChatChannel.Personal] = "\229\175\134\232\129\138",
  [ChatChannel.System] = "\231\179\187\231\187\159",
  [ChatChannel.Team] = "\233\152\159\228\188\141"
}
ChatChannelStrMap = {
  [ChatChannel.WorldBase] = "WorldMsg",
  [ChatChannel.Guild] = "GuildMsg",
  [ChatChannel.Team] = "TeamMsg",
  [ChatChannel.System] = "SysMsg"
}
ChatEmojiTags = {Recent = 0, Default = 1}
EmojiTag = {
  [ChatEmojiTags.Recent] = 0,
  [ChatEmojiTags.Default] = 1
}
FriendStatus = {
  NORMAL = 1,
  APPLY = 2,
  FRIEND = 3,
  BLACK = 4,
  APPLYREC = 5
}
FriendList = {
  Friend = 1,
  Add = 2,
  Apply = 3,
  BlackList = 4,
  Teaching = 5
}
UserStatusType = {Online = 1, Offline = 2}
BagSortSign = {
  ForBag = 1,
  ForDismantle = 2,
  ForChangeEquip = 3
}
ShopId = {
  Normal = 1,
  Spa = 2,
  Diamond = 3,
  Retire = 4,
  Equip = 5,
  MainGun = 6,
  Torpedo = 7,
  Days = 8,
  Gift = 9,
  Recharge = 12,
  DailyCopy = 13,
  Recommand = 1001,
  Fashion = 23,
  Tower = 24,
  DiamondRecharge = 1201,
  LuckyRecharge = 1202,
  TeachingShop = 28
}
BuyResource = {Supply = 1, Gold = 2}
BuyStatus = {NoBuy = 0, HaveBuy = 1}
SwitchType = {WhiteType = 1, BlackType = 2}
PlatformDotType = {
  behavior = "behavior",
  secretary = "secretary",
  uilog = "ui_log",
  service = "service",
  clickLog = "click_log",
  getLog = "get_log",
  newPlayer = "newplayer",
  setting = "setting",
  vow = "vow",
  battlelog = "battle",
  supportfleet = "supportfleet",
  bathing = "bathing",
  recharge = "recharge",
  equipGetLog = "equip_get_log",
  sceneLog = "scene_log",
  fashionGetLog = "fashion_get_log",
  copyMaxLog = "copy_max"
}
TalentType = {
  ALL = 0,
  ATTACK = 1,
  DEFEND = 2,
  ASSIST = 3
}
OperateModeType = {RUDDER = 0, DIRECT = 1}
OperateMode = {
  [0] = OperateModeType.RUDDER,
  [1] = OperateModeType.DIRECT
}
BattleGameSpeedIndex = {
  ONE = 0,
  TWO = 1,
  THR = 2
}
SpeedModeIndex = {
  [0] = 1,
  [1] = 0
}
SpeedIndexMode = {
  [0] = 1,
  [1] = 0
}
AnimColliderType = {
  None = -1,
  ChestCollider = 0,
  BodyCollder = 1
}
UILayer = {
  SCENE = 0,
  MAIN = 1,
  GUIDER = 2,
  ATTENTION = 3,
  NETWORK = 4,
  PLATFORM = 5,
  UI = 6,
  ADAPTIVE = 7
}
UILayerStr = {
  Scene = UILayer.SCENE,
  Default = UILayer.MAIN,
  Guider = UILayer.GUIDER,
  Attention = UILayer.ATTENTION,
  Network = UILayer.NETWORK,
  Platform = UILayer.PLATFORM,
  UI = UILayer.UI,
  Adaptive = UILayer.ADAPTIVE
}
ExecutorState = {
  Wait = 1,
  Running = 2,
  End = 3
}
CommonHeroItem = {
  Fleet = 1,
  Repaire = 2,
  Wish = 3,
  BathRoom = 4,
  Goods = 5,
  Break = 6,
  Strengthen = 7,
  Study = 8,
  ChangeSecretaryFleet = 9,
  Assist = 10,
  Picture = 11,
  Building = 12,
  TowerFleet = 13,
  PresetFleet = 14,
  BuildingList = 15,
  ShipTask = 16,
  ShopFashion = 17,
  EquipPicture = 18,
  Magazine = 19,
  ShopBrokenFashion = 20,
  RemouldPic = 21,
  MubarOurpost = 22
}
ModuleStatus = {
  OpenF = 0,
  No_OpenF = 1,
  OpenQ = 2,
  No_OpenQ = 3
}
CameraSwitchType = {
  HomeToPage = 1,
  PageToHome = 2,
  HomeToAnim = 3,
  AnimToHome = 4
}
TaskType = {
  All = 0,
  Main = 1,
  Daily = 2,
  Week = 3,
  Grow = 4,
  Achieve = 5,
  Activity = 6,
  Guild = 7,
  TeachingDaily = 8,
  TeachingStage = 9,
  TreatyTask = 10,
  Magazine = 11,
  Return = 12
}
TaskCountType = {TOTAL_COUNT = 1, SELF_COUNT = 2}
TaskAllRewardType = {TASK_LIST = 1, TASK_ACHIEVE = 2}
TaskType.TaskBegin = TaskType.Main
TaskType.TaskEnd = TaskType.Grow
TaskState = {
  FINISH = 1,
  TODO = 2,
  RECEIVED = 3
}
TaskShowModule = {Task = 0, Achieve = 1}
TaskKind = {
  LOGIN = 1,
  BATTLEWIN = 2,
  PASSDAILYCOPY = 3,
  PASSELITECOPY = 4,
  PASSCHALLENGECOPY = 5,
  FINISHCRUSADE = 6,
  SUPPORTFLEET = 7,
  EXERCISE = 8,
  SKILL = 9,
  STRENGTH = 10,
  RETIRE = 11,
  BUILD = 12,
  REPAIR = 13,
  FININSHALLDAILY = 14,
  HITSHIP = 15,
  PASSCOPY = 16,
  FULLPASSCOPY = 17,
  FINISHWEEK = 18,
  USERLEVEL = 25,
  ACTIVITYPLOT = 27,
  FRIENDCOUNT = 35,
  SKILLLEVEL = 200,
  BUILDCOUNT = 500,
  CUMURECHARGE = 702,
  PASSTRAIN = 800,
  ARBATTLEWIN = 811,
  PASSRUNFIGHT = 900,
  PASSSEACOPY = 1700,
  TOWER_ACTIVITY = 1703,
  PASSADAILYCOPY = 2500,
  GETEQUIPTEMPLATE = 2701,
  GETHEROTEMPLATE = 2702,
  HEROLVTEMPLATE = 2703,
  HEROADTEMPLATE = 2704,
  EQUIPLVTEMPLATE = 2705,
  EQUIPADTEMPLATE = 2706,
  BUILDSHIPQUICK = 2716,
  BUILDTYPE = 2720,
  GETITEMTEMPLATE = 3111,
  POWERMAXCHG = 3200,
  POWERMINCHG = 3201,
  BUILDOFFICELV = 3104,
  PASSTOWER = 6005,
  TaskShipPassCopy = 12001,
  TaskShipAffection = 12002,
  TaskShipPassCopyMvp = 12003,
  TaskShipEquip = 12004,
  TaskShipStartCopy = 12005,
  TaskShipIllustrate = 12006,
  TaskShipClick = 12007,
  TaskShipGift = 12008,
  TaskMagazineShipPassCopy = 12009,
  TaskMagazineShipStar = 12010,
  TaskMagazineShipAffection = 12011,
  TaskMagazineShipLevel = 12012,
  TaskShipSkill = 12013,
  TaskEventMiniGameScoreCopy = 17003,
  TaskEventMiniGameScore = 17004,
  TaskRemouldQualityStage = 18002,
  TaskRemouldSfIdStageEffect = 18003,
  TaskRemouldSfIdStage = 18004
}
BigActivityType = {
  ZHAOMU = 12,
  SEACOPY = 1700,
  PLOTCOPY = 27
}
ActivityPageShowType = {
  Normal = 0,
  School = 1,
  NationalDay = 2
}
SceneType = {
  HOME = 1,
  BATHROOM = 2,
  BUILD = 3,
  LOGIN = 4,
  MARRY = 5,
  RESTAURANTE = 6,
  TOWER = 7,
  Office = 8,
  ElectricFactory = 9,
  OilFactory = 10,
  ResourceFactory = 11,
  DormRoom = 12,
  FoodFactory = 13,
  ItemFactory = 14,
  MiniGame = 15,
  Remould = 16,
  Mubar = 17,
  MultiPveAct = 18
}
IllustrateState = {
  UNLOCK = 1,
  LOCK = 2,
  CLOSE = 3
}
IllustrateShow = {
  CLOSE = -1,
  NOOPEN = 0,
  OPEN = 1,
  TIMEAFTER = 2
}
GetSupplyStatus = {
  CANGET = 1,
  NOTINTIME = 2,
  RECEIVED = 3
}
MHeroSortType = {
  Default = 1,
  BathSelect = 2,
  Picture = 3,
  Building = 4,
  BuildingList = 5,
  ShopFashion = 6,
  Equip = 7
}
PlotTriggerType = {
  copy_start_before_cg = 1,
  copy_start_after_cg = 2,
  discovery_fleet = 3,
  fleetbattle_before_cg = 4,
  fleetbattle_after_cg = 5,
  fleetenemy_blood = 6,
  fleetbattle_before_count = 7,
  fleetbattle_after_count = 8,
  copy_end_count = 9,
  plot_episode_reward = 10,
  receive_task = 11,
  complete_task = 12,
  newplayer_guide = 13,
  plot_episode_branch = 14,
  plot_copy_display_trigger = 15,
  marriage_before = 16,
  marriage_after = 17,
  character_story = 18,
  mini_game_2d_start = 19,
  mini_game_2d_fail = 20,
  mini_game_2d_success = 21
}
AssistFleetState = {
  TODO = 0,
  DOING = 1,
  FINISH = 2
}
AssistTag = {
  DOING = 0,
  MAINLINE = 1,
  ELITE = 2,
  ACTIVITY = 3
}
AssistCompleteType = {
  NORMAL = 1,
  FAST = 2,
  CANCEL = 3
}
CopyType = {
  COMMONCOPY = 1,
  DAILYCOPY = 2,
  ACTIVITYCOPY = 3,
  BOSS = 4
}
SpSkillType = {REDUCEREPAIRE = 11061, ADDOTHEREXP = 10152}
TopPageType = {
  Home = 0,
  General = 1,
  Copy = 2,
  User = 3,
  Animoji = 5
}
ChapterType = {
  PlotCopy = 1,
  SeaCopy = 2,
  Train = 3,
  TrainAdvance = 4,
  TrainLv = 5,
  ActPlotCopy = 6,
  ActSeaCopy = 7,
  AR = 8,
  DailyCopy = 9,
  GoodsCopy = 10,
  ActPlotCopyEx = 11,
  ActSeaCopyEx = 12,
  Tower = 13,
  WalkDog = 15,
  AdventurePlot = 16,
  AdventureCopy = 17,
  HalloweenPlot = 18,
  EquipTestCopy = 19,
  ActivitySecretCopy = 22,
  TowerActivity = 24,
  Teach = 25,
  PVE = 101,
  BossCopy = 30,
  MubarCopy = 33,
  EquipNewTestCopy = 34,
  MultiPersonPlotCopy = 37
}
PlotType = {
  ChapterDes = 1,
  NormalDialog = 2,
  NobodyDialog = 3,
  Video = 4
}
PlotSkipType = {
  None = 0,
  Current = 1,
  CurrentUnread = 2,
  All = 3
}
WeekStr = {
  "\228\184\128",
  "\228\186\140",
  "\228\184\137",
  "\229\155\155",
  "\228\186\148",
  "\229\133\173",
  "\230\151\165"
}
SupportResult = {
  Failure = 0,
  Success = 1,
  SuperSuccess = 2
}
GetGirlWay = {
  build = "build_get",
  battle = "battle_get",
  vow = "vow_get",
  girl = "formulabuild_get",
  plot = "plot_get",
  reward = "task_reward"
}
FPSCheckParam = {
  name = "FirstBattleFPS",
  interval = 0.5,
  lowLevel = 10,
  lowFPSCount = 20,
  average = 24
}
WishCoolState = {OPEN = 1, COOL = 2}
CheckType = {Picture = 1, GirlInfo = 2}
LockStatus = {
  [true] = "uipic_ui_handbook_bu_suoding_wudi",
  [false] = "uipic_ui_handbook_bu_jiesuo_wudi"
}
KickType = {
  ErrorKickByUser = 104,
  ErrorKickByWeb = 105,
  ErrorRegMax = 106
}
TalentColor = {
  [TalentType.ALL] = "eca12b",
  [TalentType.ATTACK] = "eca12b",
  [TalentType.DEFEND] = "417ae3",
  [TalentType.ASSIST] = "2bcd3a"
}
RedDotType = {Normal = 0, Number = 1}
REDDOT_PARAM_TYPE = {
  None = 0,
  Programmer = 1,
  Planer = 2
}
ChatSaveScene = {AppPause = 0, AppClose = 1}
ResolutionType = {
  NORMAL = 0,
  WIDE = 1,
  NARROW = 2
}
RechargeItemType = {
  DirPay = 0,
  MonthCard = 1,
  WeekCard = 2,
  Subscribe = 3,
  Item = 4,
  SpacingItem = 5,
  ShopGoods = 6,
  Lucky = 7,
  LuckyBuy = 8,
  BigMonthCard = 9,
  LuckyRecharge = 10
}
BuildShipGirl = {
  Build = 0,
  Quene = 1,
  Notes = 2
}
BuildShipResource = {
  Gold = 1,
  Gang = 2,
  Lv = 3
}
SmallGirlQuality = {
  [1] = "uipic_ui_store_bg_touxiang_diban_bai",
  [2] = "uipic_ui_store_bg_touxiang_diban_lan",
  [3] = "uipic_ui_store_bg_touxiang_diban_zi",
  [4] = "uipic_ui_store_bg_touxiang_diban_jin"
}
MailRewardStatus = {
  GetAward = 0,
  BagFull = 1,
  NotAward = 2
}
Fleet = {Max = 4}
ShareType = {
  WeiXin = 0,
  WeiBo = 1,
  QQFriend = 2,
  QQZone = 3
}
RewardState = {
  Receivable = 1,
  UnReceivable = 2,
  Received = 3
}
HeroTypeContent = {
  [HeroIndexType.Destroyer] = "\233\169\177\233\128\144\232\136\176",
  [HeroIndexType.LightCruiser] = "\232\189\187\229\183\161\230\180\139\232\136\176",
  [HeroIndexType.HeavyCruiser] = "\233\135\141\229\183\161\230\180\139\232\136\176",
  [HeroIndexType.Battlecruiser] = "\230\136\152\229\136\151\229\183\161\230\180\139\232\136\176",
  [HeroIndexType.Battleship] = "\230\136\152\229\136\151\232\136\176",
  [HeroIndexType.HeavyAircraftCarrier] = "\232\136\170\231\169\186\230\175\141\232\136\176"
}
CopyDisplayType = {NormalCopy = 1, ActivityCopy = 2}
Activity = {
  Sign = 1,
  Supply = 2,
  Gift = 3,
  NewPlayer = 4,
  FirstRecharge = 10,
  DailyLogin_14 = 11,
  DailyLogin_xiamo = 24,
  DailyLogin_school = 25,
  Adventure_task = 1506,
  CumuCost = 701,
  CumuRecharge = 702,
  SingleRecharge = 703,
  ActivitySSR = 25,
  NewYearSign = 64,
  SpecialChristmasFashion = 65,
  SpringFestivalSign = 73,
  NewYearPlot = 76,
  NewYearFashionPlan = 77,
  ValentinePackage = 83,
  ReturnPlayer = 104
}
ActivityType = {
  Sign = 1,
  Supply = 2,
  Gift = 3,
  NewPlayer = 4,
  Festival = 5,
  Extra = 6,
  CumuCost = 7,
  DailyLogin = 8,
  FirstRecharge = 10,
  TimeLimitBuild = 12,
  NFestival = 13,
  CumuRecharge = 14,
  SingleRecharge = 15,
  HolidayReward = 16,
  SchoolActivity = 17,
  SchoolAccumu = 18,
  SchoolSign = 19,
  WishUp = 24,
  ActivitySSR = 25,
  HalloweenStory = 27,
  AEquip = 28,
  BigActivity = 29,
  TestShip = 30,
  EquipTest = 31,
  ActivitySecretCopy = 32,
  NewYearSign = 35,
  FurnitureDecoration = 34,
  SpecialChristmasFashion = 36,
  NewYearActivity = 41,
  BattlePass = 46,
  ReturnPlayer = 92,
  BirthdayCake = 103,
  ActivitySearchGoods = 112,
  ActivityValentineGift = 45,
  JChildSign = 81003,
  Boss = 9001,
  ActMiniGame = 81025,
  JCodeExchange = 81005
}
MeritType = {Grade = 0, Rank = 1}
EquipBaseType = {PLANE = 1}
EquipType = {
  FIGHTPLANE = 18,
  BOMBPLANE = 19,
  TORPEDOPLANE = 20
}
BigActivity = {
  Rank = 1,
  Other = 2,
  BigActSea = 3,
  BigActPlot = 4
}
SendUserInfoType = {
  CreateUser = "0",
  EnterHome = "1",
  LevelUp = "2"
}
NewPlayerType = {
  Null = -1,
  Fleet = 1,
  BuildShip = 2,
  Repaire = 4,
  Dock = 5,
  Bag = 6,
  Copy = 7,
  Shop = 8,
  Study = 9,
  Task = 10,
  BathRoom = 11,
  Email = 13,
  Friend = 14,
  Chat = 16,
  Activity = 17,
  Crusade = 18,
  Survey = 19,
  AutoFIght = 20,
  PlotCopy = 21,
  SeaCopy = 22,
  SupportFleet = 23,
  DailyCopy = 24,
  DoubleSpeed = 25,
  TripleSpeed = 26,
  Retire = 29,
  BuildShipGirl = 31,
  Train = 32,
  Strategy = 34,
  TrainLv = 35,
  ActPlotCopy = 36,
  ActSeaCopy = 37,
  Recharge = 38
}
HeroBreakEffect = {
  MAIN_GUN_SUB_4 = 101,
  MIAN_GUN_SUB_5 = 102,
  ADD_TORPEDO_1 = 103
}
LeftOpenInde = {
  Fleet = 1,
  Build = 2,
  BuildShip = 3,
  Repaire = 4
}
RewardType = {
  COMMON = 1,
  MONTHCARD = 2,
  FIRSTPASS = 3,
  TOWER = 4,
  TEXT = 5,
  EXTRA_SHIP = 6,
  BIGMONTHCARD = 7,
  GUILD_CONST_REWARD = 8,
  GUILD_RAND_REWARD = 9,
  REDAUCKLAND_CHANGE_REWARD = 10
}
SortResult = {
  Equal = 0,
  Less = 1,
  Greater = 2
}
NotesType = {
  All = 1,
  SSR = 2,
  SR = 3,
  R = 4
}
Mode = {Play = 1, LuZhi = 2}
AnimojiType = {
  NoRecord = 1,
  RecordIng = 2,
  Recorded = 3
}
ChangeType = {CanChange = 1, NoChange = 2}
ErrorCode = {
  ErrNoUsr = -1015,
  ErrHeroBagExpandMax = 1530,
  ErrSelfUsr = 2005,
  ErrChatMask = 2106,
  ErrChatRepeat = 2108,
  ErrTaskNotComplete = 2504,
  ErrHadTeacher = 3902,
  ErrTeachApplyFull = 3904,
  ErrApplyFull = 3905,
  ErrStudentFull = 3907,
  ErrStudentMonthFull = 3910,
  ErrTeachInPunish = 3915,
  ErrTeachMeInPunish = 3918,
  ErrStudentFinish = 3919,
  ErrTeachGraduate = 3920,
  ErrActSSRTime = 4001,
  ErrChangeGirl = 4002,
  ErrNoTimes = 4003,
  ErrFunNotOpen = 3922,
  ErrAgreeInPunishTime = 3921,
  ErrSearchName = 1005,
  ErrActivityFashionPeriod = 19121301,
  ErrActivityFashionLimit = 19121302,
  ErrActivityFashionSpecial = 19121303,
  ErrPackageSelectiveNoReward = 3300,
  ErrPackageSelectiveBuyMax = 3301
}
AchieveType = {
  Favorites = 1,
  Develop = 2,
  Expedition = 3,
  Other = 4,
  FirstRecharge = 12
}
GlobalAchieveId = {FirstRecharge = 2000}
SelectRandItem = {
  RandShip = 1,
  RandEquip = 2,
  RandItem = 3,
  RandFashion = 4
}
ChatMsgType = {
  TEXT = 0,
  VOICE = 1,
  EMOJI = 2
}
SettlementPSkillPlayType = {SAMETIME = 0}
SettlementComp = {MY = 0, ENEMY = 1}
SettlementItemType = {HERO = 1, DETIAL = 2}
VoiceBackType = {
  OnInitVoiceSDK = 0,
  OnStartRecord = 1,
  OnStopRecord = 2,
  OnCancelRecord = 3,
  OnDownloadFile = 4,
  OnPlayComplete = 5,
  OnStopPlay = 6
}
MChatVoiceCommonState = {
  NO = 0,
  WAIT = 1,
  YES = 2
}
RechargeTogType = {
  recharge = 1,
  gift = 2,
  luckybag = 3,
  count = 4
}
BarrageType = {Train = 1, Plot = 2}
SetConditionEnum = {
  SkipMySkillAnim = 44,
  SkipEnemySkillAnim = 45,
  SkipShipSkillFeedBack = 46,
  CopyAutoAttack = 47
}
IsShowAnim = {
  [true] = 0,
  [false] = 1
}
Evaluate = {
  BATTLE_FOUND_COUNT = 2001,
  BATTLE_REST_TIME = 2002,
  BATTLE_BOSS_TIME = 2003,
  BATTLE_RUN_TIME = 2004
}
AnimojiEnter = {CanEnter = true, NoCanEnter = false}
VoiceWay = {VOICE = 0, VOICE2TEXT = 1}
ChatKind = {PLC = 0, PSN = 1}
ChatRecordSlideState = {
  NONE = 0,
  UP = 1,
  DOWN = 2
}
UserSettingsKey = {
  PlotPassKey = "PlotPassKey",
  PlotToggleSkipTipKey = "PlotToggleSkipTip",
  PlotUtcTimeKey = "PlotUtcTime"
}
MarryType = {
  Love = 1,
  Mood = 2,
  Kuang = 3
}
AnnouncementType = {Base = 1, Maintenance = 2}
MarryProcess = {Before = 1, After = 2}
ChangeNameType = {
  GirlInfo = 1,
  Marry = 2,
  User = 3,
  PresetFleet = 4,
  BuildingPreset = 5
}
AttrTypeNew = {
  Common = 1,
  Gun = 2,
  Torpedo = 3,
  Plane = 4
}
MarryAffterType = {GirlInfo = 1, MarryProcess = 2}
CommonRiseEquipTag = 129
GirlType = {
  None = -1,
  Home = 0,
  MVP = 1,
  Battle = 2,
  Marry = 3
}
SelectMarryRing = {RingOne = 1, RingSecond = 2}
COLOR = {DropOpen = 100, DropLock = 101}
BathEndType = {
  Finish = 1,
  Replace = 2,
  AllBath = 3
}
ShowEquipType = {
  InfoBag = 1,
  Info = 2,
  Simple = 3,
  Shop = 4
}
EquipIndex = {Min = 1, Max = 6}
ShipWishState = {
  ALLNO = 0,
  ALLYES = 1,
  CONDITION = 2
}
QRCodeType = {RightDown = 1, LeftDown = 2}
SafeEffectType = {
  Buff = 1,
  Func = 2,
  Copy = 3,
  Enemy = 4,
  Kill = 5,
  Attr = 6
}
BuildShipPageId = {Equip = 201, NewPlayer = 1}
WishUseItemWay = {
  CLICK = 1,
  PRESS = 2,
  AUTO = 3
}
RecommandGoodsType = {Recharge = 1, ShopGoods = 2}
GuideCacheDataKey = {
  FleetPageCanDrag = 1,
  HomePageHideBtnShow = 2,
  SeacopyCurChapterId = 3
}
CopyScoreImage = {
  "",
  "uipic_ui_newaccounts_fo_jiesuan_ss",
  "uipic_ui_newaccounts_fo_jiesuan_s",
  "uipic_ui_newaccounts_fo_jiesuan_a",
  "uipic_ui_newaccounts_fo_jiesuan_b",
  "uipic_ui_newaccounts_fo_jiesuan_c",
  "uipic_ui_newaccounts_fo_jiesuan_d",
  "uipic_ui_newaccounts_fo_jiesuan_e",
  "uipic_ui_newaccounts_fo_jiesuan_f"
}
MBuildingType = {
  Office = 1,
  ElectricFactory = 2,
  OilFactory = 3,
  ResourceFactory = 4,
  DormRoom = 5,
  FoodFactory = 6,
  ItemFactory = 7,
  BathRoom = 8
}
MBuildingTipType = {LevelUp = 0, LevelDown = 1}
BuildingStatus = {
  Idle = 1,
  Adding = 2,
  Working = 3,
  Upgrading = 4,
  Receiving = 5,
  Waiting = 6
}
MEquipState = {OPEN = 0, LOCK = 1}
FleetType = {
  Normal = 1,
  Tower = 2,
  LimitTower = 3,
  Preset = 999
}
HeroEffect = {
  FoodCost = "GetFoodCostStr",
  MoodCost = "GetMoodCostStr",
  Productivity = "GetProductivityStr",
  Character = "GetCharacterStr",
  ItemProduceSpeedAdd = "GetItemProduceSpeedAddStr",
  CoinProduceSpeedAdd = "GetCoinProduceSpeedAddStr"
}
BuildingEffect = {
  ProduceSpeed = "GetProduceSpeedStr",
  MaxAdd = "GetMaxAddStr",
  ProductCount = "GetProductCountStr",
  ElectricCost = "GetElectricCostStr",
  WorkerRecover = "GetWorkerRecoverStr",
  MoodRecover = "GetMoodRecoverStr",
  MaxStrengthAdd = "GetMaxStrengthAddStr"
}
LevelEffect = {
  ProduceSpeed = "productivity",
  ProductMax = "productmax",
  ElectricCost = "powercost",
  Level = "level",
  HeroCount = "heronumber",
  WorkerRecover = "addworkerhp",
  MoodRecover = "addmood",
  ProduceReduceTime = "productiontimeless",
  MaxStrength = "GetMaxStrengthAddStr"
}
ExtractType = {
  EQUIP = 1,
  SHIP = 2,
  FASHION = 3,
  LIMIT_SHIP = 4
}
BattleMode = {
  Normal = 1,
  Exercises = 2,
  Memory = 3,
  Sweep = 4,
  Match = 5
}
AllLBPoint = 10000
ShowGirlType = {Girl = 1, Fashion = 2}
GAME_OS = {
  android = 1,
  ios = 2,
  all = 3
}
BuildingBase = {
  Int = 10000,
  Float = 1.0E-4,
  Percent = 0.01
}
AnnouncementPushType = {
  FirstLogin = 1,
  EveryLogin = 2,
  NoAuto = 3,
  TimeAuto = 4
}
InnerBrowseType = {
  NormalAnnounce = 0,
  ActivityPage = 1,
  MobielPhone = 2,
  Question = 3
}
FashionQualityImg = {
  "uipic_ui_fashion_bg_n",
  "uipic_ui_fashion_bg_r",
  "uipic_ui_fashion_bg_sr",
  "uipic_ui_fashion_bg_ssr",
  "uipic_ui_fashion_bg_ur"
}
SettingDict = {
  SkipMySkillAnim = 1,
  SkipEnemySkillAnim = 2,
  SkipOtherAnim = 3,
  SkipEnemyTorpedoAnim = 4
}
BuildingTimeUnit = 600
ActEnter = {Normal = 1, Memory = 2}
LocalNotificationInterval = {
  NoRepeat = 0,
  Century = 1,
  Year = 2,
  Month = 3,
  Day = 4,
  Hour = 5,
  Minute = 6,
  Second = 7,
  Week = 8
}
ETeachingState = {
  NONE = 0,
  TEACHER = 1,
  STUDENT = 2
}
ETeachingIntroGroupId = {
  SEX = 1,
  TIME = 2,
  ATTR = 3
}
TeachingIndex = {
  Mine = 0,
  Task = 1,
  Apply = 2,
  Find = 3,
  Rank = 4
}
ZoneType = {AR = 1, PVE = 2}
SelectImg = {
  "",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_xuanzhong_lan",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_xuanzhong",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_xuanzhong_jin"
}
QualityBgDi = {
  "",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_di_lan",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_di",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_di_jin"
}
QualityGetBgDi = {
  "",
  "uipic_ui_firstrecharge_bg_zhuangbei_xiangqing_lan",
  "uipic_ui_firstrecharge_bg_zhuangbei_xiangqing",
  "uipic_ui_firstrecharge_bg_zhuangbei_xiangqing_jin"
}
IllustrateType = {Picture = 1, ActivitySSR = 2}
GetShipImage = {
  [3] = "uipic_ui_activityssr_fo_sr",
  [4] = "uipic_ui_activityssr_fo_ssr"
}
OpenSharePage = {Other = 1, ActSSR = 2}
GetShipImageRand = {
  [3] = "uipic_ui_activityssr_bg_ka_sr",
  [4] = "uipic_ui_activityssr_bg_ka_ssr"
}
GetShipShareImageRand = {
  [3] = "uipic_ui_getship_bg_sr_di",
  [4] = "uipic_ui_getship_bg_ssr_di"
}
LightQualityIcon = {
  [3] = "uipic_ui_activityssr_im_ka_sr",
  [4] = "uipic_ui_activityssr_im_ka_ssr"
}
BlackQualityIcon = {
  [3] = "uipic_ui_activityssr_im_ka_sr_hei",
  [4] = "uipic_ui_activityssr_im_ka_ssr_hei"
}
SeaCopyStage = {
  Day = 1,
  Night = 2,
  Dusk = 3,
  S = 4,
  New = 5
}
WISH_ActivityState = {
  TODO = 10000,
  DOING = 10001,
  DONE = 10002
}
BuildingMode = {_2D = 1, _3D = 2}
SelectImg = {
  "",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_xuanzhong_lan",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_xuanzhong",
  "uipic_ui_firstrecharge_bg_shouchongzhuangbei_xuanzhong_jin"
}
WalkDogChapterId = 70000
BathHeroStateType = {
  Bathing = 1,
  DormRoom = 2,
  Working = 3,
  Other = 4
}
EWishItemType = {COMMON = 1, BINDSHIP = 2}
HeroPlotType = {Special = 1, Normal = 2}
UI3DModelType = {ShipGirl = 1, Other = 2}
InteractionItemType = {
  HalloweenPumpkin = 1,
  ChristmasFurniture = 2,
  SnowGlobe = 3,
  SnowGlobeBaby = 4
}
InteractionItemPageType = {
  [15] = "ChristmasCrystalPage",
  [45] = "ValentineCrystalPage"
}
TorpedoMode = {
  [0] = 0,
  [1] = 1
}
HalloweenStoryCandyItemId = 17105
ChristmasSnowCionItemId = 17006
InteractionItemType = {
  HalloweenPumpkin = 1,
  Furniture = 2,
  SnowGlobe = 3,
  SnowGlobeBaby = 4,
  PaperCut = 5,
  PaperCutEffect = 6,
  Posters = 7,
  childSignGift = 8101
}
InteractionBagItemType = {Other = 0, Poster = 1}
FurnitureCionItemId = {ChristmasSnowCoin = 17006, SpringCoin = 17009}
ActivityInteractionItemId = {
  ChristmasCrystalBallId = 15,
  ChristmasToryId = 16,
  ValentineCrystalBallId = 45,
  ValentineToryId = 46,
  PaperCutEffectId = 35,
  ChildCarpFlagId = 8100300
}
TowerType = {Solo = 1, Multi = 2}
TowerCopyState = {
  Clear = 1,
  Attack = 2,
  Abandon = 3,
  Lock = 4
}
TowerCopyType = {
  Boss = 1,
  LittleBoss = 2,
  Buff = 3
}
TowerBuffType = {Reset = 3}
UserAgreementType = {
  AgreementAndPrivacy = 1,
  Agreement = 2,
  Privacy = 3
}
EquipBigType = {
  One = 1,
  Two = 2,
  Three = 3,
  Four = 4,
  Five = 5,
  Six = 6
}
DiscountType = {Universal = 1, Exclusive = 2}
TotalExploreReward = {ChooseShip = 1, GetBox = 2}
TopGoToPage = {Shop = 1, DailyCopy = 2}
BuildUpType = {Equip = 1, Ship = 2}
AllType = {
  [1] = "N",
  [2] = "R",
  [3] = "SR",
  [4] = "SSR",
  [5] = "UR"
}
IllustrateFun = {
  Girl = 0,
  Memory = 1,
  Equip = 2,
  RemouldGirl = 3
}
AutoAddOption = {
  LEVEL = 2,
  FIGHT = 3,
  ATTACK = 12
}
ExchangeCondition = {Copy = 16, Level = 25}
SyncJsonTable = {}
AutoAddOption = {
  LEVEL = 2,
  FIGHT = 3,
  ATTACK = 12
}
TotalExploreReward = {ChooseShip = 1, GetBox = 2}
SSRDirection = {Left = 1, Right = 2}
SummerNoticeBtnIcon = {
  [1] = "uipic_ui_summernotice_bt_1",
  [2] = "uipic_ui_summernotice_bt_2",
  [3] = "uipic_ui_summernotice_bt_3",
  [4] = "uipic_ui_summernotice_bt_4"
}
RemouldEffectType = {
  Rare = 1,
  Attr = 2,
  Fashion = 3,
  Skill = 4,
  SkillUpgrade = 5
}
ShipPictureType = {Normal = 0, Remould = 1}
RankType = {
  MiniGame = 1,
  ActivityBossSinge = 2,
  ActivityBossTeam = 3
}
