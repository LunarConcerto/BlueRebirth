# 启动器发布与更新流水线（完整流程）

本文档覆盖“发布启动器包 → 生成 launcher-settings → 发布文件校验 → 更新清单发布”的完整过程，避免更新文件遗漏。

## 1. 流程目标

1. 每次发布都产出可直接运行的启动器包；
2. 启动器设置文件 `launcher-settings.json` 随发行包带出；
3. 发版后可被启动器检测到并触发自动更新；
4. 通过脚本内建校验防止关键文件遗漏。

## 2. 相关文件与职责

- `publish-release.bat`
  - 调用发布器并在最终目录进行关键文件存在性校验（`launcher-settings.json` 与启动器 exe）。
- `src/BlueOath.Publisher/Program.cs`
  - 负责拼装 `release` 目录内容；
  - 负责生成默认 `launcher-settings.json`。
- `src/BlueOath.Launcher.Wpf/launcher-settings.json`
  - 配置模板，随项目打包时复制到输出目录。
- `src/BlueOath.Launcher.Wpf/BlueOath.Launcher.Wpf.csproj`
  - 标记 `launcher-settings.json` 为构建/发布必带内容。
- `spec/docs/launcher-update-manifest.json`
  - 启动器远端版本清单示例与发布模板（或镜像站同结构文件）。
- `spec/docs/launcher-auto-update.md`
  - 启动器自动更新执行逻辑说明。

## 3. 标准发布步骤

### 3.1 版本与本地准备

1. 确认启动器版本基线 `src/BlueOath.Launcher.Wpf/version.txt` 已设置到本次发布目标版本。
2. 确认仓库根目录下 `baseline.json`、原始配置文件、运行时文件准备就绪。
3. 检查 `autoUpdate` 配置策略是否已确定（默认关闭空值）：
   - 若发版后立即启用自动更新，请先准备 manifest 链接。

### 3.2 执行发布脚本

```bat
publish-release.bat [可选:输出目录]
```

- 默认输出：`release\BlueOath-Release`（若未传参数）。
- `publish-release.bat [D:\tmp\release]` 可定向到固定目录便于后续打包。

### 3.3 脚本执行内含阶段

`publish-release.bat` 内部执行两层流程：

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

### 3.4 产物结构（示例）

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

## 4. 发布清单（manifest）联动

1. 先在本地确认新版本号（与 `VersionInfo.Version` 对应）；
2. 上传新版本启动器 zip 到 GitHub Releases；
3. 更新 `spec/docs/launcher-update-manifest.json`：
   - `version` 对齐新版本；
   - `packageUrl` 指向新 zip 直链；
   - `releaseNotes` 记录更新内容；
4. 对外发布的 launcher 在 `launcher-settings.json` 中配置：
   - `updateManifestUrl`（默认可指向上一步清单）；
   - `autoUpdateEnabled`（一般发布时保持 `true`）。

## 5. 发布后验收清单

- [ ] `publish-release.bat` 执行成功退出码 0；
- [ ] 输出目录存在 `launcher-settings.json`、`BlueOath.Launcher.Wpf.exe`；
- [ ] 启动 `启动游戏.bat` 可正常打开启动器；
- [ ] `launcher-settings.json` 中 `updateManifestUrl`/`autoUpdateEnabled` 如期配置；
- [ ] 清单 `version` 与实际打包启动器版本一致；
- [ ] `packageUrl` 可访问、zip 解压后文件结构正确；
- [ ] 可选：在测试环境触发一次更新流程（先写入旧版本）验证 end-to-end。

## 6. 常见问题与修正

- 未见 `launcher-settings.json`：优先检查
  - `publish-release.bat` 是否通过 `--output` 写入到预期目录；
  - `BlueOath.Publisher/Program.cs` 是否完整执行到 `Step 6`；
  - 目标目录写权限是否充足。
- 自动更新不触发：
  - 检查 `autoUpdateEnabled` 是否为 `true`；
  - `updateManifestUrl` 是否可访问；
  - 清单 `version` 大于当前版本（严格比较）。
