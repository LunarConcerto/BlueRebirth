# StageSimpleBattle
## StageSimpleBattle._getStartData

```c
Battle_StartData_BattleStartData_o *__cdecl BabelTime_GD_StageSimpleBattle__getStartData(
        BabelTime_GD_StageSimpleBattle_o *this,
        FSM_FSMParam_o *enterParam, // FSMParam
        const MethodInfo *method)
{
  int v3; // ebx
  Il2CppObject *param; // ecx
  __int128 *v5; // eax
  int32_t v6; // esi
  __int128 v7; // xmm0
  __int128 v8; // xmm1
  Il2CppObject *v9; // eax
  Il2CppObject *v10; // edx
  Il2CppClass *klass; // edi
  unsigned __int8 v12; // cl
  bool v13; // cl
  Il2CppObject *v14; // eax
  int method_low; // eax
  bool v16; // cl
  Il2CppObject *v17; // eax
  pb_TArchiveCopyData_o *v18; // edi
  Battle_StartData_PVEStartData_o *v19; // esi
  int v20; // esi
  bool v21; // al
  int v22; // esi
  System_Collections_Generic_HashSet_Text__o *v23; // edi
  int v24; // eax
  XLua_LuaTable_o *QucikConditions; // eax
  intptr_t v26; // esi
  XLua_LuaTable_o *v27; // edi
  int v28; // edi
  System_Collections_Generic_HashSet_Text__o *v29; // esi
  intptr_t v30; // esi
  Il2CppObject *Instance; // eax
  int v32; // esi
  int v33; // eax
  unsigned __int8 v34; // al
  bool v35; // al
  pb_TStartBaseRet_o *v36; // edi
  int v37; // eax
  FSM_FSMParam_o *v38; // eax
  unsigned int v39; // esi
  int v40; // ecx
  FSM_FSMParam_o *i; // edi
  Il2CppObject *v42; // eax
  FSM_FSMParam_c *v43; // ebx
  void *v44; // eax
  int v46; // eax
  BabelTime_Net_Message_o v47; // [esp-28h] [ebp-5Ch]
  __int128 v48; // [esp+1Ch] [ebp-18h]
  int v49; // [esp+2Ch] [ebp-8h]
  Selector_o *action; // [esp+30h] [ebp-4h]
  FSM_FSMParam_o *enterParama; // [esp+40h] [ebp+Ch]
  XLua_LuaTable_o *enterParamb; // [esp+40h] [ebp+Ch]
  FSM_FSMParam_o *enterParamc; // [esp+40h] [ebp+Ch]
  unsigned __int8 enterParam_3; // [esp+43h] [ebp+Fh]

  if ( !byte_6C053A1 )
  {
    sub_64CD0A0(45837);
    byte_6C053A1 = 1;
  }
  v3 = sub_6502E10(BabelTime_GD_StageSimpleBattle__getStartData_c__AnonStorey0_TypeInfo);
  v49 = v3;
  FPSCounter__Main((FPSCounter_o *)v3, 0);
  if ( !enterParam )
    goto LABEL_63;
  param = enterParam->fields.param; // enterParam 取出的 fields.param 实际是 BabelTime_Net_Message
  if ( !param )
    goto LABEL_63;
  if ( param->klass->_1.declaringType != BabelTime_Net_Message_TypeInfo->_1.declaringType )
    sub_4FD2CF0(param, BabelTime_Net_Message_TypeInfo);
  v5 = (__int128 *)sub_6502F80(param); // 该函数仅为 param + 8 应该是获得数据起始点
  v6 = *((_DWORD *)v5 + 8); // 拆出 IsResponse 字段
  v7 = *v5; // 拆出 Time 字段
  v8 = v5[1]; // 拆出 ErrMsg 字段
  v48 = *v5;
  if ( !v3 )
    goto LABEL_63;
  *(_DWORD *)(v3 + 8) = 0;
  if ( (BYTE2(BabelTime_Net_MessageHelper_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !BabelTime_Net_MessageHelper_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(BabelTime_Net_MessageHelper_TypeInfo);
    v7 = v48;
  }
  *(_OWORD *)&v47.fields.Time = v7;
  *(_OWORD *)&v47.fields.ErrMsg = v8;
  v47.fields.IsResponse = v6;
  v9 = BabelTime_Net_MessageHelper__Unpack(0, v47, 0); // 反序列化协议 Protobuf
  v10 = v9;
  if ( !v9 )
    goto LABEL_27;
  klass = v9->klass;
  v12 = (unsigned __int8)pb_TStartBaseRet_TypeInfo->vtable._0_Equals.method;
  enterParam_3 = (unsigned __int8)v9->klass->vtable[0].method;
  v13 = enterParam_3 >= v12
     && *(pb_TStartBaseRet_c **)(*(&klass->_2.cctor_finished + 1) + 4 * v12 - 4) == pb_TStartBaseRet_TypeInfo;
  v14 = 0;
  if ( v13 )
    v14 = v10;
  if ( v14 ) // 根据协议类型，构建不同的StartData
  {
    v34 = (unsigned __int8)pb_TStartBaseRet_TypeInfo->vtable._0_Equals.method;
    v35 = enterParam_3 >= v34
       && *(pb_TStartBaseRet_c **)(*(&klass->_2.cctor_finished + 1) + 4 * v34 - 4) == pb_TStartBaseRet_TypeInfo;
    v36 = 0;
    if ( v35 )
      v36 = (pb_TStartBaseRet_o *)v10;
    if ( !v36 )
      sub_4FD2CF0(v10, pb_TStartBaseRet_TypeInfo);
    v19 = (Battle_StartData_PVEStartData_o *)sub_6502E10(Battle_StartData_PVEStartData_TypeInfo);
    Battle_StartData_PVEStartData___ctor_2049238912(v19, v36, 0); // 新战斗
  }
  else
  {
    method_low = LOBYTE(pb_TArchiveCopyData_TypeInfo->vtable._0_Equals.method);
    v16 = enterParam_3 >= (unsigned __int8)method_low
       && *(pb_TArchiveCopyData_c **)(*(&klass->_2.cctor_finished + 1) + 4 * (unsigned __int8)method_low - 4) == pb_TArchiveCopyData_TypeInfo;
    v17 = 0;
    if ( v16 )
      v17 = v10;
    if ( !v17 )
      goto LABEL_27;
    v18 = (pb_TArchiveCopyData_o *)sub_4FD2C00(v10, pb_TArchiveCopyData_TypeInfo);
    v19 = (Battle_StartData_PVEStartData_o *)sub_6502E10(Battle_StartData_PVEResumeStartData_TypeInfo);
    Battle_StartData_PVEResumeStartData___ctor((Battle_StartData_PVEResumeStartData_o *)v19, v18, 0); // 恢复战斗
  }
  *(_DWORD *)(v3 + 8) = v19;
LABEL_27:
  v20 = *(_DWORD *)(v3 + 8);
  v21 = CSharpToLuaFunc__IsInGuide(0, 0);
  if ( !v20 )
    goto LABEL_63;
  *(_BYTE *)(v20 + 132) = v21;
  v22 = *(_DWORD *)(v3 + 8);
  v23 = (System_Collections_Generic_HashSet_Text__o *)sub_6502E10(System_Collections_Generic_Dictionary_int__bool__TypeInfo);
  System_Collections_Generic_HashSet_Text____ctor(v23, Method_System_Collections_Generic_Dictionary_int__bool___ctor__);
  if ( !v22 )
    goto LABEL_63;
  *(_DWORD *)(v22 + 144) = v23;
  v24 = *(_DWORD *)(v3 + 8);
  if ( !v24 )
    goto LABEL_63;
  QucikConditions = CSharpToLuaFunc__GetQucikConditions(0, *(System_String_o **)(v24 + 8), *(_DWORD *)(v24 + 140), 0);
  v26 = Method_BabelTime_GD_StageSimpleBattle__getStartData_c__AnonStorey0___m__0__;
  v27 = QucikConditions;
  enterParama = (FSM_FSMParam_o *)sub_6502E10(System_Action_int__bool__TypeInfo);
  Selector___ctor((Selector_o *)enterParama, (Il2CppObject *)v3, v26, Method_System_Action_int__bool___ctor__);
  if ( !v27 )
    goto LABEL_63;
  XLua_LuaTable__ForEach_int__bool_(
    v27,
    (System_Action_TKey__TValue__o *)enterParama,
    Method_XLua_LuaTable_ForEach_int__bool___);
  if ( !byte_6C053A3 )
  {
    sub_64CD0A0(45836);
    byte_6C053A3 = 1;
  }
  v28 = sub_6502E10(BabelTime_GD_StageSimpleBattle__getEquipFashionData_c__AnonStorey1_TypeInfo);
  FPSCounter__Main((FPSCounter_o *)v28, 0);
  enterParamb = CSharpToLuaFunc__GetHeroEffect(0, 0);
  v29 = (System_Collections_Generic_HashSet_Text__o *)sub_6502E10(System_Collections_Generic_Dictionary_int__Dictionary_int__List_int____TypeInfo);
  System_Collections_Generic_HashSet_Text____ctor(
    v29,
    Method_System_Collections_Generic_Dictionary_int__Dictionary_int__List_int_____ctor__);
  if ( !v28 )
    goto LABEL_63;
  *(_DWORD *)(v28 + 8) = v29;
  v30 = Method_BabelTime_GD_StageSimpleBattle__getEquipFashionData_c__AnonStorey1___m__0__;
  action = (Selector_o *)sub_6502E10(System_Action_int__LuaTable__TypeInfo);
  Selector___ctor(action, (Il2CppObject *)v28, v30, Method_System_Action_int__LuaTable___ctor__);
  if ( !enterParamb )
    goto LABEL_63;
  XLua_LuaTable__ForEach_object__object_(
    enterParamb,
    (System_Action_TKey__TValue__o *)action,
    Method_XLua_LuaTable_ForEach_int__LuaTable___);
  if ( (BYTE2(TSingleton_SkillAnimEquipUtil__TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !TSingleton_SkillAnimEquipUtil__TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(TSingleton_SkillAnimEquipUtil__TypeInfo);
  }
  Instance = TSingleton_object___GetInstance(0, Method_TSingleton_SkillAnimEquipUtil__GetInstance__);
  if ( !Instance )
    goto LABEL_63;
  DescSMRShapeParam__set_paramName((DescSMRShapeParam_o *)Instance, *(System_String_o **)(v28 + 8), 0);
  v32 = *(_DWORD *)(v3 + 8);
  if ( !byte_6C053A2 )
  {
    sub_64CD0A0(45838);
    byte_6C053A2 = 1;
  }
  if ( !v32 )
    goto LABEL_63;
  if ( !*(_BYTE *)(v32 + 132) )
    return *(Battle_StartData_BattleStartData_o **)(v3 + 8);
  v33 = *(_DWORD *)(v32 + 56);
  if ( !v33 )
    goto LABEL_63;
  if ( *(int *)(v33 + 12) <= 0 )
    return *(Battle_StartData_BattleStartData_o **)(v3 + 8);
  v37 = *(_DWORD *)(v33 + 16);
  if ( !v37 || (v38 = *(FSM_FSMParam_o **)(v37 + 72), v39 = 0, v40 = 0, (enterParamc = v38) == 0) )
LABEL_63:
    sub_64F3DF0(0);
  for ( i = v38 + 1; ; i = (FSM_FSMParam_o *)((char *)i + 4) )
  {
    v42 = v38->fields.param;
    if ( v40 >= (int)v42 )
      break;
    if ( v39 >= (unsigned int)v42 )
    {
      v46 = sub_64F33B0();
      sub_64F3D20(v46, 0, 0);
    }
    v43 = i->klass;
    v44 = (void *)sub_6505C70(Battle_StartData_PSkill___TypeInfo, 0);
    if ( !v43 )
      goto LABEL_63;
    ++v39;
    v43->_1.fields = v44;
    v38 = enterParamc;
    v40 = v39;
  }
  v3 = v49;
  return *(Battle_StartData_BattleStartData_o **)(v3 + 8); // 构造了 BattleStartData ?
}
```

