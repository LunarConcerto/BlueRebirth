package com.bluerebirth.mods;

import android.app.Activity;

/** 单例进度总线：管理活动里的不可取消进度遮罩。 */
public final class ProgressBus {
    private static ProgressOverlay overlay;

    public static void begin(final Activity a, final String title) {
        if (a == null) { Logx.w("progress begin skipped: activity null"); return; }
        try {
            a.runOnUiThread(new Runnable() { public void run() {
                try {
                    synchronized (ProgressBus.class) {
                        if (overlay != null) { overlay.close(); overlay = null; }
                        overlay = new ProgressOverlay(a, title);
                        overlay.show();
                        overlay.update(0, "准备中…");
                    }
                    Logx.i("progress begin(ui): " + title);
                } catch (Throwable t) { Logx.w("progress begin(ui) failed: " + t); }
            }});
        } catch (Throwable t) { Logx.w("progress begin failed: " + t); }
    }

    public static void report(int percent, String label) {
        ProgressOverlay o = overlay;
        if (o != null) o.update(percent, label);
    }

    public static synchronized void end() {
        try { if (overlay != null) { overlay.update(100, "完成"); overlay.close(); } }
        catch (Throwable ignored) { }
        overlay = null;
    }
}
