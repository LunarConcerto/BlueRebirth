package com.bluerebirth.mods;

import android.content.Context;
import android.os.Environment;
import java.io.File;
import java.io.FileOutputStream;

/** Resolves external dirs; falls back to the app-scoped external dir when storage permission is missing. */
public final class ModPaths {
    public static File extRoot;
    public static File modsDir;
    public static File savesDir;
    public static File logsDir;
    public static File stateDir;
    public static File hotDir;
    public static File privateDir;
    public static boolean externalGranted;
    public static boolean primaryWritable;
    public static String storageNote = "";
    public static File fallbackSavesDir;

    public static void init(Context ctx) {
        File base = null;
        try { base = Environment.getExternalStorageDirectory(); } catch (Throwable ignored) { }
        File fallback = null;
        try { fallback = ctx.getExternalFilesDir(null); } catch (Throwable ignored) { }
        hotDir = fallback;
        privateDir = ctx.getFilesDir();
        File primaryRoot = null;
        if (base != null) primaryRoot = new File(base, "BlueRebirth");
        else if (fallback != null) primaryRoot = new File(fallback, "BlueRebirth");
        else primaryRoot = new File(privateDir, "BlueRebirth");
        extRoot = primaryRoot;
        externalGranted = checkExternal();
        primaryWritable = testWrite(primaryRoot);

        File useRoot;
        if (primaryWritable) {
            useRoot = primaryRoot;
            storageNote = "存档/Mod 位于公共目录 /sdcard/BlueRebirth（已授权）";
        } else {
            File fb = fallback != null ? fallback : privateDir;
            useRoot = new File(fb, "BlueRebirth");
            useRoot.mkdirs();
            storageNote = "未获得「所有文件访问」权限，暂用应用外部目录：" + useRoot.getAbsolutePath()
                    + "（卸载会删除，建议在设置中授权后重启）";
        }
        File fbRoot = new File(fallback != null ? fallback : privateDir, "BlueRebirth");
        fallbackSavesDir = new File(fbRoot, "Saves");
        modsDir = new File(useRoot, "Mods");
        savesDir = new File(useRoot, "Saves");
        logsDir = new File(useRoot, "Logs");
        stateDir = new File(modsDir, ".state");
        mkdirs(modsDir); mkdirs(savesDir); mkdirs(logsDir); mkdirs(stateDir);
        Logx.init(logsDir);
    }

    private static void mkdirs(File d) { try { d.mkdirs(); } catch (Throwable ignored) { } }

    public static boolean checkExternal() {
        try { return Environment.isExternalStorageManager(); }
        catch (Throwable t) {
            try { return new File("/sdcard/BlueRebirth").canWrite(); } catch (Throwable t2) { return false; }
        }
    }

    private static boolean testWrite(File root) {
        try {
            root.mkdirs();
            File probe = new File(root, ".write_probe");
            FileOutputStream fos = new FileOutputStream(probe);
            try { fos.write(49); fos.flush(); } finally { fos.close(); }
            probe.delete();
            return true;
        } catch (Throwable t) {
            return false;
        }
    }

    public static File hotConfig() { return new File(hotDir, "config"); }
    public static File hotBundle() { return new File(hotDir, "bundle"); }

    public static String rel(File f, File root) {
        String base = root.getAbsolutePath();
        String p = f.getAbsolutePath();
        if (p.startsWith(base)) {
            p = p.substring(base.length());
            while (p.startsWith("/") || p.startsWith("\\")) p = p.substring(1);
        }
        return p.replace('\\', '/');
    }
}
