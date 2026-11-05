package com.bluerebirth.savesync;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;
import com.bluerebirth.mods.Logx;
import com.bluerebirth.mods.ModLoader;

/** Runs earliest in app startup, before the .NET server reads its hot-update config. */
public class SaveSyncProvider extends ContentProvider {
    public boolean onCreate() {
        try {
            ModLoader.init(getContext());
        } catch (Throwable t) {
            try { Logx.e("provider init failed", t); } catch (Throwable ignored) { }
        }
        return true;
    }

    public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) { return null; }
    public String getType(Uri uri) { return null; }
    public Uri insert(Uri uri, ContentValues values) { return null; }
    public int delete(Uri uri, String selection, String[] selectionArgs) { return 0; }
    public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) { return 0; }
}
