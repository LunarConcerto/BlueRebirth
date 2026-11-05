package com.bluerebirth.mods;

import android.content.Context;
import java.io.File;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Applies enabled Mods/*.mod folders to the server hot-update dir, and undoes removed ones. */
public final class ModApplier {
    private static volatile String lastResult = "";
    public static volatile boolean applyRunning = false;
    public static volatile int applyProgress = 0;

    public static String lastResult() { return lastResult; }

    public static void apply(Context ctx, String bootstrapSource) {
        long t0 = System.currentTimeMillis();
        applyRunning = true;
        applyProgress = 0;
        ConfigBridge.reset();
        ModState st = ModState.get();
        List<ModInfo> all = ModScanner.scan(ModPaths.modsDir);
        List<ModInfo> enabled = new ArrayList<ModInfo>();
        for (ModInfo m : all) if (m.enabled) enabled.add(m);
        StringBuilder sb = new StringBuilder();
        sb.append("扫描到 ").append(all.size()).append(" 个 Mod，启用 ").append(enabled.size()).append(" 个");
        Logx.i(sb.toString());
        if (!new File(ModPaths.hotDir, "config").isDirectory()) {
            lastResult = "服务端资源尚未安装（" + ModPaths.hotDir + " 下无 config 目录），等资源包安装后再应用 Mod";
            Logx.i(lastResult);
            applyRunning = false;
            return;
        }

        // 1) desired file overlays
        LinkedHashMap<String, File> desired = new LinkedHashMap<String, File>();
        for (ModInfo m : enabled) collectOverlay(m, desired);
        Logx.i("overlay files desired=" + desired.size());
        int totalOverlays = desired.size();

        // 2) undo stale overlays and previous lua patches
        st.restoreStaleOverlays(desired.keySet());
        st.restoreLuaBackups();

        // 3) copy overlays (backup pristine first)
        int copied = 0;
        for (Map.Entry<String, File> e : desired.entrySet()) {
            try {
                boolean hasBak = st.backupFileIfNeeded(e.getKey());
                FileOps.copy(e.getValue(), new File(ModPaths.hotDir, e.getKey()));
                st.markOverlay(e.getKey(), hasBak);
                copied++;
                if (totalOverlays > 0) {
                    applyProgress = 5 + (int) (copied * 80L / totalOverlays);
                    ProgressBus.report(applyProgress, "正在覆盖文件 " + copied + "/" + totalOverlays);
                }
            } catch (Throwable t) {
                Logx.e("overlay copy failed: " + e.getKey(), t);
            }
        }
        st.save();
        Logx.i("overlay copied=" + copied);

        // 版本发布 + AssetMap 动态对齐：把服务端发布的版本号同步写进 assetmap 内部第一行，
        // 避免客户端因“版本号与 assetmap 内部版本不一致”而卡在 0.00MB 的“有可用更新”。
        try {
            java.util.List<String> versions = new java.util.ArrayList<String>();
            for (ModInfo m : enabled) {
                if (m.clientVersion != null && m.clientVersion.trim().length() > 0) versions.add(m.clientVersion);
            }
            String desiredMin = VersionPublisher.highest(versions);
            VersionPublisher.publish(buildSignature(enabled), desiredMin);
        } catch (Throwable t) {
            Logx.e("version publish failed", t);
        }
        try { AssetmapVersionPatcher.sync(); } catch (Throwable t) { Logx.e("assetmap sync failed", t); }

        // 4) run lua mods (config db patching)
        List<ModInfo> withLua = new ArrayList<ModInfo>();
        for (ModInfo m : enabled) {
            File entry = new File(m.dir, m.entry == null ? "main.lua" : m.entry);
            if (entry.exists()) withLua.add(m);
        }
        applyProgress = 90;
        ProgressBus.report(90, "正在执行 Lua 补丁…");
        String boot = pickBootstrap(bootstrapSource);
        if (!withLua.isEmpty() && boot != null) {
            try {
                LuaRuntime.run(ctx, withLua, boot);
            } catch (Throwable t) {
                Logx.e("lua runtime failed", t);
            }
        }
        st.save();
        long ms = System.currentTimeMillis() - t0;
        lastResult = sb.toString() + "；文件覆盖 " + copied + "；Lua " + withLua.size()
                + "；耗时 " + ms + "ms";
        applyProgress = 100;
        applyRunning = false;
        ProgressBus.report(100, "应用完成");
        Logx.i("apply done: " + lastResult);
    }

    /** PC style Mods/bootstrap.lua wins; otherwise the built-in Android bootstrap. */
    private static String pickBootstrap(String fallback) {
        try {
            File bs = new File(ModPaths.modsDir, "bootstrap.lua");
            if (bs.exists()) {
                Logx.i("using PC-style bootstrap.lua from Mods dir");
                return FileOps.readTextAuto(bs);
            }
        } catch (Throwable t) {
            Logx.w("read Mods/bootstrap.lua failed: " + t);
        }
        return fallback;
    }

    /** Stable signature of the currently enabled bundle-mod set. */
    static String buildSignature(List<ModInfo> enabled) {
        StringBuilder b = new StringBuilder();
        boolean any = false;
        for (ModInfo m : enabled) {
            if (!hasBundleOverlay(m)) continue;
            any = true;
            b.append(m.id).append(':').append(m.clientVersion == null ? "-" : m.clientVersion).append(';');
        }
        return any ? b.toString() : VersionPublisher.CLEAN_SIGNATURE;
    }

    /** Undo every mod overlay + lua config patch; used by the "restore vanilla" action. */
    public static void restoreAll() {
        try {
            ConfigBridge.reset();
            ModState st = ModState.get();
            st.restoreStaleOverlays(new java.util.LinkedHashSet<String>());
            st.restoreLuaBackups();
            st.save();
            Logx.i("restoreAll: all mod overlays and lua patches reverted");
        } catch (Throwable t) {
            Logx.e("restoreAll failed", t);
        }
    }

    private static boolean hasBundleOverlay(ModInfo m) {
        try {
            File files = new File(m.dir, "files");
            if (new File(files, "bundle").isDirectory()) return true;
            if (new File(m.dir, "bundle").isDirectory()) return true;
        } catch (Throwable ignored) { }
        return false;
    }

    private static void collectOverlay(ModInfo m, Map<String, File> out) {
        File files = new File(m.dir, "files");
        if (files.isDirectory()) addTree(files, "", out);
        File override = new File(m.dir, "override");
        if (override.isDirectory()) addTree(override, "", out);
        File cfg = new File(m.dir, "config");
        if (cfg.isDirectory()) addTree(cfg, "config/", out);
        File bun = new File(m.dir, "bundle");
        if (bun.isDirectory()) addTree(bun, "bundle/", out);
    }

    private static void addTree(File root, String prefix, Map<String, File> out) {
        List<File> fs = FileOps.listFilesRec(root);
        for (File f : fs) {
            String rel = prefix + ModPaths.rel(f, root);
            out.put(rel, f);
        }
    }
}
