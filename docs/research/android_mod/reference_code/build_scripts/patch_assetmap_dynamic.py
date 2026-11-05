
# -*- coding: utf-8 -*-
import io, os
ROOT = r'E:/苍蓝_work/work/lead/modsrc/src/com/bluerebirth/mods'
def rd(p): return io.open(p, encoding='utf-8').read()
def wr(p, s): io.open(p, 'w', encoding='utf-8', newline='\n').write(s)

# ---------- AssetmapVersionPatcher.java ----------
wr(os.path.join(ROOT, 'AssetmapVersionPatcher.java'), r'''package com.bluerebirth.mods;

import java.io.File;

/** 动态把服务端热更目录里的 assetmap 内部第一行版本号改成 kit-client-version.txt 的当前版本。
 *  需要 assetmap 是未压缩 UnityFS（打包时用 packer=none），版本号以明文存在于文件中。 */
public final class AssetmapVersionPatcher {
    public static void sync() {
        try {
            File hot = new File(ModPaths.hotDir, "assetmap");
            File vf = new File(ModPaths.privateDir, "kit-client-version.txt");
            if (!hot.exists()) { Logx.w("assetmap patch: assetmap missing"); return; }
            if (!vf.exists()) { Logx.w("assetmap patch: version file missing"); return; }
            String version = FileOps.readTextAuto(vf);
            if (version == null) return;
            version = version.trim();
            if (!isVersion(version)) { Logx.w("assetmap patch: bad version '" + version + "'"); return; }
            byte[] data = FileOps.readBytes(hot);
            if (data == null || data.length < 32) return;
            int[] loc = findVersionLine(data);
            if (loc == null) { Logx.w("assetmap patch: plaintext version line not found (compressed assetmap?)"); return; }
            int start = loc[0];
            int len = loc[1];
            String old = new String(data, start, len, "UTF-8");
            if (old.equals(version)) { Logx.i("assetmap version already " + version); return; }
            byte[] nv = version.getBytes("UTF-8");
            if (nv.length != len) { Logx.w("assetmap patch: length mismatch " + len + " -> " + nv.length); return; }
            System.arraycopy(nv, 0, data, start, len);
            FileOps.writeBytes(hot, data);
            Logx.i("assetmap version patched: " + old + " -> " + version);
        } catch (Throwable t) { Logx.w("assetmap patch failed: " + t); }
    }

    private static boolean isVersion(String s) {
        try { return s.matches("\\d{1,2}\\.\\d{1,3}\\.\\d{1,4}"); } catch (Throwable t) { return false; }
    }

    private static boolean digit(byte b) { return b >= '0' && b <= '9'; }

    /** 返回 [起始下标, 长度]；要求形如 x.y.z 且紧跟换行，前面不是数字/点。 */
    private static int[] findVersionLine(byte[] b) {
        for (int i = 0; i + 6 < b.length; i++) {
            if (!digit(b[i])) continue;
            if (i > 0 && (digit(b[i - 1]) || b[i - 1] == '.')) continue;
            int p = i;
            int n1 = 0;
            while (p < b.length && digit(b[p]) && n1 < 2) { p++; n1++; }
            if (p >= b.length || b[p] != '.') continue;
            p++;
            int n2 = 0;
            while (p < b.length && digit(b[p]) && n2 < 3) { p++; n2++; }
            if (n2 == 0 || p >= b.length || b[p] != '.') continue;
            p++;
            int n3 = 0;
            while (p < b.length && digit(b[p]) && n3 < 4) { p++; n3++; }
            if (n3 == 0) continue;
            if (p < b.length && b[p] == '\n') {
                return new int[]{i, p - i};
            }
        }
        return null;
    }
}
''')

