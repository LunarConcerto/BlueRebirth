# 启动器版本号、发布与自动更新（完整流水线）

> 本文档合并自原 `spec/docs/` 三篇（`launcher-release-workflow.md`、`launcher-auto-update.md`、`version-and-ci-triggers.md`），
> 覆盖「版本号管理 → CI 触发 → 发布启动器包 → 生成 launcher-settings → 发布文件校验 → 自动更新」的完整过程，避免更新文件遗漏。

## 1. 启动器版本号管理

启动器版本号由 `src/BlueOath.Launcher.Wpf` 的 MSBuild 目标按需管理：

- 版本文件：`src/BlueOath.Launcher.Wpf/version.txt`（**唯一版本源**）
- 递增目标：`IncrementLauncherVersion`（仅由发布器按需显式调用）
- 生成目标：`GenerateVersion`
- 输出常量：`src/BlueOath.Launcher.Wpf/VersionInfo.g.cs` 的 `VersionInfo.Version`（供 C# 代码读取的生成文件）

普通构建流程：

1. 读取 `version.txt`，例如当前 `1.0.15`；
2. 用当前值生成 `VersionInfo.g.cs`；
3. 将当前值设置为程序集版本；
4. **不修改** `version.txt`。

正式发版需要递增版本时，给发布器显式传入参数：

```powershell
dotnet run --project src\BlueOath.Publisher\BlueOath.Publisher.csproj -- --increment-version --output "D:\tmp\release\BlueOath-Release" --configuration Release
```

发布器先单独调用一次 `IncrementLauncherVersion`，将修订号递增一次并写回 `version.txt`，随后执行普通发布；`GenerateVersion` 使用新版本生成代码和程序集信息。递增目标不挂在常规构建链上，避免带 RID 的多阶段构建重复递增。

关键说明：

- `dotnet build`、`dotnet test` 和不带 `--increment-version` 的发布均不会更改版本号。
- `--increment-version` 每调用一次就递增一次，发版失败后重试时不要重复传入，除非确实需要再次升版。
- `version.txt` 是唯一版本源；`VersionInfo.g.cs` 是生成文件，不应手工编辑。

## 2. CI 触发机制

CI 工作流配置文件：`.github/workflows/ci.yml`

- **触发器（`on`）**：
  - `push`：`master` / `WakabaMutsumi` 分支和 `v*` 标签；当前没有文件路径过滤；
  - `pull_request`：全分支；
  - `workflow_dispatch`：手动触发。
- **build 作业**（`windows-latest`）：安装 .NET 8 SDK → `dotnet restore` → `dotnet build`（仅 Debug）→ `dotnet test`。
- **publish 作业**（`windows-2022`，需要 build 通过）：仅在 `master` 推送、`v*` 标签或手动触发时执行；
  直接运行 `BlueOath.Publisher`，并校验 `launcher-settings.json` 与 `BlueOath.Launcher.Wpf.exe` 存在性；
  将产物打包 zip 上传为 GitHub Release，并同步镜像到 Gitee（`asa233/blue-rebirth`）与 `launcher-update-release.json` 清单。

## 3. 发布流水线

### 3.1 相关文件与职责

- `src/BlueOath.Publisher/BlueOath.Publisher.csproj`
  - 调用发布器并在最终目录进行关键文件存在性校验（`launcher-settings.json` 与启动器 exe）。
- `src/BlueOath.Publisher/Program.cs`
  - 负责拼装 `release` 目录内容；
  - 负责生成默认 `launcher-settings.json`。
- `src/BlueOath.Launcher.Wpf/launcher-settings.json`
  - 配置模板，随项目打包时复制到输出目录。
- `src/BlueOath.Launcher.Wpf/BlueOath.Launcher.Wpf.csproj`
  - 标记 `launcher-settings.json` 为构建/发布必带内容。
- `docs/development/launcher-update-manifest.json`
  - 启动器远端版本清单示例与发布模板（或镜像站同结构文件）。

### 3.2 标准发布步骤

**版本与本地准备**

1. 确认 `src/BlueOath.Launcher.Wpf/version.txt` 的当前版本；需要升版时，在发布命令中加入 `--increment-version`，否则版本保持不变。
2. 确认仓库根目录下 `baseline.json`、原始配置文件、运行时文件准备就绪。
3. 检查 `autoUpdate` 配置策略是否已确定（默认关闭空值）：若发版后立即启用自动更新，请先准备 manifest 链接。

