# build_scripts

逆向构建/打包脚本（Python，纯文本，仅作参考）。

| 脚本 | 用途 |
|---|---|
| build_dex.py | 用 javac + d8 把 java_plugin 源码编译成 classes2.dex |
| build_apk.py | 以原版启动器 APK 为底，替换 classes.dex/classes2.dex/assets 后重组未签名 APK |
| build_apk_ui_redo.py | 在豆包 UI 版 APK 基础上替换 classes2.dex 与 ui_layout.xml |
| make_uncompressed_assetmaps.py | 把 assetmap 以未压缩 UnityFS 重存，保留可原地改写的版本行 |
| rebuild_mod_assetmaps.py | 按 Mod 文件重算 assetmap 指纹行 |
| resave_assetmap_original.py | 原始 assetmap 重存工具 |
| patch_assetmap_dynamic.py | 动态版本对齐补丁的生成脚本 |
| final_assetmap_lz4.py | 早期 LZ4 方案留档（已被未压缩方案替代） |

依赖：Python 3、UnityPy（assetmap 处理）、JDK 17 + d8（dex）、uber-apk-signer（签名）。
上游若要复用这些能力，建议把 assetmap 算法与版本发布逻辑移植进 C# 服务端/发布器，而不是在 CI 里运行这些逆向脚本。
