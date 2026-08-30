# 文档中心

某游戏本地复原项目的全部文档索引。按「总体规划 / 开发发布 / 逆向研究 / 生成知识库」四类组织。

## 总体规划

| 文档 | 说明 |
| --- | --- |
| [项目概述](project-overview.md) | 项目背景、客户端版本差异与项目目的 |
| [Roadmap](roadmap.zh-CN.md) | 分阶段目标（M1–M7）与完成门槛 |
| [复盘总结](retrospective.md) | 开发复盘：目标状态、服务器架构、逆向知识库与方法论教训 |

## 开发与发布

> 入口：[development/README.md](development/README.md)

| 文档 | 说明 |
| --- | --- |
| [代码规范](development/code-conventions.md) | `BlueOath.Server` 分层、命名、日志与构建约定 |
| [协议全覆盖实现报告](development/protocol-coverage.md) | 423 个协议路由的实现覆盖与模块清单 |
| [启动器版本号、发布与自动更新](development/launcher-release-and-update.md) | 版本号管理、CI 触发、发布流水线与自动更新方案 |

## 逆向研究

> 按「战斗系统 / 海域玩法 / 网络传输」分类，均为逆向调查记录。

### 战斗系统（`research/battle/`）

| 文档 | 说明 |
| --- | --- |
| [战斗系统](research/battle/battle-system.md) | `StageSimpleBattle`/`PVEStartData`、进入战斗复盘、TStartBaseRet 结构 |
| [攻击 MISS](research/battle/attack-miss.md) | 伤害公式 `damageFac=0` 导致的 MISS 排查与修复 |
| [自律自动战斗](research/battle/autobattle.md) | AutoBattle 机制、`auto 1 False` 日志定位 |

### 海域玩法（`research/sea/`）

| 文档 | 说明 |
| --- | --- |
| [海域战斗](research/sea/sea-battle.md) | 海域侦察进入战斗的卡加载调查与协议修复 |
| [海域索敌机制](research/sea/sea-search.md) | 索敌大地图出生点 / 迷雾 / 巡逻机制 |
| [battlefield_info 机制](research/sea/battlefield-info.md) | 战场落位工具（EBPKit）与敌舰队坐标错位根因 |
| [索敌进战斗移动清理调查](research/sea/search-battle-transition.md) | 索敌→战斗过渡的移动/巡航清理逻辑 |

### 网络传输（`research/`）

| 文档 | 说明 |
| --- | --- |
| [JP 传输观察](research/transport.md) | TLS 传输、UnityTLS 证书校验边界与本地信任补丁 |

## 生成知识库（可重复生成）

> 由 `BlueOath.Tools` 只读分析生成，均可重新生成。目录版本以各自 README 为准。

| 目录 | 内容 |
| --- | --- |
| [protocol-catalog](protocol-catalog/README.zh-CN.md) | 协议与事件目录（`catalog.json`、`.proto` 草案、CSV） |
| [config-catalog](config-catalog/README.zh-CN.md) | 客户端配置目录（解码规则、差异摘要、工具链） |
| [il2cpp-catalog](il2cpp-catalog/README.zh-CN.md) | IL2CPP Metadata Registration 候选 |
| [lua-catalog](lua-catalog/README.md) | 日服 Lua 反编译源码与字节码格式结论 |

## 重新生成命令

```powershell
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-il2cpp
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-wire
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-protocol
dotnet run --project src\BlueOath.Tools\BlueOath.Tools.csproj -- --analyze-config
```
