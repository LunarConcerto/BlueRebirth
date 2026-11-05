# 01 外置 Mod 加载与 Assetmap 动态对齐原理

本文说明启动器如何在**不改客户端 APK** 的前提下加载外置 Mod，以及如何让客户端热更系统接受“被 Mod 覆盖过”的资源清单。

## 1. 为什么能不改 APK

游戏客户端的资源更新由 assetmap 驱动：

- assetmap 是一个 UnityFS 包，内部只有一个 TextAsset，文本按行记录资源清单；
- 客户端启动时读取服务端宣告的版本与 assetmap，比较本地缓存，只下载变化的文件；
- 下载完成后客户端把文件放进自己的 resources/bundles 目录，后续直接从本地加载。

因此，只要做到两点，就能“无侵入”替换资源：

1. 服务端热更目录里的文件被替换成 Mod 文件；
2. assetmap 中对应条目的指纹同步更新，让客户端认为文件变了。

启动器的 Java 插件负责把 Mod 文件覆盖进服务端热更目录，并维护版本与 assetmap。

## 2. Mod 目录规范

    <Mods>/<name>.mod/
    ├── mod.json
    ├── main.lua
    ├── files/                     # 可选，文件覆盖区
    │   ├── bundle/config/         # 服务端配置表（*.db）
    │   ├── bundle/compressed/config/  # 对应 gzip 变体
    │   ├── bundle/wwise/          # 音频库（*.bnk）
    │   └── bundle/...             # 其它资源
    └── ...

mod.json 字段（由 ModScanner 解析）：

    {
      "id": "my-mod.mod",
      "name": "显示名称",
      "version": "1.0.0",
      "entry": "main.lua",
      "description": "一句话说明",
      "author": "作者",
      "loadOrder": 100,
      "enabled": true,
      "clientVersion": "1.4.145"
    }

- loadOrder：越小越先加载，越大越后加载；后加载的 Mod 覆盖先加载的；
- clientVersion：参与发布版本签名；多个 Mod 同时启用时取最大值；
- enabled：管理器勾选状态会写回文件。

## 3. 文件覆盖顺序

ModApplier 按 loadOrder 升序执行：

1. 扫描 Mods 目录，过滤未启用的 Mod；
2. 对每个 Mod：
   - files/bundle/ 下的文件复制到热更目录/bundle/ 下；
   - files/config/ 复制到热更目录/config/；
   - override/ 与 files/ 等价；config/、bundle/ 直接映射到热更目录同名目录；
3. 统计覆盖数量，写入应用结果；
4. 计算启用集合的版本签名，交给 VersionPublisher 决定是否递增内容版本；
5. 调用 AssetmapVersionPatcher 把热更 assetmap 内部版本行对齐到新版本；
6. 由启动器重启本地服务端，使新资源生效。

覆盖采用“复制到热更目录”，并保留 ModState 的原始文件备份；一键还原时按备份恢复。

## 4. Lua 运行时与 Mod API

启动器内置 LuaJ（Lua 5.2 语义），对所有启用的 main.lua 依次执行：

- 全局变量：__BLUEOATH_MOD_ROOT、__blueoath_loadfile、__blueoath_log、__BLUEOATH_MOD_ENTRIES、configManager；
- 每个 Mod 环境中的 mod 表：info、copy、write、hot_dir、mods_dir、saves_dir、log、watch_global；
- 生命周期：文件加载时执行；全部加载完成后调用 on_bootstrap(state)。

示例（同时使用服务端配置表与文件覆盖）：

    local orig = configManager.GetData
    configManager.GetData = function(name)
        local data = orig(name)
        if name == "config_ship_info" then
            local row = data[20130116]
            if row then row["attack"] = 9999 end
        end
        return data
    end

    function on_bootstrap(state)
        local ok = mod.copy("payload/extra.bin", "bundle/share/lua/package_0")
        mod.info("loaded " .. tostring(ok))
    end

configManager 在 Lua 运行结束后把修改过的行 diff 写回服务端配置 DB，不改客户端文件，适合数值类 Mod。

## 5. 版本发布与 assetmap 对齐

### 5.1 为什么需要版本对齐

客户端的更新判断是：

- 服务端返回的版本号（kit-client-version.txt 中的内容版本）；
- 客户端本地缓存的版本；
- assetmap 第一条版本行。

三者不一致时，客户端可能进入“有可用更新 0.00MB”的死循环：它认为需要更新，但 assetmap 里没有任何变化，于是反复提示。

### 5.2 动态改写版本行

AssetmapVersionPatcher 的做法：

1. 读取 ModPaths.hotDir/bundle/assetmap；
2. 在文件二进制中查找第一个形如 x.y.z 的明文版本行（未压缩 UnityFS 中位于 blocksInfo 之后的数据区）；
3. 用等长替换把版本改成 kit-client-version.txt 的当前值；
4. 未找到或长度变化则放弃并记录日志，避免写坏文件。

因此 **Mod 附带的 assetmap 必须是未压缩 UnityFS**（packer=none）。LZ4/LZMA 压缩后明文不存在，无法原地改写。

### 5.3 指纹计算

assetmap 文本有两种行格式：

- 配置/音频类：path,大写MD5,原始大小,gzip大小；
- 其它 bundle 类：path,解压后crc32十进制,原始文件MD5,原始大小。

crc32 不是整文件 CRC，而是 UnityFS 全部数据块解压后拼接内容的 CRC32。可用以下算法复核：

    UnityFS 头 -> blocksInfo -> 对每个 block 解压 -> 拼接 payload -> zlib.crc32(payload)

官方 assetmap 的原生 package_0 行可与此算法精确对上，说明该口径正确。脚本实现见 reference_code/build_scripts/。

### 5.4 发布流程

    应用 Mod -> 覆盖文件 -> 计算签名 -> 版本 +1（或按规定） -> 写 kit-client-version.txt
    -> 改写热更 assetmap 版本行 -> 重启服务端 -> 客户端拉取增量

签名由 (mod id, clientVersion) 集合组成；签名变化才会递增版本，单纯重启不会。

## 6. 常见故障与排查

| 现象 | 可能原因 | 处理 |
|---|---|---|
| 客户端提示 0.00MB 更新循环 | 发布版本与 assetmap 第一行不一致，或 assetmap 被压缩 | 检查 kit-client-version.txt 与 assetmap 首行；确认未压缩 UnityFS |
| 客户端下载 404 / 压缩块缺失 | 只有 config 原文件，没有 compressed 的 gzip 变体 | 生成 gzip（level 6、mtime=0），路径与 assetmap 第 4 字段匹配 |
| Mod 应用成功但游戏没变化 | assetmap 指纹没更新，客户端认为文件未变 | 按 5.3 重算并替换对应行 |
| 管理器中显示 0 个 Mod | 文件夹名不是 .mod、mod.json 不在根目录、未授权存储 | 检查目录结构与权限 |
| 改文件后客户端闪退 | 替换了与客户端版本不兼容的 bundle | 回滚该 Mod，核对客户端版本基线 |

## 7. 代码入口

| 功能 | 类 |
|---|---|
| Mod 扫描/解析 | ModScanner、ModInfo |
| 应用/还原 | ModApplier、ModState |
| Lua 运行时 | LuaRuntime、bootstrap.lua |
| 版本发布 | VersionPublisher |
| assetmap 改写 | AssetmapVersionPatcher |
| 路径解析 | ModPaths |
