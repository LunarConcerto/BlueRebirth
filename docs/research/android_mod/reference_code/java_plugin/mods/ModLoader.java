package com.bluerebirth.mods;

import android.content.Context;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.util.List;

/** Entry point injected into the BlueRebirthApp launcher process. */
public final class ModLoader {
    private static volatile boolean started;
    private static Context appCtx;
    private static String bootstrap;
    private static Thread periodic;

    public static void init(Context ctx) {
        if (started) return;
        started = true;
        long t0 = System.currentTimeMillis();
        try {
            appCtx = ctx.getApplicationContext();
            if (appCtx == null) appCtx = ctx;
            ModPaths.init(appCtx);
            bootstrap = readAsset(appCtx, "bluerebirth/bootstrap.lua");
            Logx.i("ModLoader.init extRoot=" + ModPaths.extRoot + " granted=" + ModPaths.externalGranted);
            try { KeepAliveService.ensure(appCtx); } catch (Throwable t) { Logx.w("keepalive init failed: " + t); }
            try { UiInjector.install(appCtx); } catch (Throwable t) { Logx.w("ui injector init failed: " + t); }
        } catch (Throwable t) {
            try { Logx.e("ModLoader init failed", t); } catch (Throwable ignored) { }
            return;
        }
        // Pending "restore vanilla" request from the UI: revert everything before the server starts.
        try {
            if (consumeMarker("reset-vanilla.pending")) {
                List<ModInfo> mods = ModScanner.scan(ModPaths.modsDir);
                for (ModInfo m : mods) {
                    if (m.enabled) ModScanner.setEnabled(m, false);
                }
                ModApplier.restoreAll();
                String purge = ClientCache.purgeHotUpdateCache();
                boolean purgeOk = purge != null && purge.indexOf("remaining=0") >= 0;
                // Always go back to the real kit version. Without root the client cache cannot be
                // cleared from here, so the UI shows a guidance dialog asking the player to clear
                // the game's app data (Settings -> Storage -> Clear data) before starting.
                VersionPublisher.resetToVanillaBase();
                try { FileOps.writeText(new File(ModPaths.privateDir, "restore-done.flag"), "1"); } catch (Throwable ignored) { }
                Logx.i("vanilla restore: disabled " + mods.size() + " mod(s), overlays reverted, version reset to 1.4.140 (purge_ok=" + purgeOk + ")");
            }
        } catch (Throwable t) { Logx.e("vanilla restore failed", t); }
        // Pending save import from /sdcard/BlueRebirth/Saves (runs before the server opens the DB)
        try {
            if (SaveSync.consumeImportRequest()) {
                String msg = SaveSync.importFromExternal();
                Logx.i("boot save import: " + msg);
                try {
                    if (msg != null && msg.startsWith("存档导入成功")) {
                        FileOps.writeText(new File(ModPaths.privateDir, "import-done.flag"), "1");
                        FileOps.writeText(new File(ModPaths.privateDir, "import-hint.flag"), "1");
                        Logx.i("import-done flag written (show no-root guidance dialog)");
                    }
                } catch (Throwable t) { Logx.w("write import flag failed: " + t); }
                if (msg == null || !msg.startsWith("存档导入成功")) {
                    SaveSync.endImport();
                    Logx.w("save import failed -> auto-export resumed: " + msg);
                }
            }
        } catch (Throwable t) { Logx.e("boot save import failed", t); }
        try {
            // stale flag safety: no pending import marker but flag left over -> resume sync
            if (!new java.io.File(ModPaths.privateDir, SaveSync.IMPORT_MARKER).exists() && SaveSync.isImportInProgress()) {
                SaveSync.endImport();
                Logx.i("stale import flag cleared at boot");
            }
        } catch (Throwable ignored) { }
        try { SaveSync.restoreIfNeeded(); } catch (Throwable t) { Logx.e("save restore failed", t); }
        try { ModApplier.apply(appCtx, bootstrap); } catch (Throwable t) { Logx.e("mod apply failed", t); }
        try { AssetmapVersionPatcher.sync(); } catch (Throwable t) { Logx.w("assetmap sync at boot failed: " + t); }
        try { SaveSync.exportNow(); } catch (Throwable t) { Logx.e("save export failed", t); }
        Logx.i("boot sequence done in " + (System.currentTimeMillis() - t0) + "ms");
        startPeriodic();
    }

    public static void requestApplyAsync() {
        final Context ctx = appCtx;
        if (ctx == null) return;
        new Thread(new Runnable() {
            public void run() {
                try { ModApplier.apply(ctx, bootstrap); } catch (Throwable t) { Logx.e("manual apply failed", t); }
            }
        }, "br-mods-apply").start();
    }

    /** UI action: mark a vanilla restore + save import for the next process start. */
    public static void requestVanillaReset() {
        try {
            File m = new File(ModPaths.privateDir, "reset-vanilla.pending");
            File p = m.getParentFile();
            if (p != null) p.mkdirs();
            FileOps.writeText(m, "1");
            Logx.i("vanilla reset requested");
        } catch (Throwable t) { Logx.e("request vanilla reset failed", t); }
    }

    /** UI action: mark external save import for the next process start. */
    public static void requestSaveImport() {
        SaveSync.requestImportFromExternal();
    }

    private static boolean consumeMarker(String name) {
        try {
            File m = new File(ModPaths.privateDir, name);
            if (!m.exists()) return false;
            return m.delete();
        } catch (Throwable t) { return false; }
    }

    public static void exportAsync() {
        new Thread(new Runnable() {
            public void run() {
                try { SaveSync.exportNow(); } catch (Throwable t) { Logx.e("manual export failed", t); }
            }
        }, "br-saves-export").start();
    }

    private static void startPeriodic() {
        if (periodic != null) return;
        periodic = new Thread(new Runnable() {
            public void run() {
                while (true) {
                    try { Thread.sleep(20000L); } catch (InterruptedException e) { return; }
                    try { SaveSync.exportIfChanged(); } catch (Throwable ignored) { }
                }
            }
        }, "br-saves-periodic");
        periodic.setDaemon(true);
        periodic.start();
    }

    private static String readAsset(Context ctx, String name) throws Exception {
        InputStream in = ctx.getAssets().open(name);
        try {
            ByteArrayOutputStream bo = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) bo.write(buf, 0, n);
            return new String(bo.toByteArray(), "UTF-8");
        } finally { in.close(); }
    }
}
