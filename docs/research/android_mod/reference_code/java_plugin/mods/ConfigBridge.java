package com.bluerebirth.mods;

import org.luaj.vm2.LuaError;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.VarArgFunction;
import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Emulates the PC payload "configManager" Lua object: lets normal PC mods
 * (mod.watch_global("configManager", ...)) patch server config_*.db data.
 */
public final class ConfigBridge {
    private static final LinkedHashMap<String, LinkedHashMap<String, String>> cache =
            new LinkedHashMap<String, LinkedHashMap<String, String>>();
    private static final LinkedHashSet<String> touched = new LinkedHashSet<String>();
    private static LuaTable manager;
    private static LuaValue javaGetData;

    public static LuaTable createManager() {
        manager = new LuaTable();
        javaGetData = new VarArgFunction() {
            public Varargs invoke(Varargs args) {
                return getData(args.checkjstring(1));
            }
        };
        manager.set("GetData", javaGetData);
        manager.set("GetDataById", new VarArgFunction() {
            public Varargs invoke(Varargs args) {
                String name = args.checkjstring(1);
                LuaTable data = getData(name);
                LuaValue v = data.get(idKey(args.arg(2).tojstring()));
                return v;
            }
        });
        return manager;
    }

    public static LuaTable getData(String name) {
        touched.add(name);
        LinkedHashMap<String, String> entries = cache.get(name);
        if (entries == null) {
            try {
                entries = ConfigStore.read(name);
            } catch (Throwable t) {
                throw new LuaError("read config " + name + " failed: " + t);
            }
            cache.put(name, entries);
        }
        LuaTable t = new LuaTable();
        for (Map.Entry<String, String> e : entries.entrySet()) {
            try {
                t.set(idKey(e.getKey()), jsonToLua(MiniJson.parse(e.getValue())));
            } catch (Throwable x) {
                Logx.w("bad json in " + name + " id=" + e.getKey() + ": " + x);
            }
        }
        return t;
    }

    static LuaValue idKey(String id) {
        try {
            long l = Long.parseLong(id);
            return LuaValue.valueOf(l);
        } catch (Throwable t) {
            return LuaValue.valueOf(id);
        }
    }

    @SuppressWarnings("unchecked")
    static LuaValue jsonToLua(Object v) {
        if (v == null) return LuaValue.NIL;
        if (v instanceof Map) {
            LuaTable t = new LuaTable();
            for (Map.Entry<String, Object> e : ((Map<String, Object>) v).entrySet()) {
                t.set(LuaValue.valueOf(e.getKey()), jsonToLua(e.getValue()));
            }
            return t;
        }
        if (v instanceof List) {
            LuaTable t = new LuaTable();
            int i = 1;
            for (Object o : (List<Object>) v) {
                t.set(i, jsonToLua(o));
                i++;
            }
            return t;
        }
        if (v instanceof String) return LuaValue.valueOf((String) v);
        if (v instanceof Boolean) return LuaValue.valueOf(((Boolean) v).booleanValue());
        if (v instanceof Number) {
            double d = ((Number) v).doubleValue();
            if (d == Math.rint(d) && Math.abs(d) < 9.007199254740992E15) return LuaValue.valueOf((long) d);
            return LuaValue.valueOf(d);
        }
        return LuaValue.valueOf(String.valueOf(v));
    }

    static Object luaToJson(LuaValue v) { return luaToJson(v, null); }

    /**
     * Lua -> JSON with optional original-JSON template so that empty containers and
     * numeric-looking strings keep their original JSON type.
     */
    static Object luaToJson(LuaValue v, Object orig) {
        if (v == null || v.isnil()) return null;
        if (v.isboolean()) return Boolean.valueOf(v.toboolean());
        int tp = v.type();
        if (tp == LuaValue.TSTRING) return v.tojstring();
        if (tp == LuaValue.TNUMBER) {
            double d = v.todouble();
            if (d == Math.rint(d) && Math.abs(d) < 9.007199254740992E15) return Long.valueOf((long) d);
            return Double.valueOf(d);
        }
        if (!v.istable()) return v.tojstring();
        LuaTable t = v.checktable();
        List<Object> keys = new ArrayList<Object>();
        List<LuaValue> vals = new ArrayList<LuaValue>();
        LuaValue k = LuaValue.NIL;
        while (true) {
            Varargs n = t.next(k);
            k = n.arg1();
            if (k.isnil()) break;
            keys.add(k);
            vals.add(n.arg(2));
        }
        if (keys.isEmpty()) {
            // empty table: follow the original JSON container type when known
            if (orig instanceof Map) return new LinkedHashMap<String, Object>();
            return new ArrayList<Object>();
        }
        boolean array = true;
        int max = 0;
        for (Object key : keys) {
            LuaValue lv = (LuaValue) key;
            if (!lv.isnumber()) { array = false; break; }
            double d = lv.todouble();
            if (d != Math.rint(d) || d < 1 || d > 1000000) { array = false; break; }
            int iv = (int) d;
            if (iv > max) max = iv;
            if (t.get(iv).isnil()) { array = false; break; }
        }
        if (array && max == keys.size()) {
            List<Object> list = new ArrayList<Object>();
            List<?> olist = (orig instanceof List) ? (List<?>) orig : null;
            for (int i = 1; i <= max; i++) {
                Object child = (olist != null && i - 1 < olist.size()) ? olist.get(i - 1) : null;
                list.add(luaToJson(t.get(i), child));
            }
            return list;
        }
        Map<String, Object> m = new LinkedHashMap<String, Object>();
        Map<?, ?> omap = (orig instanceof Map) ? (Map<?, ?>) orig : null;
        for (int i = 0; i < keys.size(); i++) {
            String key = ((LuaValue) keys.get(i)).tojstring();
            Object child = (omap != null) ? omap.get(key) : null;
            m.put(key, luaToJson(vals.get(i), child));
        }
        return m;
    }

