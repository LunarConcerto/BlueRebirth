package com.bluerebirth.mods;

import java.io.File;

/** 动态把服务端热更目录里的 assetmap 内部第一行版本号改成 kit-client-version.txt 的当前版本。
 *  需要 assetmap 是未压缩 UnityFS（打包时用 packer=none），版本号以明文存在于文件中。 */
public final class AssetmapVersionPatcher {
    public static void sync() {
        try {
            File hot = new File(ModPaths.hotDir, "bundle/assetmap");
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