# StagePvpBattle
## StagePvpBattle._getStartData

```c
Battle_StartData_BattleStartData_o *__cdecl BabelTime_GD_StagePvpBattle___GetStartData(
        BabelTime_GD_StagePvpBattle_o *this,
        FSM_FSMParam_o *enterParam,
        const MethodInfo *method)
{
  Il2CppObject *param; // ecx
  __int128 *v4; // eax
  __int128 v5; // xmm0
  int32_t v6; // esi
  __int128 v7; // xmm1
  Il2CppObject *v8; // esi
  Battle_StartData_PVPStartData_o *v9; // eax
  Battle_StartData_PVPStartData_o *v10; // edi
  unsigned __int8 v12; // cl
  bool v13; // al
  pb_TBattleCreateMutiRet_o *v14; // ecx
  BabelTime_Net_Message_o v15; // [esp-28h] [ebp-50h]
  __int128 v16; // [esp+18h] [ebp-10h]

  if ( !byte_6C05390 )
  {
    sub_64CD0A0(45818);
    byte_6C05390 = 1;
  }
  if ( !enterParam || (param = enterParam->fields.param) == 0 )
    sub_64F3DF0(0);
  if ( param->klass->_1.declaringType != BabelTime_Net_Message_TypeInfo->_1.declaringType )
    sub_4FD2CF0(param, BabelTime_Net_Message_TypeInfo);
  v4 = (__int128 *)sub_6502F80(param);
  v5 = *v4; // Time
  v6 = *((_DWORD *)v4 + 8); // IsResponse
  v7 = v4[1]; // ErrMsg
  v16 = *v4;
  if ( (BYTE2(BabelTime_Net_MessageHelper_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !BabelTime_Net_MessageHelper_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(BabelTime_Net_MessageHelper_TypeInfo);
    v5 = v16;
  }
  *(_OWORD *)&v15.fields.Time = v5;
  *(_OWORD *)&v15.fields.ErrMsg = v7;
  v15.fields.IsResponse = v6;
  v8 = BabelTime_Net_MessageHelper__Unpack(0, v15, 0); // 反序列化网络信息
  v9 = (Battle_StartData_PVPStartData_o *)sub_6502E10(Battle_StartData_PVPStartData_TypeInfo); // 构造了 BattleStartData ？
  v10 = v9;
  if ( v8 )
  {
    v12 = (unsigned __int8)pb_TBattleCreateMutiRet_TypeInfo->vtable._0_Equals.method;
    v13 = LOBYTE(v8->klass->vtable[0].method) >= v12
       && *(pb_TBattleCreateMutiRet_c **)(*(&v8->klass->_2.cctor_finished + 1) + 4 * v12 - 4) == pb_TBattleCreateMutiRet_TypeInfo;
    v14 = 0;
    if ( v13 )
      v14 = (pb_TBattleCreateMutiRet_o *)v8;
    if ( !v14 )
      sub_4FD2CF0(v8, pb_TBattleCreateMutiRet_TypeInfo);
    Battle_StartData_PVPStartData___ctor(v10, v14, 0);
    return (Battle_StartData_BattleStartData_o *)v10; // PVPStartData -> BattleStartData
  }
  else
  {
    Battle_StartData_PVPStartData___ctor(v9, 0, 0);
    return (Battle_StartData_BattleStartData_o *)v10; // PVPStartData -> BattleStartData
  }
}
```

