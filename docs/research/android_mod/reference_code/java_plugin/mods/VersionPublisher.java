package com.bluerebirth.mods;

import java.io.File;
import java.util.List;
import java.util.Map;

/**
 * Keeps the server-advertised client version in sync with the currently applied Mods.
 *
 * The version is read once by the server from files/kit-client-version.txt at startup.
 * Whenever the set of enabled bundle-mods changes (enable / disable / purge) we bump the
 * version so the game client runs a hot-update pass, which re-syncs its cached assetmap
 * and content (this is the only way to "clear" the client cache without root access).
 * The version is monotonic: it never goes backwards.
 */
public final class VersionPublisher {
    private static final String VERSION_FILE = "kit-client-version.txt";
    private static final String STATE_FILE = "mod-version-state.json";
    private static final String DEFAULT_VERSION = "1.4.140";
    public static final String CLEAN_SIGNATURE = "CLEAN";

    public static void publish(String signature) { publish(signature, null); }

    public static void publish(String signature, String desiredMinVersion) {
        try {
            File versionFile = new File(ModPaths.privateDir, VERSION_FILE);
            File stateFile = new File(ModPaths.privateDir, STATE_FILE);
            String fileVer = readTrim(versionFile);
            Map<String, Object> state = readState(stateFile);
            String base = state == null ? null : str(state.get("base"));
            String current = state == null ? null : str(state.get("current"));
            String lastSig = state == null ? null : str(state.get("signature"));
            if (base == null || base.length() == 0) base = DEFAULT_VERSION;
            if (current == null || current.length() == 0) current = base;
            // the file may be re-written by a kit reinstall: never go backwards
            if (fileVer != null && compare(fileVer, current) > 0) current = fileVer;
            if (signature == null || signature.length() == 0) signature = CLEAN_SIGNATURE;

            if (lastSig != null && lastSig.equals(signature)) {
                // nothing changed: make sure the file equals our current version
                if (!current.equals(fileVer)) writeText(versionFile, current);
                return;
            }
            // content set changed -> bump past everything the client may have seen
            String from = higher(base, higher(current, fileVer));
            String next = bump(from);
            if (desiredMinVersion != null && desiredMinVersion.trim().length() > 0
                    && compare(desiredMinVersion.trim(), next) > 0) {
                next = desiredMinVersion.trim();
            }
            writeText(versionFile, next);
            Map<String, Object> ns = new java.util.LinkedHashMap<String, Object>();
            ns.put("base", base);
            ns.put("current", next);
            ns.put("signature", signature);
            writeText(stateFile, MiniJson.write(ns));
            Logx.i("content changed (" + signature + "): client version " + from + " -> " + next);
        } catch (Throwable t) {
            Logx.e("VersionPublisher failed", t);
        }
    }

    /**
     * Restore the real kit version (1.4.140) - used by "restore vanilla" after the client
     * hot-update state has been purged, so the client does a clean first-sync instead of a downgrade.
     */
    public static void resetToVanillaBase() {
        try {
            File stateFile = new File(ModPaths.privateDir, STATE_FILE);
            String base = DEFAULT_VERSION;
            try {
                Map<String, Object> state = readState(stateFile);
                if (state != null && state.get("base") != null) base = String.valueOf(state.get("base"));
            } catch (Throwable ignored) { }
            writeText(new File(ModPaths.privateDir, VERSION_FILE), base);
            // keep the CLEAN signature so the apply() that follows does not bump the version again
            Map<String, Object> ns = new java.util.LinkedHashMap<String, Object>();
            ns.put("base", base);
            ns.put("current", base);
            ns.put("signature", CLEAN_SIGNATURE);
            writeText(stateFile, MiniJson.write(ns));
            Logx.i("vanilla version restored: " + base + " (state signature=CLEAN)");
        } catch (Throwable t) {
            Logx.e("resetToVanillaBase failed", t);
        }
    }

    /** Force a bump even when the signature is unchanged (used by the purge button). */
    public static void publishForceBump(String signature) {
        try {
            File stateFile = new File(ModPaths.privateDir, STATE_FILE);
            Map<String, Object> state = readState(stateFile);
            if (state != null) state.remove("signature");
            if (state != null) writeText(stateFile, MiniJson.write(state));
        } catch (Throwable ignored) { }
        publish(signature);
    }

    /** Highest numeric version among the given strings (null if none). */
    public static String highest(java.util.List<String> versions) {
        String best = null;
        if (versions == null) return null;
        for (String v : versions) {
            if (v == null || v.trim().length() == 0) continue;
            v = v.trim();
            if (best == null || compare(v, best) > 0) best = v;
        }
        return best;
    }

    public static String bump(String version) {
        if (version == null || version.length() == 0) version = DEFAULT_VERSION;
        String[] p = version.split("\\.");
        StringBuilder b = new StringBuilder();
        try {
            int last = Integer.parseInt(p[p.length - 1].replaceAll("[^0-9]", ""));
            for (int i = 0; i < p.length - 1; i++) b.append(p[i]).append('.');
            b.append(last + 1);
            String s = b.toString();
            return s.length() > 0 ? s : DEFAULT_VERSION;
        } catch (Throwable t) {
            return DEFAULT_VERSION + ".1";
        }
    }

    private static String higher(String a, String b) {
        if (a == null) return b;
        if (b == null) return a;
        return compare(a, b) >= 0 ? a : b;
    }

    public static int compare(String a, String b) {
        String[] pa = a.split("[.\\-]");
        String[] pb = b.split("[.\\-]");
        int n = Math.max(pa.length, pb.length);
        for (int i = 0; i < n; i++) {
            long va = i < pa.length ? parseLong(pa[i]) : 0;
            long vb = i < pb.length ? parseLong(pb[i]) : 0;
            if (va != vb) return va < vb ? -1 : 1;
        }
        return 0;
    }

    private static long parseLong(String s) {
        try { return Long.parseLong(s.replaceAll("[^0-9]", "")); } catch (Throwable t) { return 0; }
    }

    private static String readTrim(File f) {
        try { return f.exists() ? FileOps.readTextAuto(f).trim() : null; } catch (Throwable t) { return null; }
    }

    private static void writeText(File f, String s) {
        try {
            File p = f.getParentFile();
            if (p != null) p.mkdirs();
            FileOps.writeText(f, s);
        } catch (Throwable t) { Logx.e("write " + f, t); }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> readState(File f) {
        try {
            if (!f.exists()) return null;
            Object v = MiniJson.parse(FileOps.readTextAuto(f));
            return v instanceof Map ? (Map<String, Object>) v : null;
        } catch (Throwable t) { return null; }
    }

    private static String str(Object o) { return o == null ? null : String.valueOf(o); }
}