**执行发布脚本**

```powershell
dotnet run --project src\BlueOath.Publisher\BlueOath.Publisher.csproj -- --output "D:\tmp\release\BlueOath-Release" --configuration Release
```

- 默认输出：`release\BlueOath-Release`（可通过 `--output` 指定到固定目录便于后续打包）。
- 需要将修订号递增一次时，额外传入 `--increment-version`；普通构建和默认发布不会修改版本文件。

**脚本执行内含阶段**

1. 根目录 `dotnet restore` / `dotnet build -c Release --no-restore`；
2. 调用 `BlueOath.Publisher`：
   - 发布 server 与 launcher；
   - 复制 native + tools + baseline；
   - 打包并解压 python；
   - 生成 `launcher-settings.json`；
   - 生成启动脚本 `启动游戏.bat`；
3. 执行发布后校验：
   - `launcher-settings.json` 必须存在；
   - `BlueOath.Launcher.Wpf.exe` 必须存在；
4. 任何关键文件缺失即退出失败。

**产物结构（示例）**

```text
BlueOath-Release
├─ BlueOath.Launcher.Wpf.exe
├─ launcher-settings.json
├─ 启动游戏.bat
├─ server/
├─ native/
├─ tools/
├─ runtime/
└─ baseline.json
```

> 当前发布器在 `Step 3` 将 launcher 发布目录内容移动到 `BlueOath-Release` 根目录，因此 zip 包应以该目录作为根目录打包。

### 3.3 发布清单（manifest）联动

1. 先在本地确认新版本号（与 `VersionInfo.Version` 对应）；
2. 上传新版本启动器 zip 到 GitHub Releases；
3. 更新 `docs/development/launcher-update-manifest.json`：
   - `version` 对齐新版本；
   - `packageUrl` 指向新 zip 直链；
   - `releaseNotes` 记录更新内容；
4. 对外发布的 launcher 在 `launcher-settings.json` 中配置：
   - `updateManifestUrl`（默认可指向上一步清单）；
   - `autoUpdateEnabled`（一般发布时保持 `true`）。

### 3.4 发布后验收清单

- [ ] 发布器执行成功退出码 0；
- [ ] 输出目录存在 `launcher-settings.json`、`BlueOath.Launcher.Wpf.exe`；
- [ ] 启动 `启动游戏.bat` 可正常打开启动器；
- [ ] `launcher-settings.json` 中 `updateManifestUrl`/`autoUpdateEnabled` 如期配置；
- [ ] 清单 `version` 与实际打包启动器版本一致；
- [ ] `packageUrl` 可访问、zip 解压后文件结构正确；
- [ ] 可选：在测试环境触发一次更新流程（先写入旧版本）验证 end-to-end。

## 4. 启动器自动更新方案

### 4.1 目标

- 启动器启动时自动检查最新版本信息；
- 与本地版本对比，检测到新版本时提示并允许更新；
- 更新时自动下载安装包、执行替换脚本、退出旧进程、完成重启；
- 不依赖外部安装器。

### 4.2 实现位置

- 自动更新服务：`src/BlueOath.Launcher.Wpf/Services/LauncherUpdateService.cs`
- 启动时触发与单实例保护：`src/BlueOath.Launcher.Wpf/App.xaml.cs`
- 安装目录互斥：`src/BlueOath.Launcher.Wpf/Services/LauncherExecutionGuard.cs`
- 配置读取：`src/BlueOath.Launcher.Wpf/Models/SettingsConfig.cs`
- 默认配置：`src/BlueOath.Launcher.Wpf/Services/SettingsService.cs`

### 4.3 配置字段（`launcher-settings.json`）

- `updateManifestUrl`：版本清单地址；当前 Release CI 使用 GitHub Releases API，后续可切到国内镜像站。
- `autoUpdateEnabled`：是否开启自动更新检测。

### 4.4 清单文件格式

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

### 4.5 建议镜像策略（国内访问）

1. CI 将 ZIP 发布到 GitHub Release，同时把发行包和 `launcher-update-release.json` 同步到 Gitee；
2. Release 包默认读取项目根目录 `launcher-update.json` 中的 Gitee 清单地址；如需切换镜像，只需修改清单地址和清单内的下载地址；
3. 建议统一通过同一个域名承载清单和安装包，减少域名切换维护成本。

当前代码仅在客户端层读取 `updateManifestUrl`，该值在 `launcher-settings.json` 中显式配置后生效；清单内可灵活切换下载源。