# BattleLauncher

# InitNet

主要作用为注册了 4 个子方法。

每个消息名（`StringLiteral_8669~8672`）是 protobuf 消息类型名，分别对应 `_InitNet_m__0__` 到 `_InitNet_m__3__` 四个 C# 匿名函数（lambda）。

**整体意思**：`Battle_Launcher` 初始化时向 `NetLogic` 注册 4 个战斗相关的网络消息监听，收到对应消息后由各自的 lambda 回调处理。

四条协议分别为：
1. copy.StartBase ：剧情战斗
2. archiveCopy.ArchiveCopyData ： 活动剧情战斗
3. battle.createBattleInfo ： 创建战斗信息
4. battle.CreateMutiBattle ： 创建多个战斗？

```c
void __cdecl Battle_Launcher____InitNet(Battle_Launcher_o *this, const MethodInfo *method)
{
  Battle_Launcher_c *v2; // ecx
  System_String_o *v3; // ebx
  intptr_t v4; // esi
  Selector_o *v5; // edi
  Battle_Launcher_c *v6; // ecx
  System_String_o *v7; // ebx
  intptr_t v8; // esi
  Selector_o *v9; // edi
  Battle_Launcher_c *v10; // ecx
  System_String_o *v11; // ebx
  intptr_t v12; // esi
  Selector_o *v13; // edi
  Battle_Launcher_c *v14; // ecx
  System_String_o *v15; // ebx
  intptr_t v16; // esi
  Selector_o *v17; // edi

  if ( !byte_69B4CF6 )
  {
    sub_627D0A0(30697);
    byte_69B4CF6 = 1;
  }
  
  
  v2 = Battle_Launcher_TypeInfo;
  v3 = StringLiteral_8669; // copy.StartBase
  if ( !*(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 4) ) 
  {
    v4 = Method_Battle_Launcher____InitNet_m__0__;
    v5 = (Selector_o *)sub_62B2E10(BabelTime_Net_MessageCallback_TypeInfo);
    Selector___ctor(v5, 0, v4, 0);
    *(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 4) = v5;
    v2 = Battle_Launcher_TypeInfo;
  }
  BabelTime_Net_NetLogic__RegisterMessageHandler(
    0,
    v3,
    0,
    *(BabelTime_Net_MessageCallback_o **)(v2->_2.cctor_started + 4),
    0);
    
    
  v6 = Battle_Launcher_TypeInfo;
  v7 = StringLiteral_8670; // archiveCopy.ArchiveCopyData
  if ( !*(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 8) )
  {
    v8 = Method_Battle_Launcher____InitNet_m__1__;
    v9 = (Selector_o *)sub_62B2E10(BabelTime_Net_MessageCallback_TypeInfo);
    Selector___ctor(v9, 0, v8, 0);
    *(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 8) = v9;
    v6 = Battle_Launcher_TypeInfo;
  }
  BabelTime_Net_NetLogic__RegisterMessageHandler(
    0,
    v7,
    0,
    *(BabelTime_Net_MessageCallback_o **)(v6->_2.cctor_started + 8),
    0);
    
    
  v10 = Battle_Launcher_TypeInfo;
  v11 = StringLiteral_8671; // battle.createBattleInfo
  if ( !*(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 12) )
  {
    v12 = Method_Battle_Launcher____InitNet_m__2__;
    v13 = (Selector_o *)sub_62B2E10(BabelTime_Net_MessageCallback_TypeInfo);
    Selector___ctor(v13, 0, v12, 0);
    *(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 12) = v13;
    v10 = Battle_Launcher_TypeInfo;
  }
  BabelTime_Net_NetLogic__RegisterMessageHandler(
    0,
    v11,
    0,
    *(BabelTime_Net_MessageCallback_o **)(v10->_2.cctor_started + 12),
    0);
    
    
  v14 = Battle_Launcher_TypeInfo;
  v15 = StringLiteral_8672; // battle.CreateMutiBattle
  if ( !*(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 16) )
  {
    v16 = Method_Battle_Launcher____InitNet_m__3__;
    v17 = (Selector_o *)sub_62B2E10(BabelTime_Net_MessageCallback_TypeInfo);
    Selector___ctor(v17, 0, v16, 0);
    *(_DWORD *)(Battle_Launcher_TypeInfo->_2.cctor_started + 16) = v17;
    v14 = Battle_Launcher_TypeInfo;
  }
  BabelTime_Net_NetLogic__RegisterMessageHandler(
    0,
    v15,
    0,
    *(BabelTime_Net_MessageCallback_o **)(v14->_2.cctor_started + 16),
    0);
    
    
}
```

