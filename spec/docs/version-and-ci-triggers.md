# 版本号更新机制与 CI 触发机制

## 1) 启动器版本号更新机制

启动器版本号由 `src/BlueOath.Launcher.Wpf` 的 MSBuild 目标按需管理：

- 版本文件：`src/BlueOath.Launcher.Wpf/version.txt`
- 递增目标：`IncrementLauncherVersion`（仅由发布器按需显式调用）
- 生成目标：`GenerateVersion`
- 输出常量：`src/BlueOath.Launcher.Wpf/VersionInfo.g.cs` 的 `VersionInfo.Version`

普通构建流程如下：

1. 读取 `version.txt`，例如当前 `1.0.15`
2. 用当前值生成 `VersionInfo.g.cs`
3. 将当前值设置为程序集版本
4. 不修改 `version.txt`

正式发版需要递增版本时，给发布器显式传入参数：

```powershell
dotnet run --project src\BlueOath.Publisher\BlueOath.Publisher.csproj -- --increment-version --output "D:\tmp\release\BlueOath-Release" --configuration Release
```

发布器先单独调用一次 `IncrementLauncherVersion`，将修订号递增一次并写回 `version.txt`，随后执行普通发布；`GenerateVersion` 使用新版本生成代码和程序集信息。递增目标不挂在常规构建链上，避免带 RID 的多阶段构建重复递增。

### 关键说明

- `dotnet build`、`dotnet test` 和不带 `--increment-version` 的发布均不会更改版本号。
- `--increment-version` 每调用一次就递增一次，发版失败后重试时不要重复传入，除非确实需要再次升版。
- `version.txt` 是唯一版本源；`VersionInfo.g.cs` 是供 C# 代码读取的生成文件。

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

