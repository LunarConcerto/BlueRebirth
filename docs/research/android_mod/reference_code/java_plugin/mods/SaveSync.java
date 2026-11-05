package com.bluerebirth.mods;

import java.io.File;
import java.util.List;

/** Mirrors the launcher private server save data to /sdcard/BlueRebirth/Saves. */
public final class SaveSync {
    public static void restoreIfNeeded() {
        try { migrateFallbackSaves(); } catch (Throwable t) { Logx.e("migrate fallback saves failed", t); }
        File priv = ModPaths.privateDir;
        if (priv == null) return;
        copyBackIfMissing(new File(priv, "bo-data"), new File(ModPaths.savesDir, "bo-data"));
        copyBackIfMissing(new File(priv, "runtime"), new File(ModPaths.savesDir, "runtime"));
    }

    /** If the user granted all-files access later, move saves written to the app-coped fallback. */
    private static void migrateFallbackSaves() {
        File fb = ModPaths.fallbackSavesDir;
        if (fb == null || !fb.exists()) return;
        if (ModPaths.savesDir == null || !ModPaths.savesDir.getAbsolutePath().startsWith("/sdcard/")) return;
        if (fb.getAbsolutePath().equals(ModPaths.savesDir.getAbsolutePath())) return;
        File srcDb = new File(fb, "bo-data/profiles.db");
        File dstDb = new File(ModPaths.savesDir, "bo-data/profiles.db");
        if (!srcDb.exists()) return;
        if (dstDb.exists() && dstDb.lastModified() >= srcDb.lastModified()) return;
        copyTree(fb, ModPaths.savesDir);
        Logx.i("migrated fallback saves -> " + ModPaths.savesDir);
    }

    private static void copyBackIfMissing(File privDir, File backupDir) {
        try {
            File db = new File(privDir, "profiles.db");
            File bakDb = new File(backupDir, "profiles.db");
            if (!db.exists() && bakDb.exists()) {
                Logx.i("restoring missing save from backup: " + backupDir);
                copyTree(backupDir, privDir);
            }
        } catch (Throwable t) {
            Logx.e("restore saves failed", t);
        }
    }

    public static void exportIfChanged() {
        if (isImportInProgress()) { Logx.i("skip export (import in progress)"); return; }
        try { copyTreeIfChanged(new File(ModPaths.privateDir, "bo-data"), new File(ModPaths.savesDir, "bo-data")); }
        catch (Throwable t) { Logx.e("export bo-data failed", t); }
        try { copyTreeIfChanged(new File(ModPaths.privateDir, "runtime"), new File(ModPaths.savesDir, "runtime")); }
        catch (Throwable t) { Logx.e("export runtime failed", t); }
    }

    public static void exportNow() {
        if (isImportInProgress()) { Logx.i("skip export (import in progress)"); return; }
        try { copyTree(new File(ModPaths.privateDir, "bo-data"), new File(ModPaths.savesDir, "bo-data")); }
        catch (Throwable t) { Logx.e("export bo-data failed", t); }
        try { copyTree(new File(ModPaths.privateDir, "runtime"), new File(ModPaths.savesDir, "runtime")); }
        catch (Throwable t) { Logx.e("export runtime failed", t); }
    }


    public static final String IMPORT_MARKER = "import-save.pending";

    private static final String IMPORT_IN_PROGRESS_FLAG = "import-in-progress.flag";

    /** 导入窗口内暂停自动导出，防止 SaveSync 把玩家刚放入的存档覆盖掉。 */
    public static void beginImport() {
        try {
            File f = new File(ModPaths.privateDir, IMPORT_IN_PROGRESS_FLAG);
            File p = f.getParentFile();
            if (p != null) p.mkdirs();
            FileOps.writeText(f, "1");
            Logx.i("import begin: auto-export paused (import-in-progress.flag)");
        } catch (Throwable t) { Logx.e("beginImport flag failed", t); }
    }

    public static boolean isImportInProgress() {
        try { return new File(ModPaths.privateDir, IMPORT_IN_PROGRESS_FLAG).exists(); }
        catch (Throwable t) { return false; }
    }

    public static void endImport() {
        try {
            File f = new File(ModPaths.privateDir, IMPORT_IN_PROGRESS_FLAG);
            if (f.exists() && f.delete()) Logx.i("import end: auto-export resumed");
            else Logx.i("import end: no flag to clear");
        } catch (Throwable t) { Logx.e("endImport flag failed", t); }
    }

