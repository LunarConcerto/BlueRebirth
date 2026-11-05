package com.bluerebirth.mods;

import android.content.Context;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;

/** 无 root 方案：进游戏后在大厅上方显示“正在加载新账号数据”的悬浮提示。 */
public final class ImportHintOverlay {
    private static WindowManager wm;
    private static View view;

    public static void show(final Context ctx, final String text, final long durationMs) {
        try {
            if (Build.VERSION.SDK_INT >= 23 && !Settings.canDrawOverlays(ctx)) {
                Logx.w("overlay permission not granted; hint skipped");
                return;
            }
            wm = (WindowManager) ctx.getSystemService("window");
            if (wm == null) return;
            TextView tv = new TextView(ctx);
            tv.setText(text);
            tv.setTextSize(18);
            tv.setTextColor(Color.WHITE);
            tv.setBackgroundColor(0xB0000000);
            tv.setPadding(40, 30, 40, 30);
            tv.setGravity(Gravity.CENTER);
            WindowManager.LayoutParams lp = new WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                    PixelFormat.TRANSLUCENT);
            lp.gravity = Gravity.CENTER;
            wm.addView(tv, (android.view.ViewGroup.LayoutParams) lp);
            view = tv;
            Logx.i("import hint overlay shown");
            new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
                public void run() { hide(); }
            }, durationMs);
        } catch (Throwable t) {
            Logx.w("import hint overlay failed: " + t);
        }
    }

    public static void hide() {
        try {
            if (wm != null && view != null) wm.removeView(view);
        } catch (Throwable ignored) { }
        view = null;
    }
}
