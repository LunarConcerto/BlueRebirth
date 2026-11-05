package com.bluerebirth.mods;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Application;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.WeakHashMap;

/** 主界面（豆包版 home_ui 资源）+ 底部工具栏重排：防杀后台/关闭启动器 + 看看倒/检查新/反馈。 */
public final class UiInjector {
    private static final String CLIENT_PKG = "com.zephyrus.clsy.gp";
    private static boolean installed;
    private static Activity current;
    private static final WeakHashMap<Activity, Boolean> injected = new WeakHashMap<Activity, Boolean>();
    private static Thread kitWatch;

    public static void install(Context app) {
        try {
            if (installed) return;
            if (!(app instanceof Application)) { Logx.w("UiInjector: app ctx is not Application"); return; }
            ((Application) app).registerActivityLifecycleCallbacks(new Cb());
            installed = true;
            Logx.i("UiInjector installed");
        } catch (Throwable t) { Logx.w("UiInjector install failed: " + t); }
    }

    static final class Cb implements Application.ActivityLifecycleCallbacks {
        public void onActivityCreated(Activity a, android.os.Bundle b) { }
        public void onActivityStarted(Activity a) { }
        public void onActivityResumed(Activity a) {
            current = a;
            try {
                String n = a.getClass().getName();
                if (n.startsWith("crc649bef45f3691b5cb4") && n.endsWith("MainActivity")) {
                    buildHome(a);
                    startKitWatch();
                }
            } catch (Throwable t) { Logx.w("onActivityResumed inject failed: " + t); }
        }
        public void onActivityPaused(Activity a) { if (current == a) current = null; }
        public void onActivityStopped(Activity a) { }
        public void onActivitySaveInstanceState(Activity a, android.os.Bundle b) { }
        public void onActivityDestroyed(Activity a) { }
    }

    private static int id(Activity a, String name) {
        try { return a.getResources().getIdentifier(name, "id", a.getPackageName()); }
        catch (Throwable t) { return 0; }
    }
    private static int drawable(Activity a, String name) {
        try { return a.getResources().getIdentifier(name, "drawable", a.getPackageName()); }
        catch (Throwable t) { return 0; }
    }
    private static int dp(Activity a, float v) {
        try { return (int) (v * a.getResources().getDisplayMetrics().density + 0.5f); }
        catch (Throwable t) { return (int) v * 2; }
    }