# ---------- FileOps: readBytes / writeBytes ----------
p = os.path.join(ROOT, 'FileOps.java')
s = rd(p)
if 'public static byte[] readBytes' not in s:
    anchor = '    public static List<File> listFilesRec(File root) {'
    add = '''    public static byte[] readBytes(File f) throws Exception {
        FileInputStream in = new FileInputStream(f);
        try {
            java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
            byte[] buf = new byte[65536];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
            return out.toByteArray();
        } finally { in.close(); }
    }

    public static void writeBytes(File f, byte[] data) throws Exception {
        File parent = f.getParentFile();
        if (parent != null) parent.mkdirs();
        OutputStream out = new FileOutputStream(f);
        try { out.write(data); out.flush(); } finally { out.close(); }
    }

'''
    assert anchor in s
    s = s.replace(anchor, add + anchor, 1)
    wr(p, s)

# ---------- ModApplier: revert physical overlay + restore version publish + assetmap sync ----------
p = os.path.join(ROOT, 'ModApplier.java')
s = rd(p)
old_lock = '''        // 物理覆盖模式：服务端版本号锁死为原生 1.4.140，绝不 +1/不重算 assetmap，
        // 避免客户端触发“有可用更新”热更流程。Mod 内容由 ClientOverlay 直接覆盖到客户端目录。
        try {
            if (enabled.isEmpty()) {
                ClientOverlay.restoreAll();
            }
            VersionPublisher.resetToVanillaBase();
        } catch (Throwable t) {
            Logx.e("version lock failed", t);
        }

        // 物理覆盖：把 Mod 的 config/compressed/wwise 直接复制进客户端 hot-update 目录
        try {
            int clientFiles = ClientOverlay.applyAll(enabled);
            if (clientFiles > 0) {
                applyProgress = 92;
                ProgressBus.report(92, "正在覆盖客户端文件…");
            }
            Logx.i("client overlay files copied=" + clientFiles);
        } catch (Throwable t) {
            Logx.e("client overlay failed", t);
        }
'''
new_publish = '''        // 版本发布 + AssetMap 动态对齐：把服务端发布的版本号同步写进 assetmap 内部第一行，
        // 避免客户端因“版本号与 assetmap 内部版本不一致”而卡在 0.00MB 的“有可用更新”。
        try {
            java.util.List<String> versions = new java.util.ArrayList<String>();
            for (ModInfo m : enabled) {
                if (m.clientVersion != null && m.clientVersion.trim().length() > 0) versions.add(m.clientVersion);
            }
            String desiredMin = VersionPublisher.highest(versions);
            VersionPublisher.publish(buildSignature(enabled), desiredMin);
        } catch (Throwable t) {
            Logx.e("version publish failed", t);
        }
        try { AssetmapVersionPatcher.sync(); } catch (Throwable t) { Logx.e("assetmap sync failed", t); }
'''
assert old_lock in s
s = s.replace(old_lock, new_publish, 1)
wr(p, s)

# ---------- ModLoader: remove physical restore call + boot version lock, add assetmap sync after boot apply ----------
p = os.path.join(ROOT, 'ModLoader.java')
s = rd(p)
s = s.replace('''                try { ClientOverlay.restoreAll(); } catch (Throwable t) { Logx.w("client overlay restore failed: " + t); }
''', '')
s = s.replace('''        try { ModApplier.apply(appCtx, bootstrap); } catch (Throwable t) { Logx.e("mod apply failed", t); }
        try { VersionPublisher.resetToVanillaBase(); } catch (Throwable t) { Logx.w("version lock at boot failed: " + t); }''',
'''        try { ModApplier.apply(appCtx, bootstrap); } catch (Throwable t) { Logx.e("mod apply failed", t); }
        try { AssetmapVersionPatcher.sync(); } catch (Throwable t) { Logx.w("assetmap sync at boot failed: " + t); }''')
wr(p, s)

# ---------- SetupActivity: restore 后同步 assetmap 回原生版本 ----------
p = r'E:/苍蓝_work/work/lead/modsrc/src/com/bluerebirth/savesync/SetupActivity.java'
s = rd(p)
wr(p, s)
print('assetmap dynamic patch code written')