子方法 m_0 为对应 copy.StartBase 协议的处理器

```c
void __cdecl Battle_Launcher_____InitNet_m__0(
        Il2CppObject *this,
        BabelTime_Net_Message_o msg,
        const MethodInfo *method)
{
  BabelTime_GD_StageMgr_o *Ins; // esi
  int v4; // ecx
  BabelTime_Net_Message_o v5; // [esp+0h] [ebp-24h] BYREF

  if ( !byte_69B4CF7 )
  {
    sub_627D0A0(30693);
    byte_69B4CF7 = 1;
  }
  
  if ( (BYTE2(BabelTime_GD_StageMgr_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !BabelTime_GD_StageMgr_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(BabelTime_GD_StageMgr_TypeInfo);
  }
  Ins = BabelTime_GD_StageMgr__get_Ins(0, 0); // 取关卡管理器单例
  v5 = msg;
  v4 = sub_62B2B50(BabelTime_Net_Message_TypeInfo, &v5); // 将 msg 装箱了，msg = NetMessage 是值类型
  if ( !Ins )
    sub_62A3DF0(0);
  ((void (__cdecl *)(BabelTime_GD_StageMgr_o *, int, int, _DWORD, const char *))Ins->klass[1]._1.gc_desc)( // 调用了StageMgr
    Ins,
    3, // 事件码
    v4, // NetMessage
    0,
    Ins->klass[1]._1.name);
}
```

其余 m_1、m_2、m_3 结构完全相同，只有事件码不同。

m_0、m_1 对应事件码为 3
m_2、m_3 对应事件码为 4

# MessageHelper

## Unpack

`MessageHelper__Unpack` 根据消息的方法名反序列化 protobuf 字节流。

**整体意思**：`MessageHelper` 内部维护一个 `Dictionary<string, Type>`（静态字段 `cctor_started`），key 是方法名（如 `"TStartBaseRet"`），value 是对应的 `System.Type`。
`Unpack` 用 `message.Method` 查到类型后，把 `message.Payload`（bytes）反序列化为对应的 protobuf 对象返回。如果 Method 未注册（未知消息类型），返回 null。

```c
Il2CppObject *__cdecl BabelTime_Net_MessageHelper__Unpack(
        Il2CppObject *this,
        BabelTime_Net_Message_o message,
        const MethodInfo *method)
{
  BabelTime_Net_MessageHelper_c *v3; // eax
  System_Collections_Generic_Dictionary_Mesh__Vector3____o *v4; // eax
  BabelTime_Net_MessageHelper_c *v6; // eax
  System_Collections_Generic_Dictionary_object__object__o *v7; // eax
  Il2CppObject *Item; // eax

  if ( !byte_69B5B66 )
  {
    sub_627D0A0(34373);
    byte_69B5B66 = 1;
  }
  
  v3 = BabelTime_Net_MessageHelper_TypeInfo;
  if ( (BYTE2(BabelTime_Net_MessageHelper_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !BabelTime_Net_MessageHelper_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(BabelTime_Net_MessageHelper_TypeInfo);
    v3 = BabelTime_Net_MessageHelper_TypeInfo;
  }
  v4 = *(System_Collections_Generic_Dictionary_Mesh__Vector3____o **)v3->_2.cctor_started;
  if ( !v4 )
    goto LABEL_14;
  if ( !System_Collections_Generic_Dictionary_Mesh__Vector3_____ContainsKey(
          v4,
          (UnityEngine_Mesh_o *)message.fields.Method,
          Method_System_Collections_Generic_Dictionary_string__Type__ContainsKey__) )
    return 0;
  v6 = BabelTime_Net_MessageHelper_TypeInfo;
  if ( (BYTE2(BabelTime_Net_MessageHelper_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !BabelTime_Net_MessageHelper_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(BabelTime_Net_MessageHelper_TypeInfo);
    v6 = BabelTime_Net_MessageHelper_TypeInfo;
  }
  v7 = *(System_Collections_Generic_Dictionary_object__object__o **)v6->_2.cctor_started;
  if ( !v7 )
LABEL_14:
    sub_62A3DF0(0);
  Item = System_Collections_Generic_Dictionary_object__object___get_Item(
           v7,
           (Il2CppObject *)message.fields.Method,
           Method_System_Collections_Generic_Dictionary_string__Type__get_Item__);
  return BabelTime_Net_PbSerializer__Deserialize(0, (System_Type_o *)Item, message.fields.Payload, 0);
}
```

## Register__TStartBaseRet

`MessageHelper__Registor_<T>()` 是泛型方法（此处为 `Registor<TStartBaseRet>` 的实例化），用于注册消息头与 protobuf 类型的映射。

**整体意思**：把 `msgHeader`（如 `"TStartBaseRet"`）映射到对应的 protobuf C# 类型，存入 `Dictionary<string, Type>`。这就是 `Unpack` 里用到的那张表——注册后 `Unpack` 才能根据消息名找到类型并反序列化。IDA 把 `Dictionary<string, Type>` 在不同位置推断成了 `Dictionary<Mesh, Vector3>` / `Dictionary<Shader, PropertySheet>` 等错误类型名，实际是同一张表。

