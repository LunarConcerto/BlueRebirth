package com.bluerebirth.mods;

import android.util.Log;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public final class Logx {
    public static final String TAG = "BlueRebirthMod";
    private static volatile File logFile;

    public static void init(File logsDir) {
        try {
            if (logsDir != null) {
                logsDir.mkdirs();
                logFile = new File(logsDir, "mods.log");
            }
        } catch (Throwable ignored) { }
    }

    public static void i(String msg) {
        try { Log.i(TAG, msg); } catch (Throwable ignored) { }
        append("I", msg);
    }

    public static void w(String msg) {
        try { Log.w(TAG, msg); } catch (Throwable ignored) { }
        append("W", msg);
    }

    public static void e(String msg, Throwable t) {
        try { Log.e(TAG, msg, t); } catch (Throwable ignored) { }
        append("E", msg + (t == null ? "" : (" :: " + Log.getStackTraceString(t))));
    }

    private static void append(String level, String msg) {
        File f = logFile;
        if (f == null) return;
        try {
            String ts = new SimpleDateFormat("MM-dd HH:mm:ss.SSS", Locale.US).format(new Date());
            FileOutputStream fos = new FileOutputStream(f, true);
            OutputStreamWriter w = new OutputStreamWriter(fos, "UTF-8");
            w.write(ts + " " + level + " " + msg + "\n");
            w.flush();
            w.close();
        } catch (Throwable ignored) { }
    }
}
