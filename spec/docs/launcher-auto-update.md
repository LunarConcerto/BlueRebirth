# 启动器自动更新方案（Issue#1）

## 目标

- 启动器启动时自动检查最新版本信息；
- 与本地版本对比，检测到新版本时提示并允许更新；
- 更新时自动下载安装包、执行替换脚本、退出旧进程、完成重启；
- 不依赖外部安装器。

## 实现位置

- 自动更新服务：`src/BlueOath.Launcher.Wpf/Services/LauncherUpdateService.cs`
- 启动时触发：`src/BlueOath.Launcher.Wpf/MainWindow.xaml.cs`
- 配置读取：`src/BlueOath.Launcher.Wpf/Models/SettingsConfig.cs`
- 默认配置：`src/BlueOath.Launcher.Wpf/Services/SettingsService.cs`

## 配置字段（`launcher-settings.json`）

- `updateManifestUrl`：版本清单地址；当前 Release CI 使用 GitHub Releases API，后续可切到国内镜像站
- `autoUpdateEnabled`：是否开启自动更新检测

## 清单文件格式

清单使用 JSON，字段如下；启动器同时兼容自定义清单和 GitHub `releases/latest` API 响应：

```json
{
  "version": "1.0.20",
  "packageUrl": "https://github.com/BlueRebirth/BlueRebirth/releases/download/v1.0.20/BlueOath.Launcher.Wpf.zip",
  "releaseNotes": "修复启动异常、优化更新流程",
  "confidenceHint": "建议在无游戏运行时更新",
  "executableName": "BlueOath.Launcher.Wpf.exe"
}
```

## 建议镜像策略（国内访问）

1. 当前可直接使用 GitHub：
   - `updateManifestUrl` 指向 GitHub Releases API：`https://api.github.com/repos/BlueRebirth/BlueRebirth/releases/latest`
   - 启动器自动从最新 Release 的 ZIP asset 中读取 `browser_download_url`；
2. 如后续需要国内镜像站，仅需修改清单地址与下载地址即可，无需改代码；
3. 建议统一通过同一个域名承载清单和安装包，减少域名切换维护成本。

当前代码仅在客户端层读取 `updateManifestUrl`，该值在 `launcher-settings.json` 中显式配置后生效；清单内可灵活切换下载源。

## 兼容性与执行逻辑

1. 启动时读取版本清单，提取 `version`；
2. 与 `VersionInfo.Version` 做 `System.Version` 比较；
3. 发现更新则弹窗确认；
4. 下载更新压缩包到 `%TEMP%\BlueOathLauncherUpdate`；
5. 写入一次性 PowerShell 脚本并携带参数：
   - 根目录 `rootDir`
   - 压缩包路径 `zipPath`
   - 启动器文件名 `exeName`
   - 当前启动器进程 id `launcherPid`
6. 启动脚本后关闭当前启动器：
   - 脚本先等待旧进程结束；
   - 解压到临时目录；
   - 复制新文件到根目录；
   - 清理临时文件；
   - 重启新启动器。

> 说明：当前策略是“覆盖式更新”，不会删除新包里不存在的旧文件。若需要全量清理策略，请在发布流程明确目录约定后再引入。

## 运行时注意

- 建议发布新版本时把启动器目录打包为 zip 根目录直接包含 `BlueOath.Launcher.Wpf.exe` 等目标文件；
- 保持 `executableName` 与实际可执行文件名一致；
- 当清单不可访问或解析失败时，启动器静默跳过更新，不影响正常启动流程。

## 推荐 launcher-settings 配置示例

```json
{
  "updateManifestUrl": "https://api.github.com/repos/BlueRebirth/BlueRebirth/releases/latest",
  "autoUpdateEnabled": true
}
```