更新地址统一维护在项目根目录的 `launcher-update.json`，发布器根据 `Debug` 或 `Release` 配置选择对应地址并写入发行包。

Debug CI 默认发布到 Gitee 镜像，清单地址为：
`https://gitee.com/asa233/blue-rebirth/raw/master/launcher-update-debug.json`

### 4.6 兼容性与执行逻辑

1. 启动时读取版本清单，提取 `version`；
2. 与 `VersionInfo.Version` 做 `System.Version` 比较；
3. 发现更新则弹窗确认；
4. 下载更新压缩包到安装目录的 `.update\launcher-update.zip`；一次性 PowerShell 脚本写入 `%TEMP%\BlueOathLauncherUpdate\scripts`；
5. 写入一次性 PowerShell 脚本并携带参数：
   - 根目录 `rootDir`
   - 压缩包路径 `zipPath`
   - 启动器文件名 `exeName`
   - 当前启动器进程 id `launcherPid`
6. 启动脚本后关闭当前启动器：
   - 外部安装器先取得当前安装目录专属的更新互斥锁，并显示持续可见的安装窗口；
   - 在旧启动器仍持有单实例锁时，先解压并校验新启动器文件；
   - 通过命名事件完成“安装器已就绪”的无空窗交接，旧启动器收到信号后才退出；
   - 安装器等待旧进程完全结束；
   - 复制新文件到根目录；
   - 被占用文件最多自动重试 5 次；
   - 清理临时文件；
   - 释放更新互斥锁；
   - 重启新启动器。

启动器自身还持有安装目录专属的单实例互斥锁。覆盖安装期间再次双击启动器时，新进程会检测到更新互斥锁并立即退出；不能在这个进程中显示模态提示，否则提示框本身会继续占用待替换的 EXE/DLL。更新状态统一由持续可见的外部安装窗口展示。安装器复制前还会按完整可执行文件路径确认同目录的其他启动器进程均已退出，随后再执行带重试的覆盖。安装器准备失败时旧启动器继续运行；旧进程退出后的覆盖失败会写入发布包根目录的 `launcher-update-error.log` 并显示错误提示。

> 说明：当前策略是“覆盖式更新”，不会删除新包里不存在的旧文件。若需要全量清理策略，请在发布流程明确目录约定后再引入。

### 4.7 运行时注意

- 建议发布新版本时把启动器目录打包为 zip 根目录直接包含 `BlueOath.Launcher.Wpf.exe` 等目标文件；
- 保持 `executableName` 与实际可执行文件名一致；
- 当清单不可访问或解析失败时，启动器静默跳过更新，不影响正常启动流程。
- 更新安装窗口关闭前不要强制结束安装器进程；窗口会在覆盖完成后自动关闭并重启启动器。
- 若更新失败，先查看发布包根目录的 `launcher-update-error.log`，排除杀毒软件或其他程序占用文件后重试。

### 4.8 推荐 launcher-settings 配置示例

```json
{
  "updateManifestUrl": "https://api.github.com/repos/BlueRebirth/BlueRebirth/releases/latest",
  "autoUpdateEnabled": true
}
```

## 5. 常见问题与修正

- 未见 `launcher-settings.json`：优先检查
  - 发布器是否通过 `--output` 写入到预期目录；
  - `BlueOath.Publisher/Program.cs` 是否完整执行到发布器收尾步骤；
  - 目标目录写权限是否充足。
- 自动更新不触发：
  - 检查 `autoUpdateEnabled` 是否为 `true`；
  - `updateManifestUrl` 是否可访问；
  - 清单 `version` 大于当前版本（严格比较）。
- 更新期间重复打开启动器：
  - 新进程应立即退出，不再额外弹出会占用文件的提示框；
  - 安装进度窗口应始终可见，覆盖完成后自动重启；
  - 如果仍能同时打开两个主窗口，检查运行的启动器是否已经升级到包含安装互斥保护的版本。
- 双击启动器仍提示安装或更新 .NET：
  - 启动器采用轻量的框架依赖发布，不在发行包中内置 .NET 运行库；
  - 必须安装与程序架构一致的 **.NET Desktop Runtime 8 x64**，普通 **.NET Runtime** 不包含 WPF；
  - 安装后可用 `dotnet --list-runtimes` 确认存在 `Microsoft.WindowsDesktop.App 8.0.x`。