```c
void __cdecl BabelTime_Net_MessageHelper__Registor_TStartBaseRet_(
        Il2CppObject *this,
        System_String_o *msgHeader,
        const MethodInfo_706730 *method)
{
  BabelTime_Net_MessageHelper_c *v3; // eax
  System_Collections_Generic_Dictionary_Mesh__Vector3____o *v4; // eax
  BabelTime_Net_MessageHelper_c *v5; // eax
  System_Collections_Generic_Dictionary_Shader__PropertySheet__o *v6; // ebx
  Il2CppType *_0_T; // esi
  System_Type_o *TypeFromHandle; // eax

  if ( !byte_69B89B9 )
  {
    sub_627D0A0(34370);
    byte_69B89B9 = 1;
  }
  v3 = BabelTime_Net_MessageHelper_TypeInfo;
  if ( (BYTE2(BabelTime_Net_MessageHelper_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !BabelTime_Net_MessageHelper_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(BabelTime_Net_MessageHelper_TypeInfo);
    v3 = BabelTime_Net_MessageHelper_TypeInfo;
  }
  v4 = *(System_Collections_Generic_Dictionary_Mesh__Vector3____o **)v3->_2.cctor_started;
  if ( !v4 )
    goto LABEL_17;
  if ( System_Collections_Generic_Dictionary_Mesh__Vector3_____ContainsKey(
         v4,
         (UnityEngine_Mesh_o *)msgHeader,
         Method_System_Collections_Generic_Dictionary_string__Type__ContainsKey__) )
  {
    return;
  }
  v5 = BabelTime_Net_MessageHelper_TypeInfo;
  if ( (BYTE2(BabelTime_Net_MessageHelper_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !BabelTime_Net_MessageHelper_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(BabelTime_Net_MessageHelper_TypeInfo);
    v5 = BabelTime_Net_MessageHelper_TypeInfo;
  }
  v6 = *(System_Collections_Generic_Dictionary_Shader__PropertySheet__o **)v5->_2.cctor_started;
  _0_T = method->rgctx_data->_0_T;
  if ( (BYTE2(System_Type_TypeInfo->vtable._1_Finalize.methodPtr) & 1) != 0
    && !System_Type_TypeInfo->_2.genericContainerIndex )
  {
    il2cpp_runtime_class_init_0(System_Type_TypeInfo);
  }
  TypeFromHandle = System_Type__GetTypeFromHandle(0, (System_RuntimeTypeHandle_o)_0_T, 0);
  if ( !v6 )
LABEL_17:
    sub_62A3DF0(0);
  System_Collections_Generic_Dictionary_Shader__PropertySheet___Add(
    v6,
    (UnityEngine_Shader_o *)msgHeader,
    (UnityEngine_Rendering_Common_PropertySheet_o *)TypeFromHandle,
    Method_System_Collections_Generic_Dictionary_string__Type__Add__);
}
```


# 备注：已知坑点（2026-08-20）

## `_getStartData` 崩溃根因（已修复）

`StageSimpleBattle._getStartData`（RVA `0x1EFC00`）的 prologue 为：

```
55 8B EC | 83 EC 28 | 80 3D A1 53 D4 11 00 | 53 56 57 | ...
push ebp ; mov ebp,esp ; sub esp,0x28 ; cmp byte ptr [0x11D453A1], 0 ; push ebx ...
```

即 `push ebp(1) + mov ebp,esp(2) + sub esp,0x28(3) + cmp(7字节) = 13 字节`。
hook 若用 `stolenLen=11` 会把 `cmp` 指令截断（`80 3D A1 53 D4` 之后缺 `11 00`），
stolen stub 执行到残缺 `cmp` 时把下一条 `E9`（回跳）当作操作数解析 → 立即崩溃。
**stolenLen 必须为 13**，否则函数一进即崩，且 `Ship.PBConvert` 永远不会触发
（此前误以为是 `Unpack` 返回 null）。

`Ship.PBConvert`（RVA `0x307F20`）同理：prologue
`push ebp(1) mov ebp,esp(2) push -1(2) push imm(5) mov eax,fs:[0](6) push eax(1)`，
`stolenLen` 需为 17（覆盖到 `push eax` 结束），不能用 11。

> 结论：此前"`_getStartData` 崩溃 = `MessageHelper.Unpack` 返回 null"的推断是错的，
> 崩溃是自身 hook 截断指令导致的。pbMap 经日志确认已初始化（非 0）。

# 备注：战斗类型

## EnumCopyType

Copy 在游戏里好像指的是剧情一类的内容。

```csharp

[Token(Token = "0x2000AED")]
public enum EnumCopyType
{
  [Token(Token = "0x4002A6E")] Main = 1,
  [Token(Token = "0x4002A6F")] Sea = 2,
  [Token(Token = "0x4002A70")] Train = 3,
  [Token(Token = "0x4002A71")] Traindv = 4,
  [Token(Token = "0x4002A72")] Trainlv = 5,
  [Token(Token = "0x4002A73")] BigActivityMain = 6,
  [Token(Token = "0x4002A74")] BigActivitySea = 7,
  [Token(Token = "0x4002A75")] Ar = 8,
  [Token(Token = "0x4002A76")] Daily = 9,
  [Token(Token = "0x4002A77")] Goods = 10, // 0x0000000A
  [Token(Token = "0x4002A78")] BigActivityMainEx = 11, // 0x0000000B
  [Token(Token = "0x4002A79")] BigActivitySeaEx = 12, // 0x0000000C
  [Token(Token = "0x4002A7A")] Tower = 13, // 0x0000000D
}

```

# 备注：类型结构

## TStartBaseRet

