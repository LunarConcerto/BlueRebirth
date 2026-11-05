# Android Mod 与启动器逆向改造 —— 技术总览

本目录记录在 **不修改游戏客户端 APK、不 Root、不依赖 PC** 的前提下，为已关服的《苍蓝誓约》安卓客户端额外实现的一层启动器与 Mod 运行环境。

目录只包含文档与源码参考，不包含任何游戏本体、APK/BRK 打包物、数据库、图片或音频资源，可直接作为上游仓库 docs/research 下的资料并入。

## 1. 背景与目标

- 游戏客户端为 Unity IL2CPP 的安卓包（com.zephyrus.clsy.gp），内容与配置通过服务端热更分发；
- 官方服务器已关闭，玩家需要本地离线环境才能继续游戏；
- 上游 BlueRebirth 仓库提供 C# 本地服务端与 PC 启动器；本目录描述的是安卓端独立启动器方案（com.blueoath.server）的逆向与改造经验；
- 目标：不碰客户端安装包本体，通过“本地服务端 + 外置资源覆盖 + 运行时注入”实现汉化、语音、活动内容、Mod 扩展与存档迁移。

## 2. 总体架构

    +--------------------------+         loopback          +----------------------------+
    |  启动器 App               |  127.0.0.1:19090/19191   |  游戏客户端 APK             |
    |  com.blueoath.server     | <----------------------> |  com.zephyrus.clsy.gp      |
    |  - Xamarin C# 壳          |  19193 明文热更下载       |                            |
    |  - classes2.dex Java 插件 |                          |                            |
    |  - 本地服务端进程         |                          |                            |
    +--------------------------+                          +----------------------------+
                |
                | 读写
                v
    /sdcard/BlueRebirth/Mods/           外置 Mod（纯数据 + Lua）
    /sdcard/BlueRebirth/Saves/          profiles.db 导入导出
    /sdcard/Android/data/com.blueoath.server/files/   服务端热更目录（bundle/config/wwise/assetmap）

核心思路是三点：

1. 服务端热更目录作为唯一内容源：客户端更新时只拉取与 assetmap 有差异的文件，因此把 Mod 文件覆盖到热更目录并同步更新 assetmap 即可生效，无需改客户端 APK。
2. Java 插件运行在启动器进程里：负责 Mod 扫描/应用、热更版本发布、assetmap 版本对齐、存档导入导出、UI 注入与防杀后台。它通过修改 classes2.dex 注入到既有启动器，不触碰游戏进程。
3. 全部路径走公共存储：Mod、存档、日志位于 /sdcard/BlueRebirth，便于玩家自行替换，无需 root。

## 3. 关键机制索引

| 机制 | 说明 | 文档 |
|---|---|---|
| 外置 Mod 加载 | mod.json/main.lua、loadOrder、文件覆盖、Lua API | 01_Mod_Loader_Mechanism.md |
| Assetmap 动态对齐 | 版本行原地改写，解决 0.00MB 更新死循环 | 01_Mod_Loader_Mechanism.md |
| 存档重定向 | 服务端 profiles.db 与外部 Saves 目录互导 | 02_Save_Redirect_Guide.md |
| UI 重构 | 主界面/Mod 页/存档页与一次性弹窗逻辑 | 03_UI_Redesign_Specs.md |
| 测试闭环 | 五关实机验收与黑屏/缓存避坑 | 04_Test_Checklist.md |
| Mod 开发 | 给小白/其他 AI 的开发模板 | 05_Android_Mod_Dev_Guide.md |

## 4. 兼容基线与版本

- 客户端：日服 1.4.90 安装包，内置脚本版本 1.4.140；
- 内容版本：随启动器发布版本递增（实测 1.4.140 → 1.4.145 → 1.4.146 → 1.4.147）；
- 热更资源以 assetmap 为清单；每个发布版本必须保证客户端期望版本、服务端宣告版本、assetmap 第一行版本三者一致；
- 只在 Android 9 模拟器（LDPlayer，720x1280 / 1280x720）与部分真机验证过，其余机型需回归。

## 5. 实机验收结论（摘要）

- 仅汉化 Mod：客户端仅增量拉取约 11.8MB，进入大厅汉化生效，无 0.00MB 循环；
- 汉化 + 语音 + 活动三 Mod 叠加：增量约 1.51MB，春节活动章节 7/7 LIVE，语音库替换生效；
- 关闭活动 Mod：版本继续递增，游戏不崩溃，汉化保留；
- 一键还原：确认后还原并结束启动器进程，重开主界面只弹一次清数据提示，之后不再弹；
- 存档导入：导入后需清空客户端数据，正常退出大厅或进一次基地后账号 UI 刷新；
- 注意事项：模拟器低内存首次启动可能黑屏，先等 60 秒再重启模拟器，不要反复强杀。

## 6. 目录与使用方式

    android_mod/
    ├── README.md
    ├── 01_Mod_Loader_Mechanism.md
    ├── 02_Save_Redirect_Guide.md
    ├── 03_UI_Redesign_Specs.md
    ├── 04_Test_Checklist.md
    ├── 05_Android_Mod_Dev_Guide.md
    └── reference_code/
        ├── java_plugin/        Java 注入层源码（mods / savesync）
        ├── ui_layouts/         主界面、Mod 页、存档页 XML 与 drawable
        └── build_scripts/      assetmap 处理、dex 打包、APK 重签脚本

reference_code 为参考实现，不是可直接参与上游 CI 的工程源码：它依赖原版启动器 APK 的 classes.dex 与 Xamarin 壳，编译方式见 build_scripts/README.md。上游若要吸收，建议按 src/BlueOath.Android 的 C# 工程重写，思路可完全复用本目录文档。

## 7. 红线与合规

- 不提交游戏客户端、APK、BRK、assetmap 原始资源、数据库、图片、音频、存档或签名私钥；
- 文档中的路径、哈希、指纹只用于说明机制，不包含可直接还原游戏资源的完整数据；
- 本项目遵循上游 GPL-3.0；引用或改写本目录内容请保留出处与许可声明。
