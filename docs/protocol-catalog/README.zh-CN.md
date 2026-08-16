# 苍蓝誓约协议与事件目录

> 由只读分析器生成，目录版本 `1.2`。生成时间 `2026-08-13T04:13:05.9947679+00:00`。

## 证据等级

- `confirmed`：已在本地回环捕获或 SDK 回调日志中直接观察。
- `inferred`：来自 IL2CPP 类型字段、成对请求/响应名称或强静态证据。
- `candidate`：仅发现独立字符串，必须继续确认调用点或运行时行为。

## 当前覆盖

- `jp-1.4.0`：73 个消息候选，69 个具有类型级字段证据，1351 个网络相关符号。
- `cn-1.5.20`：73 个消息候选，69 个具有类型级字段证据，1348 个网络相关符号。
- 两服共有消息：73；日服独有：0；国服独有：0。
- 已确认 SDK 事件：4；已确认 HTTP 端点：6。

## 登录相关消息与字段

### jp-1.4.0

- `TArgCreateUser`（C2S/request）：`_Uname: string = 1`；`_Class: int = 2`；`extensionObject: ProtoBuf.IExtension`；配对 `未确认`；置信度 85%。
- `TArgLogin`（C2S/request）：`_Pid: string = 1`；`_Timestamp: int = 2`；`_OpenDateTime: string = 3`；`_Hash: string = 4`；`_SampleInfo: pb.TSampleInfo = 5`；`extensionObject: ProtoBuf.IExtension`；配对 `TRetLogin`；置信度 85%。
- `TArgUniteLogin`（C2S/request）：`_Uname: string = 1`；`extensionObject: ProtoBuf.IExtension`；配对 `未确认`；置信度 85%。
- `TArgUserLogin`（C2S/request）：`_Uid: ulong = 1`；`extensionObject: ProtoBuf.IExtension`；配对 `TRetUserLogin`；置信度 85%。
- `TRetGetSvrTime`（S2C/response）：`_NowTime: int = 1`；`_SvrStartTime: int = 2`；`extensionObject: ProtoBuf.IExtension`；配对 `未确认`；置信度 85%。
- `TRetLogin`（S2C/response）：`_Ret: string = 1`；`_FeignRoleId: string = 2`；`extensionObject: ProtoBuf.IExtension`；配对 `TArgLogin`；置信度 85%。
- `TRetUserLogin`（S2C/response）：`_Ret: string = 1`；`_BanMsg: string = 2`；`_BanTime: int = 3`；`extensionObject: ProtoBuf.IExtension`；配对 `TArgUserLogin`；置信度 85%。

### cn-1.5.20

- `TArgCreateUser`（C2S/request）：`_Uname: string = 1`；`_Class: int = 2`；`extensionObject: ProtoBuf.IExtension`；配对 `未确认`；置信度 85%。
- `TArgLogin`（C2S/request）：`_Pid: string = 1`；`_Timestamp: int = 2`；`_OpenDateTime: string = 3`；`_Hash: string = 4`；`_SampleInfo: pb.TSampleInfo = 5`；`extensionObject: ProtoBuf.IExtension`；配对 `TRetLogin`；置信度 85%。
- `TArgUniteLogin`（C2S/request）：`_Uname: string = 1`；`extensionObject: ProtoBuf.IExtension`；配对 `未确认`；置信度 85%。
- `TArgUserLogin`（C2S/request）：`_Uid: ulong = 1`；`extensionObject: ProtoBuf.IExtension`；配对 `TRetUserLogin`；置信度 85%。
- `TRetGetSvrTime`（S2C/response）：`_NowTime: int = 1`；`_SvrStartTime: int = 2`；`extensionObject: ProtoBuf.IExtension`；配对 `未确认`；置信度 85%。
- `TRetLogin`（S2C/response）：`_Ret: string = 1`；`_FeignRoleId: string = 2`；`extensionObject: ProtoBuf.IExtension`；配对 `TArgLogin`；置信度 85%。
- `TRetUserLogin`（S2C/response）：`_Ret: string = 1`；`_BanMsg: string = 2`；`_BanTime: int = 3`；`extensionObject: ProtoBuf.IExtension`；配对 `TArgUserLogin`；置信度 85%。

## 生成物用途

- `catalog.json`：完整机器可读知识库，后续代码生成和差异检查的唯一输入。
- `sdk-events.csv`：SDK 事件编号、触发点和参数。
- `message-candidates.csv`：消息方向、请求/响应配对、实际字段和低置信参数候选。
- `adapter-template.json`：版本适配器配置骨架，集中保存消息 ID、帧、压缩、加密和能力开关。

## 尚未确认

- 消息数字 ID 与类型名称的映射。
- protobuf 字段编号、字段线型和可选/必需规则；字段 CLR/IL2CPP 类型已解析。
- 游戏连接的帧头、序号、压缩和加密流程。
- SDK 事件 1007 的 `data` 完整结构及消费函数。

以上项目不会再通过反复修改响应猜测，而应通过类型布局、调用点交叉引用和有目标的单次运行捕获补齐。每次确认后写回目录，再由版本适配器消费。

## 重新生成

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-protocol
```
