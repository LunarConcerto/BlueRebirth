# 05 安卓 Mod 开发指南（小白/AI 版）

面向想自己做 Mod 的玩家与代写 AI。所有示例均为纯文本/Lua，不涉及修改客户端 APK。

## 1. 五分钟做一个 Mod

1. 新建文件夹，必须以 .mod 结尾，如 我的测试.mod；
2. 里面放 mod.json 和 main.lua；
3. 要替换文件就建 files/ 子目录，按第 4 节放；
4. 整个文件夹放进手机 /sdcard/BlueRebirth/Mods/；
5. 打开 Mod 管理器 → 勾选 → 刷新并应用 → 看完须知 → 等 100% → 彻底关闭并重开启动器 → 开始游戏等更新完成。

## 2. 目录结构

    我的测试.mod/
    ├── mod.json
    ├── main.lua
    ├── README.md
    └── files/
        ├── bundle/config/xxx.db
        ├── bundle/compressed/config/xxx.db
        └── bundle/wwise/xxx.bnk

映射规则：files/ 里的内容对应服务端热更目录的根，例如 files/bundle/config/a.db 会覆盖热更目录的 bundle/config/a.db。

## 3. mod.json 字段

| 字段 | 必填 | 说明 |
|---|---|---|
| id | 建议 | 唯一标识，建议与文件夹同名 |
| name | 建议 | 管理器显示名 |
| version | 建议 | Mod 自身版本，仅显示 |
| entry | 必填 | 入口 Lua 文件，默认 main.lua |
| description | 可选 | 管理器显示的说明 |
| author | 可选 | 作者 |
| loadOrder | 可选 | 越小越先加载，越大越后加载覆盖；默认 100 |
| enabled | 可选 | 是否启用，默认 true |
| clientVersion | 改文件类必填 | 热更版本号，如 1.4.145；多 Mod 取最大值 |

## 4. main.lua 环境与 API

全局变量：

- __BLUEOATH_MOD_ROOT：Mod 根目录绝对路径；
- __blueoath_loadfile(rel)：加载 Mod 目录下另一个 Lua 文件；
- __blueoath_log(msg)：写日志；
- configManager.GetData(name)/GetDataById(name,id)：读写服务端配置表；
- __BLUEOATH_MOD_ENTRIES：已启用 Mod 的入口列表。

每个 Mod 的 mod 表：

- mod.info(msg)、mod.log(msg)；
- mod.copy(src,dst)：从 Mod 目录复制文件到热更目录；
- mod.write(relPath,text)：向热更目录写文本；
- mod.hot_dir()/mods_dir()/saves_dir()；
- on_bootstrap(state) 生命周期回调。

## 5. 示例一：改数值

    local orig = configManager.GetData
    configManager.GetData = function(name)
        local data = orig(name)
        if name == "config_ship_info" then
            local row = data[20130116]
            if row then row["attack"] = 9999 end
        end
        return data
    end

启动器会把修改过的行 diff 写回服务端配置 DB。

## 6. 示例二：替换文本/资源

把改好的文件放在：

    files/bundle/config/config_language.db
    files/bundle/compressed/config/config_language.db
    files/bundle/wwise/c_cl_ninghai_jp_bank.bnk

配置 db 的 jsonbytes 为 UTF-8 JSON 逐字节 XOR 0x55；修改后需同步 compressed 的 gzip 变体（level 6、mtime=0），并更新 assetmap 指纹（见 01 文档第 5 节）。

## 7. 打包与安装

- 把整个 .mod 文件夹压成 zip（解压后必须直接得到 .mod 文件夹，不能多套一层）；
- 发群/网盘，玩家解压到 /sdcard/BlueRebirth/Mods/；
- 管理器勾选 → 刷新并应用 → 必读须知 → 重启启动器 → 开始游戏。

## 8. 调试

| 现象 | 排查 |
|---|---|
| 管理器 0 个 Mod | 目录名、mod.json 位置、存储权限 |
| 应用后无效 | 是否等 100%、是否重启启动器、assetmap 是否更新 |
| Lua 报错 | 查看 BlueRebirth/Logs/mods.log 最新日志 |
| 游戏黑屏 | 等待 60 秒或重启模拟器，不要先怀疑 Mod |

## 9. 给 AI 的提示词模板

    你是 BlueRebirth 安卓启动器的 Mod 开发助手。请按以下规范输出可直接使用的 Mod：
    目录：我的Mod.mod/mod.json + main.lua（可选 files/）。
    mod.json 必填 entry、clientVersion（1.4.145）、enabled、loadOrder。
    Lua 环境：configManager.GetData/GetDataById；mod.copy/mod.write/mod.info；on_bootstrap(state)。
    要求：输出完整 mod.json 与 main.lua，代码加中文注释，不使用 os.execute/io.popen，不修改客户端 APK。
    我的需求：<在这里写>

## 10. 红线

- 不修改游戏客户端 APK，不 Root，不碰其他 App 数据；
- 不制作破坏存档、盗号、联网外挂类功能；
- 分享前自测一遍，并附说明与卸载方式。