    /** Ask the launcher to import /sdcard/BlueRebirth/Saves/bo-data into the private server dir
     *  on the next process start (must run before the .NET server opens the database). */
    public static final String STAGING_DIR = "import-staging";

    public static void requestImportFromExternal() {
        try {
            beginImport();
            // snapshot the external save right now: the periodic exporter may overwrite it later
            File ext = new File(new File(ModPaths.savesDir, "bo-data"), "profiles.db");
            if (!ext.exists()) ext = new File(new File(ModPaths.fallbackSavesDir, "bo-data"), "profiles.db");
            if (ext.exists() && ext.length() > 1024) {
                File stageDir = new File(ModPaths.privateDir, STAGING_DIR);
                stageDir.mkdirs();
                FileOps.copy(ext, new File(stageDir, "profiles.db"));
                Logx.i("save snapshot for import: " + ext + " -> staging (" + ext.length() + "B)");
            }
            File m = new File(ModPaths.privateDir, IMPORT_MARKER);
            File p = m.getParentFile();
            if (p != null) p.mkdirs();
            FileOps.writeText(m, "1");
            Logx.i("save import requested: " + m);
        } catch (Throwable t) {
            Logx.e("request save import failed", t);
        }
    }

    public static boolean consumeImportRequest() {
        try {
            File m = new File(ModPaths.privateDir, IMPORT_MARKER);
            if (!m.exists()) return false;
            m.delete();
            Logx.i("save import marker consumed");
            return true;
        } catch (Throwable t) { return false; }
    }

    /** Force-import the external profiles.db into the private server dir. */
    public static String importFromExternal() {
        try {
            File src = new File(new File(ModPaths.privateDir, STAGING_DIR), "profiles.db");
            boolean staged = src.exists();
            if (!staged) {
                src = new File(new File(ModPaths.savesDir, "bo-data"), "profiles.db");
                if (!src.exists()) {
                    src = new File(new File(ModPaths.fallbackSavesDir, "bo-data"), "profiles.db");
                }
            }
            if (!src.exists()) return "未找到外部存档（Saves/bo-data/profiles.db）";
            if (src.length() < 1024) return "外部存档文件异常（大小 " + src.length() + " 字节）";
            byte[] head = new byte[16];
            java.io.FileInputStream in = new java.io.FileInputStream(src);
            try { int n = in.read(head); if (n < 16) return "外部存档读取失败"; } finally { in.close(); }
            String magic = new String(head, "ISO-8859-1");
            if (!magic.startsWith("SQLite format 3")) return "外部文件不是有效的存档数据库";
            File priv = new File(ModPaths.privateDir, "bo-data");
            priv.mkdirs();
            File dst = new File(priv, "profiles.db");
            if (dst.exists()) {
                try { FileOps.copy(dst, new File(priv, "profiles.db.before-import")); } catch (Throwable ignored) { }
            }
            new File(priv, "profiles.db-wal").delete();
            new File(priv, "profiles.db-shm").delete();
            FileOps.copy(src, dst);
            dst.setReadable(true, false);
            dst.setWritable(true, false);
            try { dst.setLastModified(src.lastModified()); } catch (Throwable ignored) { }
            if (staged) new File(src.getParentFile(), "profiles.db").delete();
            clearOldAccountCaches();
            try {
                File extNow = new File(new File(ModPaths.savesDir, "bo-data"), "profiles.db");
                writeExportState(extNow.exists() ? extNow : dst);
            } catch (Throwable ignored) { }
            endImport();
            String msg = "存档导入成功：" + dst.getAbsolutePath() + "（" + dst.length() + " 字节）";
            Logx.i(msg + " <- " + src.getAbsolutePath());
            return msg;
        } catch (Throwable t) {
            Logx.e("save import failed", t);
            return "存档导入失败：" + t;
        }
    }

    private static void copyTreeIfChanged(File src, File dst) {
        if (src == null || !src.exists()) return;
        List<File> fs = FileOps.listFilesRec(src);
        int n = 0;
        for (File f : fs) {
            String rel = ModPaths.rel(f, src);
            File d = new File(dst, rel);
            if (d.exists() && d.length() == f.length() && d.lastModified() >= f.lastModified()) continue;
            if (isNewerExternalSave(f, d) || isForeignExternalSave(f, d)) { Logx.i("skip export (protected external save, use 导入外部存档): " + rel); continue; }
            try { copyOne(f, d); n++; if (f.getName().endsWith("profiles.db")) writeExportState(d); } catch (Throwable t) { Logx.e("copy " + rel, t); }
        }
        if (n > 0) Logx.i("saves exported " + n + " file(s) -> " + dst);
    }

