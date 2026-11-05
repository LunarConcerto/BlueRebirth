package com.bluerebirth.mods;

import android.content.Context;
import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.VarArgFunction;
import org.luaj.vm2.lib.jse.JsePlatform;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Runs PC-compatible Mods/*.mod/main.lua scripts inside the launcher. */
public final class LuaRuntime {
    private static final Pattern CONFIG_NAME = Pattern.compile("config_[a-zA-Z0-9_]+");
    private static final Pattern GLOBAL_CONFIG = Pattern.compile("[\"']?(config_[a-zA-Z0-9_]+)[\"']?");

    public static void run(Context ctx, List<ModInfo> mods, String bootstrapSource) {
        Logx.i("lua runtime starting; mods=" + mods.size());
        Globals g = JsePlatform.standardGlobals();
        g.load(new org.luaj.vm2.lib.DebugLib());
        patchDebug(g);
        g.set("__BLUEOATH_MOD_ROOT", LuaValue.valueOf(ModPaths.modsDir.getAbsolutePath()));
        g.set("__blueoath_loadfile", new LoadFileFn(g));
        g.set("__blueoath_log", new OneArgFunction() {
            public LuaValue call(LuaValue arg) {
                Logx.i(arg.tojstring());
                return LuaValue.NIL;
            }
        });
        LuaTable entries = new LuaTable();
        int idx = 1;
        for (ModInfo m : mods) {
            File main = new File(m.dir, m.entry == null ? "main.lua" : m.entry);
            if (!main.exists()) continue;
            String rel = ModPaths.rel(main, ModPaths.modsDir);
            entries.set(idx, LuaValue.valueOf(rel));
            idx++;
        }
        g.set("__BLUEOATH_MOD_ENTRIES", entries);
        g.set("__blueoath_mod_api", new ApiFactory());
        g.set("configManager", ConfigBridge.createManager());
        LuaValue chunk = g.load(bootstrapSource, "@bluerebirth-bootstrap.lua");
        chunk.call();
        Set<String> candidates = new LinkedHashSet<String>();
        for (ModInfo m : mods) collectConfigNames(m, candidates);
        ConfigBridge.finish(candidates);
        Logx.i("lua runtime finished");
    }


    /** LuaJ's debug library lacks traceback()/setupvalue() on some versions; add fallbacks. */
    private static void patchDebug(Globals g) {
        try {
            LuaValue dbg = g.get("debug");
            if (!dbg.istable()) {
                dbg = new LuaTable();
                g.set("debug", dbg);
            }
            LuaTable t = dbg.checktable();
            if (t.get("traceback").isnil()) {
                t.set("traceback", new OneArgFunction() {
                    public LuaValue call(LuaValue arg) {
                        return LuaValue.valueOf(arg.isnil() ? "" : arg.tojstring());
                    }
                });
            }
        } catch (Throwable ignored) { }
    }

    private static void collectConfigNames(ModInfo m, Set<String> out) {
        try {
            List<File> fs = FileOps.listFilesRec(m.dir);
            for (File f : fs) {
                String n = f.getName();
                if (!(n.endsWith(".lua") || n.endsWith(".json") || n.endsWith(".txt"))) continue;
                if (f.length() > 2 * 1024 * 1024) continue;
                String txt = FileOps.readText(f);
                Matcher mt = CONFIG_NAME.matcher(txt);
                while (mt.find()) {
                    String name = mt.group();
                    if (ConfigStore.dbFile(name).exists()) out.add(name);
                }
            }
        } catch (Throwable t) {
            Logx.w("collect config names failed for " + m.id + ": " + t);
        }
    }

    /** Collect the first N string arguments (Lua colon-call may pass the mod table first). */
    static String[] strings(Varargs a, int count) {
        String[] out = new String[count];
        int n = 0;
        for (int i = 1; i <= a.narg() && n < count; i++) {
            LuaValue v = a.arg(i);
            if (v.isstring()) out[n++] = v.tojstring();
        }
        return n == count ? out : null;
    }

    static final class LoadFileFn extends OneArgFunction {
        private final Globals g;
        LoadFileFn(Globals g) { this.g = g; }
        public LuaValue call(LuaValue arg) {
            String rel = arg.checkjstring();
            File f = new File(ModPaths.modsDir, rel);
            try {
                String text = FileOps.readTextAuto(f);
                return g.load(text, "@" + rel);
            } catch (Throwable t) {
                return LuaValue.NIL;
            }
        }
    }

    static final class ApiFactory extends OneArgFunction {
        public LuaValue call(LuaValue entryArg) {
            final String entry = entryArg.checkjstring();
            int slash = entry.lastIndexOf('/');
            final String modDir = slash > 0 ? entry.substring(0, slash) : entry;
            LuaTable t = new LuaTable();
            t.set("copy", new VarArgFunction() {
                public Varargs invoke(Varargs a) {
                    try {
                        // supports both mod.copy(src,dst) and mod:copy(src,dst)
                        String[] ss = strings(a, 2);
                        if (ss == null) return LuaValue.FALSE;
                        String src = ss[0];
                        String dst = ss[1];
                        File s = new File(new File(ModPaths.modsDir, modDir), src);
                        File d = new File(ModPaths.hotDir, dst);
                        FileOps.copy(s, d);
                        return LuaValue.TRUE;
                    } catch (Throwable x) {
                        Logx.e("mod.copy failed: " + x, x);
                        return LuaValue.FALSE;
                    }
                }
            });
            t.set("write", new VarArgFunction() {
                public Varargs invoke(Varargs a) {
                    try {
                        String[] ss = strings(a, 2);
                        if (ss == null) return LuaValue.FALSE;
                        FileOps.writeText(new File(ModPaths.hotDir, ss[0]), ss[1]);
                        return LuaValue.TRUE;
                    } catch (Throwable x) {
                        Logx.e("mod.write failed: " + x, x);
                        return LuaValue.FALSE;
                    }
                }
            });
            t.set("hot_dir", new OneArgFunction() {
                public LuaValue call(LuaValue a) { return LuaValue.valueOf(ModPaths.hotDir.getAbsolutePath()); }
            });
            t.set("mods_dir", new OneArgFunction() {
                public LuaValue call(LuaValue a) { return LuaValue.valueOf(ModPaths.modsDir.getAbsolutePath()); }
            });
            t.set("saves_dir", new OneArgFunction() {
                public LuaValue call(LuaValue a) { return LuaValue.valueOf(ModPaths.savesDir.getAbsolutePath()); }
            });
            t.set("log", new OneArgFunction() {
                public LuaValue call(LuaValue a) { Logx.i("[" + modDir + "] " + a.tojstring()); return LuaValue.NIL; }
            });
            return t;
        }
    }
}
