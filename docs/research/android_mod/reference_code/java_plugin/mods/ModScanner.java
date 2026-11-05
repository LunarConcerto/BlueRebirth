package com.bluerebirth.mods;

import org.json.JSONObject;
import java.io.File;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class ModScanner {
    private static final Pattern ENTRY = Pattern.compile("[\"']([^\"'\\r\\n]+?\\.mod/[^\"'\\r\\n]+?)[\"']");
    private static final Pattern LUA_LINE_COMMENT = Pattern.compile("--[^\\r\\n]*");
    private static final Pattern LUA_BLOCK_COMMENT = Pattern.compile("--\\[\\[.*?\\]\\]", Pattern.DOTALL);

    public static List<ModInfo> scan(File modsDir) {
        List<ModInfo> out = new ArrayList<ModInfo>();
        File[] children = modsDir == null ? null : modsDir.listFiles();
        if (children == null) return out;
        Set<String> bootstrapEntries = readBootstrapEntries(modsDir);
        for (File d : children) {
            if (d == null || !d.isDirectory()) continue;
            String n = d.getName();
            if (n.startsWith(".")) continue;
            if (!n.endsWith(".mod")) continue;
            ModInfo m = parse(d);
            if (m == null) continue;
            if (bootstrapEntries != null) {
                boolean found = false;
                for (String e : bootstrapEntries) {
                    String norm = e.replace('\\', '/');
                    if (norm.startsWith(m.id + "/") || norm.equals(m.id)) { found = true; break; }
                }
                m.enabled = found;
            }
            out.add(m);
        }
        Collections.sort(out, new Comparator<ModInfo>() {
            public int compare(ModInfo a, ModInfo b) {
                if (a.loadOrder != b.loadOrder) return a.loadOrder < b.loadOrder ? -1 : 1;
                return a.id.compareTo(b.id);
            }
        });
        return out;
    }

    private static String stripLuaComments(String text) {
        String t = LUA_BLOCK_COMMENT.matcher(text).replaceAll("");
        return LUA_LINE_COMMENT.matcher(t).replaceAll("");
    }

    /** null when no PC style bootstrap.lua or it declares no entries (fall back to mod.json). */
    public static Set<String> readBootstrapEntries(File modsDir) {
        if (modsDir == null) return null;
        File bs = new File(modsDir, "bootstrap.lua");
        if (!bs.exists()) return null;
        LinkedHashSet<String> set = new LinkedHashSet<String>();
        try {
            String text = stripLuaComments(FileOps.readTextAuto(bs));
            Matcher m = ENTRY.matcher(text);
            while (m.find()) set.add(m.group(1).trim());
        } catch (Throwable t) {
            Logx.w("bootstrap.lua read failed: " + t);
            return null;
        }
        if (set.isEmpty()) {
            Logx.w("bootstrap.lua exists but has no entries; falling back to mod.json.enabled");
            return null;
        }
        return set;
    }

    public static ModInfo parse(File d) {
        File mj = new File(d, "mod.json");
        if (!mj.exists()) {
            File ml = new File(d, "main.lua");
            if (!ml.exists()) return null;
        }
        ModInfo m = new ModInfo();
        m.id = d.getName();
        m.name = d.getName();
        m.dir = d;
        if (mj.exists()) {
            try {
                JSONObject o = new JSONObject(FileOps.readTextAuto(mj));
                if (o.has("id")) m.id = o.optString("id", m.id);
                if (o.has("name")) m.name = o.optString("name", m.name);
                if (o.has("version")) m.version = o.optString("version", null);
                if (o.has("description")) m.description = o.optString("description", null);
                if (o.has("author")) m.author = o.optString("author", null);
                if (o.has("entry")) m.entry = o.optString("entry", "main.lua");
                if (o.has("loadOrder")) m.loadOrder = o.optInt("loadOrder", 100);
                if (o.has("clientVersion")) m.clientVersion = o.optString("clientVersion", null);
                m.enabled = o.optBoolean("enabled", true);
            } catch (Throwable t) {
                Logx.w("mod.json parse failed for " + d.getName() + ": " + t);
            }
        }
        return m;
    }

    /** Persist enabled state: mod.json.enabled plus a clean rewrite of PC bootstrap.lua entries. */
    public static boolean setEnabled(ModInfo m, boolean enabled) {
        m.enabled = enabled;
        File mj = new File(m.dir, "mod.json");
        try {
            JSONObject o;
            if (mj.exists()) o = new JSONObject(FileOps.readTextAuto(mj));
            else o = new JSONObject();
            o.put("enabled", enabled);
            if (!o.has("id")) o.put("id", m.id);
            if (!o.has("entry")) o.put("entry", m.entry);
            FileOps.writeText(mj, o.toString(2));
        } catch (Throwable t) {
            Logx.e("write mod.json failed: " + m.id, t);
        }
        return updateBootstrap(m, enabled);
    }

    private static boolean updateBootstrap(ModInfo m, boolean enabled) {
        File bs = new File(ModPaths.modsDir, "bootstrap.lua");
        if (!bs.exists()) return true;
        try {
            String text = FileOps.readTextAuto(bs);
            String stripped = stripLuaComments(text);
            LinkedHashSet<String> entries = new LinkedHashSet<String>();
            Matcher mt = ENTRY.matcher(stripped);
            while (mt.find()) entries.add(mt.group(1).trim());
            String rel = m.id + "/" + (m.entry == null ? "main.lua" : m.entry);
            if (enabled) entries.add(rel);
            else entries.remove(rel);
            StringBuilder block = new StringBuilder("local entries = {\n");
            for (String e : entries) block.append("  \"").append(e).append("\",\n");
            block.append("}");
            // locate the entries table literal (balanced braces, comments stripped)
            int key = stripped.indexOf("local entries");
            if (key < 0) key = stripped.indexOf("entries =");
            String outText;
            if (key >= 0) {
                int open = text.indexOf('{', key);
                if (open < 0) return false;
                int depth = 0, close = -1;
                for (int i = open; i < text.length(); i++) {
                    char c = text.charAt(i);
                    if (c == '{') depth++;
                    else if (c == '}') { depth--; if (depth == 0) { close = i; break; } }
                }
                if (close < 0) return false;
                outText = text.substring(0, key) + block + text.substring(close + 1);
            } else {
                outText = text + "\n" + block + "\n";
            }
            FileOps.writeText(bs, outText);
            return true;
        } catch (Throwable t) {
            Logx.e("update bootstrap.lua failed", t);
            return false;
        }
    }
}
