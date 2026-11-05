package com.bluerebirth.mods;

import java.io.File;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

/** Tracks which files mods overwrote/created and the pristine backups needed to undo them. */
public final class ModState {
    private static ModState inst;
    /** rel path -> true when a pristine backup exists, false when the mod created the file. */
    public final LinkedHashMap<String, Boolean> overlay = new LinkedHashMap<String, Boolean>();
    public final LinkedHashSet<String> lua = new LinkedHashSet<String>();

    public static synchronized ModState get() {
        if (inst == null) {
            inst = new ModState();
            inst.load();
        }
        return inst;
    }

    private File stateFile() { return new File(ModPaths.stateDir, "applied.json"); }
    private File backupRoot() { return new File(ModPaths.stateDir, "backup"); }

    public File backupFile(String rel) { return new File(backupRoot(), rel); }

    public synchronized void load() {
        overlay.clear();
        lua.clear();
        File f = stateFile();
        if (!f.exists()) return;
        try {
            Object root = MiniJson.parse(FileOps.readTextAuto(f));
            if (root instanceof Map) {
                Object of = ((Map<?, ?>) root).get("files");
                if (of instanceof Map) {
                    for (Map.Entry<?, ?> e : ((Map<?, ?>) of).entrySet()) {
                        boolean hasBackup = !(e.getValue() instanceof Number) || ((Number) e.getValue()).intValue() != 0;
                        overlay.put(String.valueOf(e.getKey()), Boolean.valueOf(hasBackup));
                    }
                }
                Object lu = ((Map<?, ?>) root).get("lua");
                if (lu instanceof List) for (Object k : (List<?>) lu) lua.add(String.valueOf(k));
            }
        } catch (Throwable t) {
            Logx.e("state load failed", t);
        }
    }

    public synchronized void save() {
        try {
            Map<String, Object> root = new LinkedHashMap<String, Object>();
            Map<String, Object> fm = new LinkedHashMap<String, Object>();
            for (Map.Entry<String, Boolean> e : overlay.entrySet()) {
                fm.put(e.getKey(), Integer.valueOf(Boolean.TRUE.equals(e.getValue()) ? 1 : 0));
            }
            List<Object> ll = new ArrayList<Object>();
            ll.addAll(lua);
            root.put("files", fm);
            root.put("lua", ll);
            FileOps.writeText(stateFile(), MiniJson.write(root));
        } catch (Throwable t) {
            Logx.e("state save failed", t);
        }
    }

    /** @return true when a pristine backup now exists (false when the file did not exist before). */
    public synchronized boolean backupFileIfNeeded(String rel) {
        File src = new File(ModPaths.hotDir, rel);
        File bak = backupFile(rel);
        if (bak.exists()) return true;
        if (!src.exists()) return false;
        try {
            bak.getParentFile().mkdirs();
            FileOps.copy(src, bak);
            Logx.i("backup " + rel);
            return true;
        } catch (Throwable t) {
            Logx.e("backup failed " + rel, t);
            return false;
        }
    }

    public synchronized void restore(String rel) {
        Boolean hasBackup = overlay.get(rel);
        File bak = backupFile(rel);
        File dst = new File(ModPaths.hotDir, rel);
        try {
            if (bak.exists()) {
                FileOps.copy(bak, dst);
                FileOps.deleteRec(bak);
                Logx.i("restored " + rel);
            } else if (Boolean.FALSE.equals(hasBackup) && dst.exists()) {
                FileOps.deleteRec(dst);
                Logx.i("deleted mod-created " + rel);
            }
        } catch (Throwable t) {
            Logx.e("restore failed " + rel, t);
        }
        overlay.remove(rel);
        lua.remove(rel);
    }

    public synchronized void markOverlay(String rel, boolean hasBackup) { overlay.put(rel, Boolean.valueOf(hasBackup)); }
    public synchronized void markLua(String rel) { lua.add(rel); }

    public synchronized void restoreLuaBackups() {
        List<String> names = new ArrayList<String>(lua);
        for (String rel : names) restore(rel);
        save();
    }

    public synchronized void restoreStaleOverlays(java.util.Set<String> desired) {
        List<String> names = new ArrayList<String>(overlay.keySet());
        for (String rel : names) if (!desired.contains(rel)) restore(rel);
        save();
    }
}