    private static void buildHome(final Activity a) {
        synchronized (injected) {
            if (injected.containsKey(a)) return;
            injected.put(a, Boolean.TRUE);
        }
        try {
            int layoutId = a.getResources().getIdentifier("home_ui", "layout", a.getPackageName());
            View root = LayoutInflater.from(a).inflate(layoutId, null);
            if (root == null) { Logx.w("home_ui inflate failed"); return; }
            final TextView title = (TextView) root.findViewById(id(a, "tv_status_title"));
            final TextView hint = (TextView) root.findViewById(id(a, "tv_status_hint"));
            final TextView modStatus = (TextView) root.findViewById(id(a, "tv_mod_status"));

            bind(a, root, "btn_start", new Runnable() { public void run() { performOriginal(a, "开始游戏"); } });
            bind(a, root, "btn_install", new Runnable() { public void run() { performOriginal(a, "安装倒卖狗死妈包"); } });
            bind(a, root, "btn_mods", new Runnable() { public void run() { openSetupMode(a, "mods", null); } });
            bind(a, root, "btn_import", new Runnable() { public void run() { openSetupMode(a, "saves", null); } });
            bind(a, root, "btn_export", new Runnable() { public void run() { openSetupMode(a, "saves", null); } });
            bind(a, root, "btn_antikill", new Runnable() { public void run() { openStartupManager(a); } });
            bind(a, root, "btn_close", new Runnable() { public void run() { confirmCloseLauncher(a); } });
            bind(a, root, "btn_feedback", new Runnable() { public void run() { performOriginal(a, "反馈"); } });

            root.setClickable(true);
            a.addContentView(root, new ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            layoutBottomBar(a, root);
            slimMain(a, root);
            maybeShowRestorePrompt(a);
            startStatusPoll(a, title, hint, modStatus);
            Logx.i("main UI rebuilt (home console + bottom actions)");
        } catch (Throwable t) { Logx.w("buildHome failed: " + t); }
    }

    private static void bind(final Activity a, View root, String name, final Runnable r) {
        try {
            View v = root.findViewById(id(a, name));
            if (v != null) v.setOnClickListener(new View.OnClickListener() {
                public void onClick(View x) { try { r.run(); } catch (Throwable t) { Logx.w("click failed: " + t); } }
            });
        } catch (Throwable t) { Logx.w("bind " + name + " failed: " + t); }
    }

    /** 把豆包布局的底部 3 按钮区改成两行：上行 防杀/关闭，下行 看看倒/检查新/反馈（长文案 + 自动缩放）。 */
    private static void layoutBottomBar(final Activity a, View root) {
        try {
            View fb = root.findViewById(id(a, "btn_feedback"));
            if (fb == null) return;
            Object pobj = fb.getParent();
            if (!(pobj instanceof ViewGroup)) return;
            ViewGroup pvg = (ViewGroup) pobj;
            if (!(pvg instanceof LinearLayout)) return;
            LinearLayout parent = (LinearLayout) pvg;
            parent.removeAllViews();
            parent.setOrientation(LinearLayout.VERTICAL);
            parent.setPadding(dp(a, 20), dp(a, 6), dp(a, 20), dp(a, 6));

            LinearLayout row1 = new LinearLayout(a);
            row1.setOrientation(LinearLayout.HORIZONTAL);
            row1.setGravity(Gravity.CENTER);
            Button anti = makeButton(a, "防杀后台设置", "btn_pill", 0xFF1C2B4A, 12f, dp(a, 40));
            anti.setOnClickListener(new View.OnClickListener() { public void onClick(View v) { openStartupManager(a); } });
            Button close = makeButton(a, "关闭启动器", "btn_danger_pill", 0xFFE85C5C, 12f, dp(a, 40));
            close.setOnClickListener(new View.OnClickListener() { public void onClick(View v) { confirmCloseLauncher(a); } });
            LinearLayout.LayoutParams lp1 = new LinearLayout.LayoutParams(0, dp(a, 40), 1.0f);
            lp1.setMargins(0, 0, dp(a, 4), 0);
            row1.addView(anti, lp1);
            LinearLayout.LayoutParams lp2 = new LinearLayout.LayoutParams(0, dp(a, 40), 1.0f);
            lp2.setMargins(dp(a, 4), 0, 0, 0);
            row1.addView(close, lp2);
            LinearLayout fixedBar = new LinearLayout(a);
            fixedBar.setOrientation(LinearLayout.VERTICAL);
            fixedBar.setPadding(dp(a, 16), dp(a, 14), dp(a, 16), dp(a, 10));
            fixedBar.addView(row1);

            LinearLayout row2 = new LinearLayout(a);
            row2.setOrientation(LinearLayout.HORIZONTAL);
            row2.setGravity(Gravity.CENTER);
            row2.setPadding(dp(a, 4), dp(a, 6), dp(a, 4), 0);
            String[] texts = new String[] {
                    "看看倒卖狗的是怎么死的", "检查新的倒卖狗死妈小技巧", "反馈"
            };
            String[] acts = new String[] {
                    "看看倒卖狗的是怎么死的", "检查新的倒卖狗死妈小技巧", "反馈"
            };
            for (int i = 0; i < texts.length; i++) {
                Button b = new Button(a);
                b.setText(texts[i]);
                b.setTextColor(0xFF1C2B4A);
                b.setTextSize(11f);
                b.setMaxLines(2);
                b.setPadding(dp(a, 6), dp(a, 4), dp(a, 6), dp(a, 4));
                int bg = drawable(a, "btn_pill");
                if (bg != 0) b.setBackgroundResource(bg);
                tryAutoSize(b);
                final int idx = i;
                b.setOnClickListener(new View.OnClickListener() {
                    public void onClick(View v) {
                        if (idx == 0) openLogActivity(a);
                        else if (idx == 1) checkUpdate(a);
                        else performOriginal(a, "反馈");
                    }
                });
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(a, 40), 1.0f);
                lp.setMargins(dp(a, 8), 0, dp(a, 8), 0);
                row2.addView(b, lp);
            }
            fixedBar.addView(row2);
            a.addContentView(fixedBar, new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM));
        } catch (Throwable t) { Logx.w("layoutBottomBar failed: " + t); }
    }

    private static void slimMain(Activity a, View root) {
        try {
            View v = root.findViewById(id(a, "tv_status_title"));
            if (v instanceof TextView) { ((TextView) v).setTextSize(18); ((TextView) v).setTypeface(Typeface.DEFAULT); }
            v = root.findViewById(id(a, "tv_status_hint"));
            if (v instanceof TextView) { ((TextView) v).setTextSize(12); ((TextView) v).setTypeface(Typeface.DEFAULT); }
            slim(a, root.findViewById(id(a, "btn_start")), 48, 18f, true);
            slim(a, root.findViewById(id(a, "btn_install")), 42, 14f, true);
            View modsBtn = root.findViewById(id(a, "btn_mods"));
            if (modsBtn instanceof TextView) ((TextView) modsBtn).setText("Mod 管理器");
            slim(a, modsBtn, 40, 12f, false);
            shrinkCardTitles(root);
            replaceSaveCard(a, root);
            slim(a, root.findViewById(id(a, "btn_import")), 36, 12f, false);
            slim(a, root.findViewById(id(a, "btn_export")), 36, 12f, false);
        } catch (Throwable t) { Logx.w("slimMain failed: " + t); }
    }

    private static void shrinkCardTitles(View root) {
        try {
            if (!(root instanceof ViewGroup)) return;
            ViewGroup g = (ViewGroup) root;
            for (int i = 0; i < g.getChildCount(); i++) {
                View c = g.getChildAt(i);
                if (c instanceof TextView && !(c instanceof Button)) {
                    String t = String.valueOf(((TextView) c).getText());
                    if ("Mod 管理".equals(t) || "存档操作".equals(t)) {
                        ((TextView) c).setTextSize(15);
                        ((TextView) c).setTypeface(Typeface.DEFAULT);
                    }
                }
                if (c instanceof ViewGroup) shrinkCardTitles(c);
            }
        } catch (Throwable ignored) { }
    }

    private static void maybeShowRestorePrompt(final Activity a) {
        try {
            SharedPreferences sp = a.getSharedPreferences("br_ui", 0);
            if (sp.getBoolean("restore_done", false)) return;
            if (!sp.getBoolean("restore_pending", false)) return;
            sp.edit().putBoolean("restore_done", true).putBoolean("restore_pending", false).commit();
            new AlertDialog.Builder(a)
                    .setTitle("已恢复纯净原版")
                    .setMessage("已恢复纯净原版！请去系统设置清空客户端数据，然后再进游戏。")
                    .setPositiveButton("我知道了", null)
                    .show();
            Logx.i("restore prompt shown on main");
        } catch (Throwable t) { Logx.w("restore prompt failed: " + t); }
    }

    private static void replaceSaveCard(final Activity a, View root) {
        try {
            View imp = root.findViewById(id(a, "btn_import"));
            View exp = root.findViewById(id(a, "btn_export"));
            if (imp == null || exp == null) return;
            Object pobj = imp.getParent();
            if (!(pobj instanceof ViewGroup)) return;
            ViewGroup card = (ViewGroup) pobj;
            card.removeView(imp);
            card.removeView(exp);
            Button b = new Button(a);
            b.setText("存档管理");
            b.setTextColor(0xFFFFFFFF);
            b.setTextSize(12f);
            b.setTypeface(Typeface.DEFAULT);
            int bg = drawable(a, "btn_blue");
            if (bg != 0) b.setBackgroundResource(bg);
            b.setOnClickListener(new View.OnClickListener() {
                public void onClick(View v) { openSetupMode(a, "saves", null); }
            });
            View push = new View(a);
            card.addView(push, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, 0, 1.0f));
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, dp(a, 40));
            lp.setMargins(0, 0, 0, 0);
            card.addView(b, lp);
        } catch (Throwable t) { Logx.w("replaceSaveCard failed: " + t); }
    }

    private static void slim(Activity a, View v, int hdp, float sp, boolean marginTop) {
        if (v == null) return;
        try {
            ViewGroup.LayoutParams lp = v.getLayoutParams();
            int w = (lp == null) ? ViewGroup.LayoutParams.MATCH_PARENT : lp.width;
            if (w == 0) w = ViewGroup.LayoutParams.MATCH_PARENT;
            LinearLayout.LayoutParams nlp = new LinearLayout.LayoutParams(w, dp(a, hdp));
            nlp.setMargins(0, marginTop ? dp(a, 16) : dp(a, 10), 0, 0);
            v.setLayoutParams(nlp);
            if (v instanceof TextView) {
                ((TextView) v).setTextSize(sp);
                ((TextView) v).setTypeface(Typeface.DEFAULT);
            }
        } catch (Throwable t) { Logx.w("slim failed: " + t); }
    }

    private static Button makeButton(Activity a, String text, String drawable, int color, float size, int height) {
        Button b = new Button(a);
        b.setText(text);
        b.setTextColor(color);
        b.setTextSize(size);
        int bg = drawable(a, drawable);
        if (bg != 0) b.setBackgroundResource(bg);
        return b;
    }

    private static void tryAutoSize(Button b) {
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                b.setAutoSizeTextTypeUniformWithConfiguration(8, 12, 1, 2);
            }
        } catch (Throwable ignored) { }
    }

    private static void openSetupMode(Activity a, String mode, String action) {
        try {
            Intent i = new Intent();
            i.setClassName("com.blueoath.server", "com.bluerebirth.savesync.SetupActivity");
            i.putExtra("br_mode", mode);
            if (action != null) i.putExtra("br_action", action);
            a.startActivity(i);
        } catch (Throwable t) { Logx.w("open setup failed: " + t); }
    }

    private static void openLogActivity(final Activity a) {
        try {
            Intent i = new Intent();
            i.setClassName("com.blueoath.server", "crc649bef45f3691b5cb4.LogActivity");
            a.startActivity(i);
            Logx.i("log activity opened from bottom button");
        } catch (Throwable t) {
            Logx.w("openLogActivity failed: " + t);
            performOriginal(a, "看看倒卖狗的是怎么死的");
        }
    }

    private static void checkUpdate(final Activity a) {
        performOriginal(a, "检查新的倒卖狗死妈小技巧");
        try {
            new AlertDialog.Builder(a)
                    .setTitle("检查更新")
                    .setMessage("已检查更新：当前版本 v1.2.999\n最新 Release：v1.2.999\n\n已是最新版本；如有新包，请以群文件发布为准。")
                    .setPositiveButton("我知道了", null)
                    .show();
            Logx.i("check update dialog shown");
        } catch (Throwable t) { Logx.w("checkUpdate failed: " + t); }
    }

    /** 在原 C# 界面的 View 树里按文字找按钮并点击（复用原有业务逻辑）。 */
    private static boolean performOriginal(Activity a, String text) {
        try {
            Button b = findButtonByText(a, text);
            if (b != null) { b.performClick(); return true; }
            Logx.w("original button not found: " + text);
        } catch (Throwable t) { Logx.w("performOriginal failed: " + t); }
        return false;
    }

    private static Button findButtonByText(Activity a, String want) {
        try {
            View content = a.findViewById(0x1020002);
            if (content instanceof ViewGroup) {
                ViewGroup cg = (ViewGroup) content;
                if (cg.getChildCount() > 0) {
                    View original = cg.getChildAt(0);
                    if (original instanceof ViewGroup) return findIn((ViewGroup) original, want);
                }
            }
        } catch (Throwable ignored) { }
        return null;
    }
    private static Button findIn(ViewGroup g, String want) {
        for (int i = 0; i < g.getChildCount(); i++) {
            View c = g.getChildAt(i);
            if (c instanceof Button) {
                try {
                    CharSequence t = ((Button) c).getText();
                    if (t != null && t.toString().contains(want)) return (Button) c;
                } catch (Throwable ignored) { }
            }
            if (c instanceof ViewGroup) {
                Button r = findIn((ViewGroup) c, want);
                if (r != null) return r;
            }
        }
        return null;
    }

    private static void startStatusPoll(final Activity a, final TextView title, final TextView hint, final TextView modStatus) {
        try {
            final Handler h = new Handler(Looper.getMainLooper());
            h.postDelayed(new Runnable() { public void run() {
                try {
                    if (a.isFinishing()) return;
                    List<CharSequence> texts = new ArrayList<CharSequence>();
                    View content = a.findViewById(0x1020002);
                    if (content instanceof ViewGroup && ((ViewGroup) content).getChildCount() > 0) {
                        collectTexts(((ViewGroup) content).getChildAt(0), texts);
                    }
                    if (title != null) {
                        title.setText(texts.size() > 0 ? texts.get(0) : "可以开始游戏了");
                    }
                    if (hint != null) {
                        hint.setText(texts.size() > 1 ? texts.get(1) : "点下面「开始游戏」。");
                    }
                    if (modStatus != null) {
                        boolean granted = ModPaths.checkExternal();
                        int n = 0;
                        try { if (granted) n = ModScanner.scan(ModPaths.modsDir).size(); } catch (Throwable ignored) { }
                        modStatus.setText("存储：" + (granted ? "已授权" : "未授权") + "  ｜  Mod：" + n + " 个");
                    }
                } catch (Throwable ignored) { }
                h.postDelayed(this, 1500L);
            }}, 500L);
        } catch (Throwable t) { Logx.w("startStatusPoll failed: " + t); }
    }

    private static void collectTexts(View v, List<CharSequence> out) {
        try {
            if (v instanceof TextView && !(v instanceof Button)) {
                CharSequence t = ((TextView) v).getText();
                if (t != null) {
                    String s = t.toString().trim();
                    if (s.length() > 0 && s.indexOf("永久免费") < 0 && s.indexOf("退款") < 0 && s.indexOf("付费") < 0) {
                        out.add(t);
                    }
                }
            }
            if (v instanceof ViewGroup) {
                ViewGroup g = (ViewGroup) v;
                for (int i = 0; i < g.getChildCount(); i++) collectTexts(g.getChildAt(i), out);
            }
        } catch (Throwable ignored) { }
    }

    /** 多厂家“应用启动管理”页面 Intent 兜底，最后退回本应用详情页。 */
    private static void openStartupManager(Activity a) {
        String[][] comps = {
                {"com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"},
                {"com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"},
                {"com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"},
                {"com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"},
                {"com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"},
                {"com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"},
                {"com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"},
                {"com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"}
        };
        for (int i = 0; i < comps.length; i++) {
            try {
                Intent it = new Intent();
                it.setComponent(new ComponentName(comps[i][0], comps[i][1]));
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                a.startActivity(it);
                toast(a, "请在系统页面允许「自启动 / 关联启动 / 后台活动」");
                Logx.i("startup manager opened: " + comps[i][0] + "/" + comps[i][1]);
                return;
            } catch (Throwable ignored) { }
        }
        try {
            a.startActivity(new Intent("android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS"));
            toast(a, "请在电池优化列表把本应用设为「不优化/无限制」");
            Logx.i("battery optimization settings opened");
            return;
        } catch (Throwable ignored) { }
        try {
            Intent it = new Intent("android.settings.APPLICATION_DETAILS_SETTINGS");
            it.setData(Uri.parse("package:" + a.getPackageName()));
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            a.startActivity(it);
            toast(a, "本机没有独立启动管理页，请在应用详情里打开「省电策略/后台运行」");
            Logx.i("app details fallback opened");
            return;
        } catch (Throwable ignored) { }
        toast(a, "无法自动打开系统设置，请手动到系统设置→应用→电池/自启动里设置");
    }

    private static void confirmCloseLauncher(final Activity a) {
        try {
            AlertDialog.Builder b = new AlertDialog.Builder(a);
            b.setTitle("关闭启动器？");
            b.setMessage("关闭启动器可以解决大部分黑屏/卡顿问题。");
            b.setPositiveButton("关闭", new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface d, int w) { doCloseLauncher(); }
            });
            b.setNegativeButton("取消", null);
            b.show();
        } catch (Throwable t) { Logx.w("close launcher dialog failed: " + t); }
    }

    private static void doCloseLauncher() {
        Logx.i("close launcher requested: killing own process");
        try {
            new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
                public void run() {
                    try { Process.killProcess(Process.myPid()); } catch (Throwable ignored) { }
                }
            }, 300L);
        } catch (Throwable t) {
            try { Process.killProcess(Process.myPid()); } catch (Throwable ignored) { }
        }
    }

    private static void startKitWatch() {
        if (kitWatch != null) return;
        kitWatch = new Thread(new Runnable() { public void run() {
            long last = -1; int stable = 0; boolean shown = false;
            File dir = new File("/sdcard/Android/data/com.blueoath.server/files");
            File client = new File("/sdcard/Android/data/com.zephyrus.clsy.gp");
            long startSize = dirSize(dir);
            for (int i = 0; i < 600; i++) {
                try { Thread.sleep(1500); } catch (Throwable t) { return; }
                long size = dirSize(dir);
                Activity a = current;
                if (client.exists()) {
                    if (shown) { ProgressBus.end(); shown = false; }
                    return;
                }
                if (size > startSize + 150L * 1024 * 1024) {
                    int pct = (int) (size * 100L / 3600000000L);
                    if (pct < 1) pct = 1;
                    if (pct > 99) pct = 99;
                    if (!shown && a != null) {
                        ProgressBus.begin(a, "正在安装资源包（解压）");
                        shown = true;
                    }
                    if (shown) ProgressBus.report(pct, "已解压 " + (size / 1048576L) + " MB，请勿点击其他按钮");
                }
                if (size == last && shown) {
                    stable++;
                    if (stable >= 6) {
                        ProgressBus.report(100, "解压完成");
                        try { Thread.sleep(800); } catch (Throwable ignored) { }
                        ProgressBus.end();
                        return;
                    }
                } else stable = 0;
                last = size;
            }
        }}, "br-kit-watch");
        kitWatch.setDaemon(true);
        kitWatch.start();
    }

    private static long dirSize(File f) {
        if (f == null || !f.exists()) return 0;
        if (f.isFile()) return f.length();
        File[] kids = f.listFiles();
        if (kids == null) return 0;
        long s = 0;
        for (File k : kids) s += dirSize(k);
        return s;
    }

    private static void toast(Context c, String s) {
        try { Toast.makeText(c, s, Toast.LENGTH_SHORT).show(); } catch (Throwable ignored) { }
    }
}
