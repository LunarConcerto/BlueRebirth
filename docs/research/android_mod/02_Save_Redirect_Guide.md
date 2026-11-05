# 02 免 Root 存档重定向与导入原理

本文说明安卓端如何在没有 root 的情况下导出、导入服务端存档，并把外部 profiles.db 换进本地服务端。

## 1. 存档在哪里

- 服务端存档：启动器 App 私有目录
      /data/user/0/com.blueoath.server/files/bo-data/profiles.db
- 公共导出目录：
      /sdcard/BlueRebirth/Saves/bo-data/profiles.db

客户端自己的账号缓存不在这里，客户端只是登录到本地服务端；换服务端存档后客户端需要清一次数据或刷新大厅，原因见第 5 节。

## 2. 为什么不需要 Root

本地服务端与 Java 插件运行在同一个 App（com.blueoath.server）中，服务端读写 profiles.db 时使用的是 App 自己的私有目录，天然有权限；导入导出只是在这个私有目录与公共 Saves 目录之间复制文件，公共目录通过“所有文件访问权限”（MANAGE_EXTERNAL_STORAGE）即可读写，不需要 root。

## 3. 启动时导入流程

菜单点“导入存档”后：

1. SaveSync.beginImport() 写入导入标记；
2. 从 /sdcard/BlueRebirth/Saves/bo-data/profiles.db 复制到私有 import-staging；
3. 启动器重启进程；
4. 服务端启动前，ModLoader/SaveSync 检测到标记：
   - 备份当前 profiles.db；
   - 用 staging 文件替换 bo-data/profiles.db；
   - 记录“存档导入成功”日志；
   - 写入 import-done 标记（供 UI 弹清数据引导）；
5. 服务端启动后读取新存档；客户端下次登录即为新账号。

相关代码：SaveSync.java、SaveSyncProvider.java、SetupActivity.java（导入入口）。

## 4. 导出流程

1. 服务端点“导出存档”（或退出时自动导出）；
2. SaveSync.exportAsync() 把 bo-data 下的 profiles.db 及附属文件复制到 /sdcard/BlueRebirth/Saves/bo-data；
3. 若外部已有同名文件，按时间/保护策略处理，避免自动导出覆盖用户刚放入的导入文件；
4. 日志写入 /sdcard/BlueRebirth/Logs/mods.log。

## 5. 客户端侧注意事项

客户端的“账号”来自登录响应，登录后会缓存本地状态。仅替换服务端 profiles.db 时：

- 客户端可能仍显示旧账号（缓存/会话未刷新）；
- 正确做法：正常退出大厅，或进入一次基地再返回；多数情况下大厅 UI 会刷新；
- 若仍不刷新：清空客户端数据（系统设置 → 应用 → 苍蓝誓约 → 存储 → 清除数据），再启动游戏重新登录；
- 清数据不会删除存档（存档在启动器/服务端侧），只会让客户端重新拉取资源。

## 6. 安全与备份

- 导入前必须备份原 profiles.db；SaveSync 会自动备份为 profiles.db.before-import；
- 导入文件先写 staging，校验通过才替换，避免半截文件损坏存档；
- 服务端运行时禁止手工覆盖私有目录文件；
- 不要用 adb shell pm clear com.blueoath.server：会把 App 私有目录与外部资源一起清掉，等同于重置整个启动器。

## 7. 测试步骤（回归用）

1. 启动器 → 存档管理 → 导出当前存档；
2. 用 adb 或文件管理器确认 /sdcard/BlueRebirth/Saves/bo-data/profiles.db 存在且可拉回；
3. 把测试存档 profiles.db 放入该目录（覆盖）；
4. 启动器 → 存档管理 → 导入存档；
5. 进度完成、启动器自动重启后，清空客户端数据；
6. 启动游戏，登录后进入大厅；若显示旧号，正常退出大厅或进一次基地再返回；
7. 确认账号名/等级与测试存档一致。

## 8. 代码入口

| 功能 | 类/方法 |
|---|---|
| 导入标记与替换 | SaveSync.beginImport / consumeImport |
| 导出 | SaveSync.exportAsync |
| ContentProvider 供外部文件选择 | SaveSyncProvider |
| 导入/导出 UI | SetupActivity（br_mode=saves） |
| 日志 | Logx / mods.log |
