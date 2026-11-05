# java_plugin

启动器 Java 注入层源码（原样归档，仅作参考）。

- `mods/`：Mod 扫描/应用/还原、Lua 运行时、版本发布、assetmap 动态对齐、UI 注入、进度遮罩、保活服务等；
- `savesync/`：存档导入导出、ContentProvider、Mod 管理器 Activity。

编译方式：将本目录源码与 Android stubs 一起由 `build_scripts/build_dex.py` 编译为 classes2.dex，再替换进启动器 APK。上游 CI 不包含这一步，建议用 C# 重写对应能力。
