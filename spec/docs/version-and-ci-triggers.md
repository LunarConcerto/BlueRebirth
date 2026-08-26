# 版本号更新机制与 CI 触发机制

## 1) 启动器版本号更新机制

启动器版本号由 `src/BlueOath.Launcher.Wpf` 的 MSBuild 目标自动管理：

- 版本文件：`src/BlueOath.Launcher.Wpf/version.txt`
- 生成目标：`src/BlueOath.Launcher.Wpf/BlueOath.Launcher.Wpf.csproj` 的 `GenerateVersion`
- 输出常量：`src/BlueOath.Launcher.Wpf/VersionInfo.g.cs` 的 `VersionInfo.Version`

更新流程如下（每次 `BeforeBuild`）：

1. 读取 `version.txt`，例如当前 `1.0.15`
2. 按 `.` 拆分为 `Major.Minor.Build`
3. `Build` 自增 `+1`
4. 将新值写回 `version.txt`（副作用）
5. 用新值生成 `VersionInfo.g.cs`
6. 运行时与启动器 UI 显示为自增后的版本

### 关键说明

- 该机制是“自增型”，只要构建就会改文件，适合本地构建场景，但会产生未提交文件变更。
- 需要人工固定版本时，建议直接先编辑 `version.txt` 到目标基准版本，再触发一次构建。

## 2) CI 触发机制

CI 工作流配置文件：`.github/workflows/ci.yml`

- 触发器（`on`）：
  - `push`：`master` 分支、`v*` 标签
  - `workflow_dispatch`：手动触发
- 运行内容：
  - 安装 .NET 8 SDK
  - `dotnet restore BlueOath.Local.sln`
  - `dotnet build BlueOath.Local.sln`（仅 Debug）
  - `dotnet test BlueOath.Local.sln`

发布作业（publish）：
- 仅在 `v*` 标签或手动触发时执行；
- 自动运行 `publish-release.bat`；
- 校验 `launcher-settings.json` 与 `BlueOath.Launcher.Wpf.exe` 存在性。