```csharp

[AttributeAttribute(Name = "ProtoContractAttribute", RVA = "0x8ECB0", Offset = "0x8E0B0")]
[Serializable]
public class TStartBaseRet : IExtensible
{
  private TBattlePlayerList _BattlePlayer;
  private int _RandomSeed;
  private int _Rid;
  private readonly List<TCopyRes> _arrRes;
  private readonly List<int> _EnemyFleet;
  private int _CopyId;
  private int _CopyType;
  private bool _CopyPass;
  private int _BossProgress;
  private bool _IsRunningFight;
  private readonly List<TShipEquipGridInfo> _ShipEquipGridInfo;
  private readonly List<TRandomFactor> _RandomFactors;
  private int _SafeLv;
  private TVerifyPackage _Verify;
  private readonly List<TBattlePlayerList> _ExtraBattlePlayerList;
  private string _Token;
  private readonly List<TCopySkipVcr> _SkipVcr;
  private int _BattleMode;
  private bool _IsFinal;
  private int _AnimMode;
  private int _WeatherGroupId;
  private readonly List<int> _CopyMission;
  private readonly List<TBattleEnemyFleet> _EnemyFleets;
  private readonly List<TPassEvaluate> _ConfigData;
  private int _MatchType;
  private IExtension extensionObject;

  [Il2CppDummyDll.Token(Token = "0x600616A")]
  [Address(RVA = "0x797410", Offset = "0x796810", VA = "0x10797410")]
  public TStartBaseRet()
  {
  }

  [Il2CppDummyDll.Token(Token = "0x170009CA")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x8F660", Offset = "0x8EA60")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x8F660", Offset = "0x8EA60")]
  public TBattlePlayerList BattlePlayer
  {
    [Il2CppDummyDll.Token(Token = "0x600616B"), Address(RVA = "0x151DC0", Offset = "0x1511C0", VA = "0x10151DC0")] get
    {
      return (TBattlePlayerList) null;
    }
    [Il2CppDummyDll.Token(Token = "0x600616C"), Address(RVA = "0x169470", Offset = "0x168870", VA = "0x10169470")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009CB")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6B0F0", Offset = "0x6A4F0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6B0F0", Offset = "0x6A4F0")]
  public int RandomSeed
  {
    [Il2CppDummyDll.Token(Token = "0x600616D"), Address(RVA = "0x169460", Offset = "0x168860", VA = "0x10169460")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x600616E"), Address(RVA = "0x169480", Offset = "0x168880", VA = "0x10169480")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009CC")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6B4C0", Offset = "0x6A8C0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6B4C0", Offset = "0x6A8C0")]
  public int Rid
  {
    [Il2CppDummyDll.Token(Token = "0x600616F"), Address(RVA = "0x133440", Offset = "0x132840", VA = "0x10133440")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x6006170"), Address(RVA = "0x133450", Offset = "0x132850", VA = "0x10133450")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009CD")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6B850", Offset = "0x6AC50")]
  public List<TCopyRes> arrRes
  {
    [Il2CppDummyDll.Token(Token = "0x6006171"), Address(RVA = "0x18B7E0", Offset = "0x18ABE0", VA = "0x1018B7E0")] get
    {
      return (List<TCopyRes>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009CE")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6BAB0", Offset = "0x6AEB0")]
  public List<int> EnemyFleet
  {
    [Il2CppDummyDll.Token(Token = "0x6006172"), Address(RVA = "0x134E00", Offset = "0x134200", VA = "0x10134E00")] get
    {
      return (List<int>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009CF")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6BDA0", Offset = "0x6B1A0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6BDA0", Offset = "0x6B1A0")]
  public int CopyId
  {
    [Il2CppDummyDll.Token(Token = "0x6006173"), Address(RVA = "0x1BFA40", Offset = "0x1BEE40", VA = "0x101BFA40")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x6006174"), Address(RVA = "0x1DBAA0", Offset = "0x1DAEA0", VA = "0x101DBAA0")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D0")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6C0D0", Offset = "0x6B4D0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6C0D0", Offset = "0x6B4D0")]
  public int CopyType
  {
    [Il2CppDummyDll.Token(Token = "0x6006175"), Address(RVA = "0x171BC0", Offset = "0x170FC0", VA = "0x10171BC0")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x6006176"), Address(RVA = "0x171BE0", Offset = "0x170FE0", VA = "0x10171BE0")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D1")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6C4C0", Offset = "0x6B8C0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6C4C0", Offset = "0x6B8C0")]
  public bool CopyPass
  {
    [Il2CppDummyDll.Token(Token = "0x6006177"), Address(RVA = "0x22EE00", Offset = "0x22E200", VA = "0x1022EE00")] get
    {
      return new bool();
    }
    [Il2CppDummyDll.Token(Token = "0x6006178"), Address(RVA = "0x22EE10", Offset = "0x22E210", VA = "0x1022EE10")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D2")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6C860", Offset = "0x6BC60")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6C860", Offset = "0x6BC60")]
  public int BossProgress
  {
    [Il2CppDummyDll.Token(Token = "0x6006179"), Address(RVA = "0x1462B0", Offset = "0x1456B0", VA = "0x101462B0")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x600617A"), Address(RVA = "0x1463D0", Offset = "0x1457D0", VA = "0x101463D0")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D3")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6CC00", Offset = "0x6C000")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6CC00", Offset = "0x6C000")]
  public bool IsRunningFight
  {
    [Il2CppDummyDll.Token(Token = "0x600617B"), Address(RVA = "0x3DD2F0", Offset = "0x3DC6F0", VA = "0x103DD2F0")] get
    {
      return new bool();
    }
    [Il2CppDummyDll.Token(Token = "0x600617C"), Address(RVA = "0x794530", Offset = "0x793930", VA = "0x10794530")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D4")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6CFF0", Offset = "0x6C3F0")]
  public List<TShipEquipGridInfo> ShipEquipGridInfo
  {
    [Il2CppDummyDll.Token(Token = "0x600617D"), Address(RVA = "0x171BD0", Offset = "0x170FD0", VA = "0x10171BD0")] get
    {
      return (List<TShipEquipGridInfo>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D5")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6D2F0", Offset = "0x6C6F0")]
  public List<TRandomFactor> RandomFactors
  {
    [Il2CppDummyDll.Token(Token = "0x600617E"), Address(RVA = "0x25A610", Offset = "0x259A10", VA = "0x1025A610")] get
    {
      return (List<TRandomFactor>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D6")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x6D5C0", Offset = "0x6C9C0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x6D5C0", Offset = "0x6C9C0")]
  public int SafeLv
  {
    [Il2CppDummyDll.Token(Token = "0x600617F"), Address(RVA = "0x2C7B10", Offset = "0x2C6F10", VA = "0x102C7B10")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x6006180"), Address(RVA = "0x2C7B20", Offset = "0x2C6F20", VA = "0x102C7B20")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D7")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x91E90", Offset = "0x91290")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x91E90", Offset = "0x91290")]
  public TVerifyPackage Verify
  {
    [Il2CppDummyDll.Token(Token = "0x6006181"), Address(RVA = "0x183E00", Offset = "0x183200", VA = "0x10183E00")] get
    {
      return (TVerifyPackage) null;
    }
    [Il2CppDummyDll.Token(Token = "0x6006182"), Address(RVA = "0x183E10", Offset = "0x183210", VA = "0x10183E10")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D8")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x92250", Offset = "0x91650")]
  public List<TBattlePlayerList> ExtraBattlePlayerList
  {
    [Il2CppDummyDll.Token(Token = "0x6006183"), Address(RVA = "0x213C00", Offset = "0x213000", VA = "0x10213C00")] get
    {
      return (List<TBattlePlayerList>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009D9")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x92510", Offset = "0x91910")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x92510", Offset = "0x91910")]
  public string Token
  {
    [Il2CppDummyDll.Token(Token = "0x6006184"), Address(RVA = "0x1A6AE0", Offset = "0x1A5EE0", VA = "0x101A6AE0")] get
    {
      return (string) null;
    }
    [Il2CppDummyDll.Token(Token = "0x6006185"), Address(RVA = "0x1A6AF0", Offset = "0x1A5EF0", VA = "0x101A6AF0")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009DA")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x92910", Offset = "0x91D10")]
  public List<TCopySkipVcr> SkipVcr
  {
    [Il2CppDummyDll.Token(Token = "0x6006186"), Address(RVA = "0x28D210", Offset = "0x28C610", VA = "0x1028D210")] get
    {
      return (List<TCopySkipVcr>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009DB")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x92BF0", Offset = "0x91FF0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x92BF0", Offset = "0x91FF0")]
  public int BattleMode
  {
    [Il2CppDummyDll.Token(Token = "0x6006187"), Address(RVA = "0x28D200", Offset = "0x28C600", VA = "0x1028D200")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x6006188"), Address(RVA = "0x28D290", Offset = "0x28C690", VA = "0x1028D290")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009DC")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x92FF0", Offset = "0x923F0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x92FF0", Offset = "0x923F0")]
  public bool IsFinal
  {
    [Il2CppDummyDll.Token(Token = "0x6006189"), Address(RVA = "0x2EC9A0", Offset = "0x2EBDA0", VA = "0x102EC9A0")] get
    {
      return new bool();
    }
    [Il2CppDummyDll.Token(Token = "0x600618A"), Address(RVA = "0x796080", Offset = "0x795480", VA = "0x10796080")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009DD")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x93420", Offset = "0x92820")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x93420", Offset = "0x92820")]
  public int AnimMode
  {
    [Il2CppDummyDll.Token(Token = "0x600618B"), Address(RVA = "0x27D550", Offset = "0x27C950", VA = "0x1027D550")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x600618C"), Address(RVA = "0x27D570", Offset = "0x27C970", VA = "0x1027D570")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009DE")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x936B0", Offset = "0x92AB0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x936B0", Offset = "0x92AB0")]
  public int WeatherGroupId
  {
    [Il2CppDummyDll.Token(Token = "0x600618D"), Address(RVA = "0x2EC300", Offset = "0x2EB700", VA = "0x102EC300")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x600618E"), Address(RVA = "0x5C07D0", Offset = "0x5BFBD0", VA = "0x105C07D0")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009DF")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x93AB0", Offset = "0x92EB0")]
  public List<int> CopyMission
  {
    [Il2CppDummyDll.Token(Token = "0x600618F"), Address(RVA = "0x112DC0", Offset = "0x1121C0", VA = "0x10112DC0")] get
    {
      return (List<int>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009E0")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x94510", Offset = "0x93910")]
  public List<TBattleEnemyFleet> EnemyFleets
  {
    [Il2CppDummyDll.Token(Token = "0x6006190"), Address(RVA = "0x5A8560", Offset = "0x5A7960", VA = "0x105A8560")] get
    {
      return (List<TBattleEnemyFleet>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009E1")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x94790", Offset = "0x93B90")]
  public List<TPassEvaluate> ConfigData
  {
    [Il2CppDummyDll.Token(Token = "0x6006191"), Address(RVA = "0x3B79C0", Offset = "0x3B6DC0", VA = "0x103B79C0")] get
    {
      return (List<TPassEvaluate>) null;
    }
  }

  [Il2CppDummyDll.Token(Token = "0x170009E2")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x94A10", Offset = "0x93E10")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x94A10", Offset = "0x93E10")]
  public int MatchType
  {
    [Il2CppDummyDll.Token(Token = "0x6006192"), Address(RVA = "0x258F20", Offset = "0x258320", VA = "0x10258F20")] get
    {
      return new int();
    }
    [Il2CppDummyDll.Token(Token = "0x6006193"), Address(RVA = "0x259050", Offset = "0x258450", VA = "0x10259050")] set
    {
    }
  }

  [Il2CppDummyDll.Token(Token = "0x6006194")]
  [Address(RVA = "0x7973F0", Offset = "0x7967F0", VA = "0x107973F0", Slot = "4")]
  private IExtension ProtoBuf\u002EIExtensible\u002EGetExtensionObject(bool createIfMissing)
  {
    return (IExtension) null;
  }
}
```

