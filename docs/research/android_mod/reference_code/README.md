# reference_code（参考实现，不是可直接构建的工程）

本目录只放我们为安卓端启动器写的**纯源码/脚本/布局 XML**，用于说明实现思路，便于上游参考或后续用 C# 重写。

**重要：这些代码不能直接参与上游 CI 构建。**

- `java_plugin/`：运行在启动器 `classes2.dex` 中的 Java 注入层（Mod 管理、热更版本发布、assetmap 对齐、存档导入导出、UI 注入、保活等）；
- `ui_layouts/`：主界面/管理器静态布局 XML 与按钮、卡片 drawable；
- `build_scripts/`：assetmap 重算、dex 编译、APK 重组与签名等 Python 脚本。

它们依赖原版启动器 APK（Xamarin 壳 + Xamarin 的 classes.dex）与本地 Android SDK/JDK，上游要吸收这些能力，建议按 `src/BlueOath.Android` 的 C# 工程重写，交互与机制可参考同级 6 份文档。

本目录不包含任何游戏本体、APK/BRK 打包物、数据库、图片、音频、存档或签名私钥。
