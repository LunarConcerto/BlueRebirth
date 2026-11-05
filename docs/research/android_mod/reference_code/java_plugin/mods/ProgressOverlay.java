package com.bluerebirth.mods;

import android.app.Activity;
import android.app.Dialog;
import android.view.Gravity;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.LinearLayout;
import android.widget.TextView;

/** 不可取消的模态进度框：大号百分比 + 字符进度条 + 说明，遮罩级别覆盖游戏/启动器界面。 */
final class ProgressOverlay {
    private final Activity act;
    private final Dialog dialog;
    private final TextView titleTv;
    private final TextView pctTv;
    private final TextView barTv;
    private final TextView subTv;

    ProgressOverlay(Activity a, String title) {
        act = a;
        dialog = new Dialog(a);
        dialog.setCancelable(false);
        dialog.setCanceledOnTouchOutside(false);

        LinearLayout root = new LinearLayout(a);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setBackgroundColor(0xF20B0F14);
        root.setPadding(60, 60, 60, 60);

        titleTv = new TextView(a);
        titleTv.setText(title);
        titleTv.setTextColor(0xFFFFFFFF);
        titleTv.setTextSize(22);
        titleTv.setGravity(Gravity.CENTER);
        titleTv.setPadding(0, 0, 0, 18);
        root.addView(titleTv);

        pctTv = new TextView(a);
        pctTv.setText("0%");
        pctTv.setTextColor(0xFF44E08A);
        pctTv.setTextSize(52);
        pctTv.setGravity(Gravity.CENTER);
        root.addView(pctTv);

        barTv = new TextView(a);
        barTv.setText("[░░░░░░░░░░░░░░░░░░░░]");
        barTv.setTextColor(0xFF8CCBFF);
        barTv.setTextSize(20);
        barTv.setGravity(Gravity.CENTER);
        barTv.setPadding(0, 10, 0, 0);
        root.addView(barTv);

        subTv = new TextView(a);
        subTv.setText("请勿操作，等待完成…");
        subTv.setTextColor(0xFFCCCCCC);
        subTv.setTextSize(13);
        subTv.setGravity(Gravity.CENTER);
        subTv.setPadding(0, 24, 0, 0);
        root.addView(subTv);

        dialog.setContentView(root);
    }

    void show() {
        try {
            dialog.show();
            Window w = dialog.getWindow();
            if (w != null) w.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        } catch (Throwable t) { Logx.w("progress dialog show failed: " + t); }
    }

    void update(final int percent, final String label) {
        final int p = percent < 0 ? 0 : (percent > 100 ? 100 : percent);
        act.runOnUiThread(new Runnable() { public void run() {
            try {
                pctTv.setText(p + "%");
                StringBuilder b = new StringBuilder("[");
                int cells = 20;
                int filled = p * cells / 100;
                for (int i = 0; i < cells; i++) b.append(i < filled ? '█' : '░');
                b.append(']');
                barTv.setText(b.toString());
                if (label != null) subTv.setText(label);
            } catch (Throwable ignored) { }
        }});
    }

    void close() {
        act.runOnUiThread(new Runnable() { public void run() {
            try { dialog.dismiss(); } catch (Throwable ignored) { }
        }});
    }
}