## TCopyRes

上面 TStartBaseRet 的其中一个成员字段的类型。
意思应该是章节的奖励/资源信息。来源可能为游戏 config_copy.db 配置表？

```csharp

[Token(Token = "0x2000CFD")]
[AttributeAttribute(Name = "ProtoContractAttribute", RVA = "0xA70B0", Offset = "0xA64B0")]
[Serializable]
public class TCopyRes : IExtensible
{

  private int _id;
  private readonly List<TCommonReward> _Reward;
  private IExtension extensionObject;

  [Token(Token = "0x600624F")]
  [Address(RVA = "0x7A6D00", Offset = "0x7A6100", VA = "0x107A6D00")]
  public TCopyRes()
  {
  }

  [Token(Token = "0x17000A3B")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0xA7260", Offset = "0xA6660")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0xA7260", Offset = "0xA6660")]
  public int id
  {
    [Token(Token = "0x6006250"), Address(RVA = "0x151DC0", Offset = "0x1511C0", VA = "0x10151DC0")] get
    {
      return new int();
    }
    [Token(Token = "0x6006251"), Address(RVA = "0x169470", Offset = "0x168870", VA = "0x10169470")] set
    {
    }
  }

  [Token(Token = "0x17000A3C")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x79450", Offset = "0x78850")]
  public List<TCommonReward> Reward
  {
    [Token(Token = "0x6006252"), Address(RVA = "0x169460", Offset = "0x168860", VA = "0x10169460")] get
    {
      return (List<TCommonReward>) null;
    }
  }

  [Token(Token = "0x6006253")]
  [Address(RVA = "0x792970", Offset = "0x791D70", VA = "0x10792970", Slot = "4")]
  private IExtension ProtoBuf\u002EIExtensible\u002EGetExtensionObject(bool createIfMissing)
  {
    return (IExtension) null;
  }
}

```

## TCommonReward

上面 TCopyRes 的成员

