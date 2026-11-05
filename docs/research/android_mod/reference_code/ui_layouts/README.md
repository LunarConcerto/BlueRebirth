# ui_layouts

启动器界面相关 XML（原样归档，仅作参考）。

- `home_ui.xml`：主界面静态骨架（状态卡、开始/安装按钮、Mod/存档卡片、底部操作区）；
- `ui_layout.xml`：旧版管理器布局（授权/刷新/导入/导出/还原/打开启动器）；
- `drawable/`：按钮、卡片、背景、通知图标的 shape/selector。

最终版本的管理器页面由 SetupActivity 程序化生成（竖屏适配与卡片留白），XML 用于说明视觉结构。
