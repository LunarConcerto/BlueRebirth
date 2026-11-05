package com.bluerebirth.mods;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;

/**
 * Clears the game client hot-update state so that the server can safely advertise the
 * ORIGINAL kit version again (1.4.140). Without this the client keeps its local content
 * version (stored in bundles/assetmap*) and refuses the "downgrade" -> endless "有可用更新".
 *
 * Android 11+ hides other apps' Android/data from us, so a root shell is also tried.
 * Success is reported as "remaining=0" in the return string.
 */
public final class ClientCache {
    public static final String CLIENT_PKG = "com.zephyrus.clsy.gp";
    private static final String REL_BASE = "/sdcard/Android/data/" + CLIENT_PKG + "/files/bundles";
    private static final String[] TARGETS = {"assetmap", "assetmap_target", "compressed", "external_files_list.txt"};

    public static String purgeHotUpdateCache() {
        StringBuilder sb = new StringBuilder();
        File base = new File(REL_BASE);
        int directOk = 0;
        if (base.isDirectory()) {
            for (String name : TARGETS) {
                File f = new File(base, name);
                if (!f.exists()) { directOk++; continue; }
                if (deleteRec(f) && !f.exists()) directOk++;
            }
            sb.append("direct_ok=").append(directOk).append(' ');
        } else {
            sb.append("direct_invisible ");
        }
        String root = tryRootDelete();
        sb.append("root=").append(root);
        String remaining = root.endsWith("remaining=0") ? "remaining=0" : "remaining=unknown";
        sb.append(' ').append(remaining);
        Logx.i("ClientCache.purgeHotUpdateCache -> " + sb);
        return sb.toString();
    }

    private static String tryRootDelete() {
        try {
            StringBuilder cmd = new StringBuilder("rm -rf");
            for (String name : TARGETS) cmd.append(' ').append(REL_BASE).append('/').append(name);
            cmd.append("; echo MARK; ls ").append(REL_BASE).append(" 2>/dev/null; echo DONE");
            final Process p = Runtime.getRuntime().exec(new String[]{"su", "-c", cmd.toString()});
            final StringBuilder out = new StringBuilder();
            Thread reader = new Thread(new Runnable() {
                public void run() {
                    try {
                        BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
                        String line;
                        while ((line = br.readLine()) != null) out.append(line).append('\n');
                    } catch (Throwable ignored) { }
                }
            });
            reader.start();
            boolean finished = false;
            try { finished = p.waitFor() == 0; } catch (InterruptedException ignored) { }
            if (!finished) { try { p.destroy(); } catch (Throwable ignored) { } return "failed_rc"; }
            reader.join(3000);
            String text = out.toString();
            int mark = text.indexOf("MARK");
            String listing = mark >= 0 ? text.substring(mark) : text;
            boolean any = false;
            for (String t : TARGETS) if (listing.contains(t + "\n") || listing.trim().endsWith(t) || listing.contains(" " + t + "\n")) any = true;
            Logx.i("ClientCache root listing: " + (listing.length() > 300 ? listing.substring(0, 300) : listing));
            return any ? "partial" : "remaining=0";
        } catch (Throwable t) {
            Logx.w("ClientCache root delete failed: " + t);
            return "no_root";
        }
    }

    private static boolean deleteRec(File f) {
        if (f == null || !f.exists()) return true;
        if (f.isDirectory()) {
            File[] cs = f.listFiles();
            if (cs != null) for (File c : cs) deleteRec(c);
        }
        return f.delete();
    }
}
