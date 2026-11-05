package com.bluerebirth.mods;

import java.io.File;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/** PC 式“物理覆盖”：把 Mod 的 bundle/config、compressed/config、wwise 文件直接覆盖到游戏客户端目录，
 *  不再依赖热更/版本号/assetmap。首次覆盖前备份原文件，还原时恢复。 */
public final class ClientOverlay {
    public static final String CLIENT_FILES = "/sdcard/Android/data/com.zephyrus.clsy.gp/files";
    public static final String BACKUP_DIR = "/sdcard/BlueRebirth/ClientBackup";

    private static File backupRoot() { return new File(BACKUP_DIR); }
    private static File manifest() { return new File(BACKUP_DIR, "manifest.txt"); }

    private static Set<String> loadManifest() {
        Set<String> s = new LinkedHashSet<String>();
        try {
            File m = manifest();
            if (!m.exists()) return s;
            String t = FileOps.readTextAuto(m);
            if (t == null) return s;
            for (String line : t.split("\n")) {
                line = line.trim();
                if (line.length() > 0) s.add(line);
            }
        } catch (Throwable t) { Logx.w("client overlay load manifest failed: " + t); }
        return s;
    }

    private static void saveManifest(Set<String> s) {
        try {
            StringBuilder b = new StringBuilder();
            for (String line : s) b.append(line).append('\n');
            FileOps.writeText(manifest(), b.toString());
        } catch (Throwable t) { Logx.w("client overlay save manifest failed: " + t); }
    }

    /** 统计可物理覆盖的文件数（用于进度）。 */
    public static int countFiles(List<ModInfo> mods) {
        int n = 0;
        for (ModInfo m : mods) {
            if (!m.enabled) continue;
            File files = new File(m.dir, "files");
            if (!files.isDirectory()) continue;
            for (File f : FileOps.listFilesRec(files)) {
                String rel = ModPaths.rel(f, files);
                if (isOverlayPath(rel)) n++;
            }
        }
        return n;
    }

    private static boolean isOverlayPath(String rel) {
        if (rel == null) return false;
        if (rel.equals("bundle/assetmap")) return false;
        return rel.startsWith("bundle/config/") || rel.startsWith("bundle/compressed/config/")
                || rel.startsWith("bundle/wwise/");
    }

    /** 物理覆盖所有启用的 Mod 文件；返回成功复制数。 */
    public static int applyAll(List<ModInfo> mods) {
        int copied = 0;
        Set<String> manifestSet = loadManifest();
        for (ModInfo m : mods) {
            if (!m.enabled) continue;
            File files = new File(m.dir, "files");
            if (!files.isDirectory()) continue;
            for (File f : FileOps.listFilesRec(files)) {
                String rel = ModPaths.rel(f, files);
                if (!isOverlayPath(rel)) continue;
                try {
                    String targetRel = rel.startsWith("bundle/") ? ("bundles/" + rel.substring("bundle/".length())) : rel;
                    File target = new File(CLIENT_FILES, targetRel);
                    String key = rel;
                    boolean known = manifestSet.contains(key) || manifestSet.contains("!" + key);
                    if (!known) {
                        if (target.exists()) {
                            File bak = new File(BACKUP_DIR, rel);
                            FileOps.copy(target, bak);
                            manifestSet.add(key);
                            Logx.i("client overlay backup: " + rel);
                        } else {
                            manifestSet.add("!" + key);
                        }
                    } else if (manifestSet.contains("!" + key) && target.exists()) {
                        // 之前记录为“原本不存在”，现在客户端文件已下载：升级为正式备份
                        File bak = new File(BACKUP_DIR, rel);
                        FileOps.copy(target, bak);
                        manifestSet.remove("!" + key);
                        manifestSet.add(key);
                        Logx.i("client overlay backup upgraded: " + rel);
                    }
                    FileOps.copy(f, target);
                    copied++;
                } catch (Throwable t) { Logx.w("client overlay copy failed: " + rel + " : " + t); }
            }
        }
        saveManifest(manifestSet);
        Logx.i("client overlay applied files=" + copied + " manifest=" + manifestSet.size());
        return copied;
    }

    /** 还原所有被覆盖的文件（有备份的恢复，本不存在的删除）。 */
    public static int restoreAll() {
        int n = 0;
        Set<String> manifestSet = loadManifest();
        for (String line : manifestSet) {
            try {
                boolean hadOriginal = !line.startsWith("!");
                String rel = hadOriginal ? line : line.substring(1);
                File target = new File(CLIENT_FILES, rel);
                String targetRel = rel.startsWith("bundle/") ? ("bundles/" + rel.substring("bundle/".length())) : rel;
                File realTarget = new File(CLIENT_FILES, targetRel);
                if (hadOriginal) {
                    File bak = new File(BACKUP_DIR, rel);
                    if (bak.exists()) { FileOps.copy(bak, realTarget); n++; }
                } else {
                    if (realTarget.exists() && realTarget.delete()) n++;
                }
            } catch (Throwable t) { Logx.w("client overlay restore failed: " + line + " : " + t); }
        }
        try { manifest().delete(); } catch (Throwable ignored) { }
        try { deleteTree(backupRoot()); } catch (Throwable ignored) { }
        Logx.i("client overlay restored files=" + n);
        return n;
    }

    private static void deleteTree(File f) {
        if (f == null || !f.exists()) return;
        if (f.isFile()) { f.delete(); return; }
        File[] kids = f.listFiles();
        if (kids != null) for (File k : kids) deleteTree(k);
        f.delete();
    }
}