    private static void copyTree(File src, File dst) {
        if (src == null || !src.exists()) return;
        List<File> fs = FileOps.listFilesRec(src);
        for (File f : fs) {
            String rel = ModPaths.rel(f, src);
            File d = new File(dst, rel);
            if (isNewerExternalSave(f, d) || isForeignExternalSave(f, d)) { Logx.i("skip export (protected external save): " + rel); continue; }
            try { copyOne(f, d); if (f.getName().endsWith("profiles.db")) writeExportState(d); } catch (Throwable t) { Logx.e("copy " + rel, t); }
        }
    }

    /** Remove caches that could make the client show the previous account after an import. */
    private static void clearOldAccountCaches() {
        try {
            File priv = ModPaths.privateDir;
            File loginLog = new File(priv, "game-login.log");
            if (loginLog.exists() && !loginLog.delete()) Logx.w("cannot delete game-login.log");
            File prof = new File(priv, "bo-data");
            String[] stale = {"profiles.db-wal", "profiles.db-shm", "login-session.txt", "session.json"};
            for (String n : stale) {
                File f = new File(prof, n);
                if (f.exists() && !f.delete()) Logx.w("cannot delete " + f);
            }
            Logx.i("old account caches cleared");
        } catch (Throwable t) {
            Logx.w("clearOldAccountCaches failed: " + t);
        }
    }

    /** External profiles.db was dropped in by the user (newer than our internal one): do not overwrite it. */
    // ---- 外部存档防误覆盖：记录“上次由本启动器导出的 profiles.db”，若外部文件被玩家替换则保护 ----
    private static File stateFile() { return new File(ModPaths.privateDir, "save-sync.state"); }

    private static String md5(File f) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
            java.io.FileInputStream in = new java.io.FileInputStream(f);
            try {
                byte[] buf = new byte[65536];
                int n;
                while ((n = in.read(buf)) > 0) md.update(buf, 0, n);
            } finally { in.close(); }
            byte[] d = md.digest();
            StringBuilder b = new StringBuilder();
            for (byte x : d) b.append(String.format("%02x", x & 0xff));
            return b.toString();
        } catch (Throwable t) { return "err"; }
    }

    private static String stat(File f) { return f.length() + ":" + md5(f); }

    private static String readExportState() {
        try {
            File sf = stateFile();
            if (!sf.exists()) return null;
            String v = FileOps.readTextAuto(sf);
            return v == null ? null : v.trim();
        } catch (Throwable t) { return null; }
    }

    private static void writeExportState(File f) {
        try {
            if (f != null && f.exists()) FileOps.writeText(stateFile(), stat(f));
        } catch (Throwable t) { Logx.w("write save-sync state failed: " + t); }
    }

    /** 外部 profiles.db 与“上次导出内容”及私有存档都不一致 => 视为玩家放入的新存档，导出时绝不能覆盖。 */
    private static boolean isForeignExternalSave(File src, File dst) {
        try {
            if (src == null || dst == null) return false;
            if (!src.getName().endsWith("profiles.db")) return false;
            if (!dst.exists()) return false;
            String st = readExportState();
            String ext = stat(dst);
            if (st != null && st.equals(ext)) return false;
            String priv = stat(src);
            if (ext.equals(priv)) { writeExportState(dst); return false; }
            Logx.i("foreign external save detected, keep for import (" + dst.length() + "B, lastExport=" + st + ")");
            return true;
        } catch (Throwable t) { return false; }
    }

    private static boolean isNewerExternalSave(File src, File dst) {
        try {
            if (src == null || dst == null) return false;
            if (!src.getName().endsWith("profiles.db")) return false;
            return dst.exists() && src.exists() && dst.lastModified() > src.lastModified() + 5000L;
        } catch (Throwable t) { return false; }
    }

    private static void copyOne(File src, File dst) throws Exception {
        if (src.getName().endsWith("profiles.db") && dst.exists()) {
            File prev = new File(dst.getAbsolutePath() + ".prev");
            try { FileOps.copy(dst, prev); } catch (Throwable ignored) { }
        }
        FileOps.copy(src, dst);
    }
}
