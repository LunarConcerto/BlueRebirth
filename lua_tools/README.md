# lua_tools — 反编译 Lua 源码

本目录存放某游戏客户端的**反编译 Lua 源码**（游戏逻辑近乎明文，Lua 热更部分）。包含国服与日服两套代码，用于协议逆向、逻辑对照与 Mod 开发。

## 目录结构

| 目录 | 客户端 | 文件数 | 说明 |
| --- | --- | --- | --- |
| `BlueoathLua/` | 国服 1.5.20 | 1397 个 `.lua` | 国服反编译源码，含 `data/ game/ logic/ UI/ util/` 等 |
| `BlueoathLuaJP/` | 日服 1.4.0 | 1526 个 `.lua` | 日服反编译源码（全量），含 `common/ config/ net/ stage/ ui/ util/ xlua/` 等 |

> 日服与国服是同一款游戏、逻辑基本一致；日服多 129 个国服没有的文件（crusade / assistfleet / plotcopymain 等玩法）。

## 如何生成

这些源码由仓库内脚本自动反编译产出，可重复生成：

```powershell
# 1. 解包 + 归一化字节码 header（日服字节码为标准 Lua 5.3.5，仅 header 两处小改）
python tools/extract-normalize.py

# 2. 用 unluac 批量反编译
python tools/decompile-all.py
```

详细原理与字节码格式结论见 [docs/lua-catalog/README.md](../docs/lua-catalog/README.md)。

## 关键文件导航

| 文件 | 角色 |
| --- | --- |
| `BlueoathLuaJP/util/platformmanager.lua` | SDK 封装：`getServiceList` / `login` / 服务器列表解析 |
| `BlueoathLuaJP/logic/loginlogic.lua` | 登录逻辑：`ConnectServer` / `SendLogin` |
| `BlueoathLuaJP/socket_net.lua` | 网络层：`Connect` / `Send` / protobuf 序列化 |
| `BlueoathLuaJP/net/protobuflua/*_pb.lua` | **protobuf 消息字段号定义**（服务端编解码字段号的主要来源） |
| `BlueoathLuaJP/genluaapi/*.lua` | xLua 生成的 C# 绑定（`babeltime.*wrap.lua`） |

## 相关文档

- 协议字段号、登录流程分析：见 [docs/lua-catalog/README.md](../docs/lua-catalog/README.md)
- 逆向研究资料：见 [docs/research/](../docs/research/)
- 反编译 / 提取脚本：`tools/extract-normalize.py`、`tools/decompile-all.py`、`tools/lua-strings.py`