    /** Call candidates from the (possibly mod-wrapped) configManager.GetData and persist changes. */
    public static void finish(Collection<String> candidates) {
        if (manager == null) return;
        LuaValue cur = manager.get("GetData");
        if (cur.isnil() || cur.equals(javaGetData)) {
            Logx.i("configManager not patched by any mod; nothing to write");
            cache.clear();
            touched.clear();
            return;
        }
        LinkedHashSet<String> names = new LinkedHashSet<String>();
        names.addAll(touched);
        if (candidates != null) names.addAll(candidates);
        int applied = 0;
        for (String name : names) {
            File f = ConfigStore.dbFile(name);
            if (!f.exists()) continue;
            try {
                LuaValue res = cur.invoke(LuaValue.valueOf(name)).arg1();
                if (!res.istable()) continue;
                if (diffAndWrite(name, res.checktable())) applied++;
            } catch (Throwable t) {
                Logx.e("apply config " + name + " failed", t);
            }
        }
        Logx.i("config bridge finished; dbs changed=" + applied);
        cache.clear();
        touched.clear();
    }

    private static boolean diffAndWrite(String name, LuaTable data) throws Exception {
        LinkedHashMap<String, String> orig = cache.get(name);
        if (orig == null) {
            orig = ConfigStore.read(name);
            cache.put(name, orig);
        }
        Map<String, String> updates = new LinkedHashMap<String, String>();
        Set<String> seen = new HashSet<String>();
        LuaValue k = LuaValue.NIL;
        while (true) {
            Varargs n = data.next(k);
            k = n.arg1();
            if (k.isnil()) break;
            LuaValue v = n.arg(2);
            String id = k.tojstring();
            seen.add(id);
            String ojson = orig.get(id);
            Object ov = null;
            if (ojson != null) {
                try { ov = MiniJson.parse(ojson); } catch (Throwable ignored) { }
            }
            Object nv = luaToJson(v, ov);
            String jsonNew = MiniJson.write(nv);
            String canNew = MiniJson.writeSorted(normalizeEmpty(nv));
            if (ojson == null) {
                updates.put(id, jsonNew);
            } else {
                try {
                    if (!canNew.equals(MiniJson.writeSorted(normalizeEmpty(MiniJson.parse(ojson))))) {
                        updates.put(id, jsonNew);
                    }
                } catch (Throwable t) {
                    updates.put(id, jsonNew);
                }
            }
        }
        // Safety: never delete server config rows; a mod returning a filtered table
        // must not wipe the database. Only insert/update are persisted.
        int dropped = 0;
        for (String id : orig.keySet()) if (!seen.contains(id)) dropped++;
        if (dropped > 0) Logx.w("config " + name + ": " + dropped + " row(s) absent from mod table; kept (no delete)");
        List<String> deletes = new ArrayList<String>();
        if (updates.isEmpty()) return false;
        ConfigStore.write(name, updates, deletes);
        ModState.get().markLua("config/" + (name.endsWith(".db") ? name : name + ".db"));
        Logx.i("config " + name + " -> updates=" + updates.size() + " deletes=" + deletes.size());
        return true;
    }

    /** Treat an empty JSON object and an empty JSON array as equal when comparing. */
    @SuppressWarnings("unchecked")
    private static Object normalizeEmpty(Object v) {
        if (v instanceof Map) {
            Map<String, Object> m = (Map<String, Object>) v;
            if (m.isEmpty()) return new ArrayList<Object>();
            Map<String, Object> out = new LinkedHashMap<String, Object>();
            for (Map.Entry<String, Object> e : m.entrySet()) out.put(e.getKey(), normalizeEmpty(e.getValue()));
            return out;
        }
        if (v instanceof List) {
            List<Object> l = (List<Object>) v;
            List<Object> out = new ArrayList<Object>();
            for (Object o : l) out.add(normalizeEmpty(o));
            return out;
        }
        return v;
    }

    public static void reset() {
        cache.clear();
        touched.clear();
        manager = null;
        javaGetData = null;
    }
}
