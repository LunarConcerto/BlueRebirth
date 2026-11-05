package com.bluerebirth.mods;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import java.io.File;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;

/** Reads/writes the XOR-0x55 JSON payloads in the server config_*.db SQLite files. */
public final class ConfigStore {
    public static final byte XOR = 0x55;

    public static File dbFile(String name) {
        String n = name.endsWith(".db") ? name : name + ".db";
        return new File(ModPaths.hotConfig(), n);
    }

    public static LinkedHashMap<String, String> read(String name) throws Exception {
        File f = dbFile(name);
        if (!f.exists()) throw new RuntimeException("config db not found: " + f);
        LinkedHashMap<String, String> map = new LinkedHashMap<String, String>();
        SQLiteDatabase db = SQLiteDatabase.openDatabase(f.getAbsolutePath(), null, SQLiteDatabase.OPEN_READONLY);
        try {
            Cursor c = db.rawQuery("select id, jsonbytes from DBObject", null);
            try {
                while (c.moveToNext()) {
                    String id = c.getString(0);
                    byte[] blob = c.getBlob(1);
                    if (id == null || blob == null) continue;
                    if ("nill".equals(id)) continue;
                    byte[] dec = new byte[blob.length];
                    for (int i = 0; i < blob.length; i++) dec[i] = (byte) (blob[i] ^ XOR);
                    map.put(id, new String(dec, "UTF-8"));
                }
            } finally { c.close(); }
        } finally { db.close(); }
        Logx.i("config read " + name + " entries=" + map.size());
        return map;
    }

    public static void write(String name, Map<String, String> updates, Collection<String> deletes) throws Exception {
        if ((updates == null || updates.isEmpty()) && (deletes == null || deletes.isEmpty())) return;
        File f = dbFile(name);
        ModState.get().backupFileIfNeeded("config/" + f.getName());
        SQLiteDatabase db = SQLiteDatabase.openDatabase(f.getAbsolutePath(), null, SQLiteDatabase.OPEN_READWRITE);
        try {
            if (updates != null) {
                for (Map.Entry<String, String> e : updates.entrySet()) {
                    byte[] json = e.getValue().getBytes("UTF-8");
                    byte[] enc = new byte[json.length];
                    for (int i = 0; i < json.length; i++) enc[i] = (byte) (json[i] ^ XOR);
                    ContentValues cv = new ContentValues();
                    cv.put("jsonbytes", enc);
                    int n = db.update("DBObject", cv, "id=?", new String[]{e.getKey()});
                    if (n <= 0) {
                        ContentValues nv = new ContentValues();
                        nv.put("id", e.getKey());
                        nv.put("indexid", e.getKey());
                        nv.put("jsonbytes", enc);
                        db.insertWithOnConflict("DBObject", null, nv, SQLiteDatabase.CONFLICT_REPLACE);
                    }
                }
            }
            if (deletes != null) {
                for (String id : deletes) {
                    db.execSQL("delete from DBObject where id=?", new Object[]{id});
                }
            }
        } finally { db.close(); }
        Logx.i("config write " + name + " updates=" + (updates == null ? 0 : updates.size())
                + " deletes=" + (deletes == null ? 0 : deletes.size()));
    }
}