```csharp
[Serializable]
public class TCommonReward : IExtensible
{
  private int _Type;
  private int _ConfigId;
  private int _Num;
  private int _Id;
  private IExtension extensionObject;

  [Token(Token = "0x60060F6")]
  [Address(RVA = "0x11A730", Offset = "0x119B30", VA = "0x1011A730")]
  public TCommonReward()
  {
  }

  [Token(Token = "0x17000997")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x2DC50", Offset = "0x2D050")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x2DC50", Offset = "0x2D050")]
  public int Type
  {
    [Token(Token = "0x60060F7"), Address(RVA = "0x151DC0", Offset = "0x1511C0", VA = "0x10151DC0")] get
    {
      return new int();
    }
    [Token(Token = "0x60060F8"), Address(RVA = "0x169470", Offset = "0x168870", VA = "0x10169470")] set
    {
    }
  }

  [Token(Token = "0x17000998")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x82FB0", Offset = "0x823B0")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x82FB0", Offset = "0x823B0")]
  public int ConfigId
  {
    [Token(Token = "0x60060F9"), Address(RVA = "0x169460", Offset = "0x168860", VA = "0x10169460")] get
    {
      return new int();
    }
    [Token(Token = "0x60060FA"), Address(RVA = "0x169480", Offset = "0x168880", VA = "0x10169480")] set
    {
    }
  }

  [Token(Token = "0x17000999")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x65300", Offset = "0x64700")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x65300", Offset = "0x64700")]
  public int Num
  {
    [Token(Token = "0x60060FB"), Address(RVA = "0x133440", Offset = "0x132840", VA = "0x10133440")] get
    {
      return new int();
    }
    [Token(Token = "0x60060FC"), Address(RVA = "0x133450", Offset = "0x132850", VA = "0x10133450")] set
    {
    }
  }

  [Token(Token = "0x1700099A")]
  [AttributeAttribute(Name = "ProtoMemberAttribute", RVA = "0x83510", Offset = "0x82910")]
  [AttributeAttribute(Name = "DefaultValueAttribute", RVA = "0x83510", Offset = "0x82910")]
  public int Id
  {
    [Token(Token = "0x60060FD"), Address(RVA = "0x18B7E0", Offset = "0x18ABE0", VA = "0x1018B7E0")] get
    {
      return new int();
    }
    [Token(Token = "0x60060FE"), Address(RVA = "0x1635A0", Offset = "0x1629A0", VA = "0x101635A0")] set
    {
    }
  }

  [Token(Token = "0x60060FF")]
  [Address(RVA = "0x793090", Offset = "0x792490", VA = "0x10793090", Slot = "4")]
  private IExtension ProtoBuf\u002EIExtensible\u002EGetExtensionObject(bool createIfMissing)
  {
    return (IExtension) null;
  }
}
```
---

# 备注：进入战斗 复盘（2026-08-22 完成）

> 状态：**战斗已能稳定进入**（多次重启均成功）。以下是打通"进入战斗"全过程的复盘。

## 成果
- 玩家能正常进入 copy 4 剧情战斗：copy.StartBase → 服务端回包 → PVEStartData..ctor → _getStartData 成功 → initBattleFrame → LoadingTick 循环运行。
- 服务端日志证实战斗全流程跑通：copy.StartBase / copy.AttackBase / copy.PassBase / copy.QuitBase / guide.PlotReward / chat.GetBarrageById 等。
- 修复后多次重启均能正常进入战斗（可复现）。

## 根因一：服务端 CopyMission 编码 bug（MissionNode 空引用）
- TStartBaseRet.CopyMission（字段 23）在服务端编码为 WriteVarint(0xB8); WriteVarint(0)。
-  xB8 = 字段 23 + wire type 0（varint）。所以这编码的是**一个元素=0**，即 copyMissionId = [0]，**不是空数组**。
- 客户端按 copyMissionId=[0] 去 config_mission 查 mission 0 → 不存在 → DictMission=null → **MissionNode 空引用**（玩家看到的弹窗"进入战斗加载时的空指针异常来自MissionNode"）。
- **修复**：EncodeStartBaseRet 改为发 [101, 102, 103]（config_mission 里存在的任务链，B8 01 65 B8 01 66 B8 01 67）。

## 根因二：bugly 崩溃处理器杀进程
- 
ew_sdk.dll（内含腾讯 Bugly）的崩溃处理器在战斗加载时**竞态触发**，其终结器  x468FF 无条件 exit(0) 杀进程 → 表现为"战斗加载必崩"。
- 崩溃链：
ew_sdk+0x468FF → _invalid_parameter_noinfo/exit → ExitProcess。
-  x468FF 两条分支（回调非空/为空）最终都 exit(0)；我们的环境中回调 [esi+0x80] 为 NULL，所以走空分支。
- **修复**：把 
ew_sdk.dll RVA  x468FF 入口第一个字节 patch 成  xC3（
et）→ bugly 终结器整体变成 no-op，即使触发也杀不掉进程。
- 顺带修复： x537D0 格式串 %→\0（见下）。

## 根因三（防御性）：bugly 格式化崩溃
- 
ew_sdk.dll 用 _vsnwprintf_s 格式化上报字符串，格式串  x537D0 是孤立 %（旧 MSVC CRT 当字面量；现代 UCRT 视为非法 → _invalid_parameter_noinfo → abort）。
- 由于 0x468FF 已 no-op，此路径不再执行；但防御性保留 patch： x537D0 的 %(0x25) → \0(0x00)。

## 其他关键改动
- EncodeStartBaseRet 补发：
  - 字段 5 EnemyFleet = realFleetId（copy 4 = 200401），供 BattleStartData.enemyFleetId。
  - 字段 24 EnemyFleets = FleetId 907 + 敌舰 71。
  - 玩家/敌舰 Attr 补发 Hit(19) / Dodge(20)（__IsHit 依赖 hit-dodge）。
- 新增 copy.AttackBase / copy.QuitBase 处理器（回环客户端数据）。
- 服务端 C2S/S2C 全量 hex 日志。
- 诊断钩子：SetUnhandledExceptionFilter IAT 抑制、new_sdk exit IAT 日志等。

## 重要认知
- copy 4 只有一个敌人（敌舰 71，Boss，
pc_boss_a01，hp=9999999，attack=1，defense=0，level=1，hit=100，dodge=0，ship_info_id=9051021）。
- config_copy 里所有 copy 的 mission_id 都是 []（客户端本地数据空），任务由服务端在 TStartBaseRet.CopyMission 下发。
- config_fleet[907] 的 copy_attacheds=[908,909,910] **不是附加舰队**（用户纠正，勿据此展开）。
- HpCoefficient=100 亿（PlayerAccountFactory.ln）是 **HP 比例**（防浮点转整数精度丢失），实际 HP 由配置决定。

## 未解决（另见 docs/research/battle/attack-miss.md）
- 进入战斗后攻击显示 MISS、无伤害。__IsHit(100,0)=true，伤害疑似=0。详见 docs/research/battle/attack-miss.md。
