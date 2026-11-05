package com.bluerebirth.savesync;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Process;
import android.provider.Settings;
import android.view.View;
import android.view.ViewGroup;
import android.graphics.Typeface;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import com.bluerebirth.mods.Logx;
import com.bluerebirth.mods.ModApplier;
import com.bluerebirth.mods.ModInfo;
import com.bluerebirth.mods.ModLoader;
import com.bluerebirth.mods.ProgressBus;
import com.bluerebirth.mods.ModPaths;
import com.bluerebirth.mods.ModScanner;
import com.bluerebirth.mods.UiLayout;
import com.bluerebirth.mods.Relauncher;
import com.bluerebirth.mods.SaveSync;
import java.io.File;
import java.util.List;
import java.util.Map;

/** BlueRebirth Mod 管理器（启动器入口）——布局来自 assets/bluerebirth/ui_layout.xml */
public class SetupActivity extends Activity {
    private LinearLayout list;
    private TextView status;
    private boolean saveMode = false;

    public void onCreate(Bundle b) {
        super.onCreate(b);
        try { requestWindowFeature(android.view.Window.FEATURE_NO_TITLE); } catch (Throwable ignored) { }
        setTitle("BlueRebirth Mod 管理器");
        try { com.bluerebirth.mods.KeepAliveService.ensure(this); } catch (Throwable ignored) { }

        Intent intent = getIntent();
        String mode = intent == null ? null : intent.getStringExtra("br_mode");
        saveMode = "saves".equals(mode);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(20), dp(16), dp(20), dp(16));
        setContentView(root);

        TextView title = new TextView(this);
        title.setText(saveMode ? "存档操作" : "BlueRebirth · Mod 管理器");
        title.setTextSize(20);
        title.setTextColor(0xFF1C2B4A);
        title.setGravity(android.view.Gravity.CENTER);
        title.setPadding(0, dp(4), 0, dp(12));
        root.addView(title, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        if (saveMode) {
            TextView card = new TextView(this);
            card.setText("存档存放路径：" + ModPaths.savesDir + "\n说明：导入/导出均为服务端 profiles.db");
            card.setTextSize(12);
            card.setTextColor(0xFF3A4A66);
            card.setPadding(dp(16), dp(14), dp(16), dp(14));
            try {
                int bg = getResources().getIdentifier("card_white", "drawable", getPackageName());
                if (bg != 0) card.setBackgroundResource(bg);
            } catch (Throwable ignored) { }
            root.addView(card, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

            LinearLayout spacer = new LinearLayout(this);
            root.addView(spacer, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1.0f));

            addBigButton(root, "导入外部存档", dp(16), new View.OnClickListener() { public void onClick(View x) { importSave(); } });
            addBigButton(root, "导出当前存档", dp(16), new View.OnClickListener() { public void onClick(View x) { exportSave(); } });
            addBigButton(root, "返回主页", dp(24), new View.OnClickListener() { public void onClick(View x) { finish(); } });
        } else {
            status = new TextView(this);
            status.setTextSize(12);
            status.setTextColor(0xFF3A4A66);
            status.setPadding(dp(16), dp(14), dp(16), dp(14));
            try {
                int card2 = getResources().getIdentifier("card_white", "drawable", getPackageName());
                if (card2 != 0) status.setBackgroundResource(card2);
            } catch (Throwable ignored) { }
            root.addView(status, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            ScrollView sv = new ScrollView(this);
            list = new LinearLayout(this);
            list.setOrientation(LinearLayout.VERTICAL);
            list.setPadding(0, dp(16), 0, 0);
            sv.addView(list);
            root.addView(sv, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1.0f));
        }

        if (!saveMode) {
            LinearLayout row1 = new LinearLayout(this);
            row1.setOrientation(LinearLayout.HORIZONTAL);
            row1.setPadding(0, dp(16), 0, 0);
            addBottomButton(row1, "授权存储", new View.OnClickListener() { public void onClick(View x) { requestAllFiles(); } });
            addBottomButton(row1, "刷新并应用", new View.OnClickListener() { public void onClick(View x) { showApplyNotice(); } });
            root.addView(row1, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

            LinearLayout row2 = new LinearLayout(this);
            row2.setOrientation(LinearLayout.HORIZONTAL);
            row2.setPadding(0, dp(4), 0, 0);
            addBottomButton(row2, "一键恢复纯净原版", new View.OnClickListener() { public void onClick(View x) { resetVanilla(); } });
            addBottomButton(row2, "返回主页", new View.OnClickListener() { public void onClick(View x) { finish(); } });
            root.addView(row2, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        }

        if (saveMode) {
            String act = intent == null ? null : intent.getStringExtra("br_action");
            if ("import".equals(act)) importSave();
            else if ("export".equals(act)) exportSave();
        } else {
            autoRequestPermissionOnce();
        }
    }

    private int dp(int v) {
        try { return (int) (v * getResources().getDisplayMetrics().density + 0.5f); }
        catch (Throwable t) { return v * 2; }
    }

    private void addBigButton(LinearLayout parent, String text, int topMargin, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(text);
        b.setTextSize(15);
        b.setTextColor(0xFFFFFFFF);
        b.setTypeface(android.graphics.Typeface.DEFAULT);
        b.setMinHeight(dp(48));
        try {
            int bg = getResources().getIdentifier("btn_blue", "drawable", getPackageName());
            if (bg != 0) b.setBackgroundResource(bg);
        } catch (Throwable ignored) { }
        b.setOnClickListener(l);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(48));
        lp.setMargins(0, topMargin, 0, 0);
        parent.addView(b, lp);
    }

    private void addBottomButton(LinearLayout parent, String text, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(text);
        b.setTextSize(13);
        b.setTextColor(0xFFFFFFFF);
        b.setTypeface(android.graphics.Typeface.DEFAULT);
        b.setMinHeight(dp(42));
        try {
            int bg = getResources().getIdentifier("btn_blue", "drawable", getPackageName());
            if (bg != 0) b.setBackgroundResource(bg);
        } catch (Throwable ignored) { }
        b.setOnClickListener(l);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(42), 1.0f);
        lp.setMargins(dp(8), 0, dp(8), 0);
        parent.addView(b, lp);
    }

    private void exportSave() {
        try {
            ModLoader.exportAsync();
            toast("正在导出存档到 " + ModPaths.savesDir);
        } catch (Throwable t) { toast("导出失败：" + t); }
    }

    private void onClick(Map<String, View> v, String id, View.OnClickListener l) {
        View x = v.get(id);
        if (x != null) x.setOnClickListener(l);
    }

    private void autoRequestPermissionOnce() {
        try {
            if (ModPaths.checkExternal()) return;
            File marker = new File(ModPaths.privateDir, ".allfiles_prompted");
            if (marker.exists()) return;
            marker.getParentFile().mkdirs();
            marker.createNewFile();
            requestAllFiles();
        } catch (Throwable t) { Logx.w("auto permission prompt failed: " + t); }
    }

    public void onResume() { super.onResume(); refresh(); if (!saveMode) { try { maybeShowImportGuide(); } catch (Throwable ignored) { } try { maybeShowRestoreGuide(); } catch (Throwable ignored) { } } }
    public void onPause() { super.onPause(); try { ModLoader.exportAsync(); } catch (Throwable ignored) { } }

    private void refresh() {
        if (saveMode) return;
        if (status == null) return;
        boolean granted = ModPaths.checkExternal();
        String st = ModApplier.lastResult();
        if (st != null) {
            int p = st.indexOf('（');
            if (p < 0) p = st.indexOf('(');
            if (p > 0) st = st.substring(0, p);
        }
        status.setText("Mod 存放路径：" + ModPaths.modsDir + "\n扫描状态：" + (granted ? "已授权 · " : "未授权 · ") + st);
        if (list == null) return;
        list.removeAllViews();
        List<ModInfo> mods = ModScanner.scan(ModPaths.modsDir);
        if (mods.isEmpty()) {
            TextView tv = new TextView(this);
            tv.setText("（未发现 Mod）\n把 .mod 文件夹放到上面的 Mod 目录，然后点『刷新并应用』。");
            tv.setTextColor(0xFF808080);
            tv.setTextSize(13);
            list.addView(tv);
            return;
        }
        for (final ModInfo m : mods) {
            LinearLayout row = new LinearLayout(this);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setPadding(dp(16), dp(16), dp(16), dp(16));
            int cardBg = getResources().getIdentifier("card_white", "drawable", getPackageName());
            if (cardBg != 0) row.setBackgroundResource(cardBg);
            row.setElevation(dp(2));
            CheckBox cb = new CheckBox(this);
            cb.setChecked(m.enabled);
            cb.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
                public void onCheckedChanged(CompoundButton b, boolean checked) {
                    ModScanner.setEnabled(m, checked);
                    toast(m.id + (checked ? " 已启用" : " 已禁用") + "（重启启动器后生效）");
                }
            });
            row.addView(cb);
            LinearLayout col = new LinearLayout(this);
            col.setOrientation(LinearLayout.VERTICAL);
            TextView title = new TextView(this);
            String head = m.displayName() + (m.version == null ? "" : ("   v" + m.version));
            title.setText(head);
            title.setTextSize(15);
            title.setTextColor(0xFF1C2B4A);
            title.setTypeface(Typeface.DEFAULT);
            col.addView(title, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            TextView desc = new TextView(this);
            desc.setText(m.description == null || m.description.length() == 0 ? "（无说明）" : m.description);
            desc.setTextSize(12);
            desc.setTextColor(0xFF5B6C8F);
            desc.setPadding(0, dp(4), 0, 0);
            col.addView(desc, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            row.addView(col, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f));
            LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            rlp.setMargins(0, 0, 0, dp(16));
            list.addView(row, rlp);
        }
    }

    /** 点击“刷新并应用”前先弹出操作须知，确认后才真正开始应用。 */
    private String buildPathInfo() {
        boolean granted = ModPaths.checkExternal();
        StringBuilder sb = new StringBuilder();
        sb.append("外部存储权限：").append(granted ? "已授权（推荐）" : "未授权").append("\n");
        sb.append("存储说明：").append(ModPaths.storageNote).append("\n");
        sb.append("Mod 目录：").append(ModPaths.modsDir).append("\n");
        sb.append("存档目录：").append(ModPaths.savesDir).append("\n");
        sb.append("热更目录：").append(ModPaths.hotDir).append("\n");
        sb.append("状态：").append(ModApplier.lastResult());
        return sb.toString();
    }

    private boolean noticeShown = false;

    private void showApplyNotice() {
        if (noticeShown) { return; }
        noticeShown = true;
        try {
            AlertDialog.Builder b = new AlertDialog.Builder(this);
            b.setTitle("应用 Mod 须知");
            b.setMessage("1. 请确保 Mod 文件夹已解压到 /sdcard/BlueRebirth/Mods/ 目录下。\n"
                    + "2. 点击下方“开始应用”后，请耐心等待进度条走到 100%。\n"
                    + "3. 【第一步】提示应用成功后，必须彻底关闭（划掉）当前启动器。\n"
                    + "4. 【第二步】重新打开启动器，点击“开始游戏”，客户端会自动拉取更新。\n"
                    + "5. 【第三步】更新完成后，再次点击“刷新并应用”以确保最新状态生效。");
            b.setPositiveButton("我知道了", new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface d, int w) { refreshAndApply(); }
            });
            b.setNegativeButton("取消", null);
            b.show();
            Logx.i("apply notice dialog shown");
        } catch (Throwable t) {
            Logx.w("apply notice dialog failed: " + t);
            refreshAndApply();
        }
    }

    private void refreshAndApply() {
        refresh();
        toast("开始扫描并应用 Mod…");
        ProgressBus.begin(this, "正在应用 Mod");
        ProgressBus.report(2, "扫描 Mod 目录…");
        ModLoader.requestApplyAsync();
        new Thread(new Runnable() { public void run() {
            for (int i = 0; i < 240; i++) {
                try { Thread.sleep(250); } catch (Throwable ignored) { }
                if (!com.bluerebirth.mods.ModApplier.applyRunning) break;
                ProgressBus.report(com.bluerebirth.mods.ModApplier.applyProgress, "正在覆盖文件…");
            }
            ProgressBus.report(100, "应用完成");
            try { Thread.sleep(400); } catch (Throwable ignored) { }
            ProgressBus.end();
            runOnUiThread(new Runnable() { public void run() { refresh(); } });
        }}, "br-apply-progress").start();
    }

    /** 导入外部存档：标记后重启进程，让服务端启动前完成覆盖。 */
    private void importSave() {
        try {
            final File src = new File(new File(ModPaths.savesDir, "bo-data"), "profiles.db");
            if (!src.exists()) { toast("未找到外部存档：" + src.getAbsolutePath()); return; }
            SaveSync.beginImport();
            ProgressBus.begin(this, "正在导入外部存档");
            ProgressBus.report(8, "校验存档文件…");
            new Thread(new Runnable() { public void run() {
                try {
                    Thread.sleep(250);
                    ProgressBus.report(30, "准备写入服务端存档…");
                    Thread.sleep(250);
                    ModLoader.requestSaveImport();
                    ProgressBus.report(70, "写入存档（" + (src.length() / 1024) + " KB）…");
                    Thread.sleep(350);
                    ProgressBus.report(100, "导入完成，即将重启启动器");
                    Thread.sleep(450);
                } catch (Throwable ignored) { }
                ProgressBus.end();
                runOnUiThread(new Runnable() { public void run() {
                    toast("存档已就绪，正在重启完成导入（无需 root）…");
                    restartSoon();
                }});
            }}, "br-import-progress").start();
        } catch (Throwable t) { toast("导入失败：" + t); }
    }

    /** 导入完成后（下一次打开管理器）弹出无 root 引导：一键跳转系统应用设置清数据。 */
    private void maybeShowImportGuide() {
        try {
            File flag = new File(ModPaths.privateDir, "import-done.flag");
            if (!flag.exists()) return;
            flag.delete();
            AlertDialog.Builder b = new AlertDialog.Builder(this);
            b.setTitle("存档导入完成！请清除旧账号缓存");
            String msg = "存档已经替换成功。为了确保游戏显示新账号，请按下面步骤操作：\n\n"
                    + "1. 点下面「一键跳转应用设置」\n"
                    + "2. 在系统页面点「存储」\n"
                    + "3. 点「清除数据」（不会删除游戏安装包本身）\n"
                    + "4. 返回启动器，点「开始游戏」\n\n"
                    + "清理后第一次进游戏会重新下载资源，请耐心等待。";
            b.setMessage(msg);
            b.setPositiveButton("一键跳转应用设置", new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface d, int w) { openClientSettings(); }
            });
            b.setNeutralButton("开启悬浮提示", new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface d, int w) { openOverlaySettings(); }
            });
            b.show();
            Logx.i("import guidance dialog shown (no-root flow)");
        } catch (Throwable t) {
            Logx.w("import guidance dialog failed: " + t);
        }
    }

    private void openOverlaySettings() {
        try {
            Intent i = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION);
            i.setData(Uri.parse("package:" + getPackageName()));
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(i);
        } catch (Throwable t) { toast("打开悬浮窗设置失败：" + t); }
    }

    /** 还原完成后的无 root 引导：清除客户端旧数据，否则客户端会提示"有可用更新"。 */
    private void maybeShowRestoreGuide() {
        try {
            File flag = new File(ModPaths.privateDir, "restore-done.flag");
            if (!flag.exists()) return;
            flag.delete();
            AlertDialog.Builder b = new AlertDialog.Builder(this);
            b.setTitle("已恢复纯净原版！请清除旧客户端数据");
            b.setMessage("启动器已关闭全部 Mod 并恢复原始版本号。\n\n"
                    + "为避免客户端提示「有可用更新」，请执行：\n"
                    + "1. 点下面「一键跳转应用设置」\n"
                    + "2. 点「存储」→「清空存储空间」→「删除」\n"
                    + "3. 返回启动器，点「开始游戏」\n\n"
                    + "清除后首次进游戏会重新下载约 3GB 原版资源。");
            b.setPositiveButton("一键跳转应用设置", new DialogInterface.OnClickListener() {
                public void onClick(DialogInterface d, int w) { openClientSettings(); }
            });
            b.setNeutralButton("我知道了", null);
            b.show();
            Logx.i("restore guidance dialog shown (no-root flow)");
        } catch (Throwable t) {
            Logx.w("restore guidance dialog failed: " + t);
        }
    }

    private void openClientSettings() {
        try {
            Intent i = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            i.setData(Uri.parse("package:" + com.bluerebirth.mods.ClientCache.CLIENT_PKG));
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(i);
        } catch (Throwable t) { toast("打开设置失败：" + t); }
    }

    /** 一键恢复纯净原版：关闭全部 Mod、撤销覆盖、版本回退到干净状态后重启。 */
    private void resetVanilla() {
        try {
            AlertDialog.Builder b = new AlertDialog.Builder(this);
            b.setTitle("一键恢复纯净原版？");
            b.setMessage("将关闭全部 Mod、还原服务端文件，并把版本回退到干净状态。\n\n恢复后需要清除客户端旧数据并重新下载资源，确定继续吗？");
            b.setPositiveButton("确认恢复", new DialogInterface.OnClickListener() { public void onClick(DialogInterface d, int w) { doResetVanilla(); } });
            b.setNegativeButton("取消", null);
            b.show();
        } catch (Throwable t) {
            doResetVanilla();
        }
    }

    private void doResetVanilla() {
        try {
            ProgressBus.begin(this, "正在恢复纯净原版");
            ProgressBus.report(5, "关闭全部 Mod…");
            new Thread(new Runnable() { public void run() {
                try {
                    Thread.sleep(250);
                    ProgressBus.report(35, "撤销文件覆盖…");
                    Thread.sleep(250);
                    ProgressBus.report(65, "回退版本号…");
                    ModLoader.requestVanillaReset();
                    ProgressBus.report(90, "清理完成，准备重启…");
                    Thread.sleep(400);
                    ProgressBus.report(100, "完成，即将重启启动器");
                    Thread.sleep(450);
                } catch (Throwable ignored) { }
                ProgressBus.end();
                try {
                    android.content.SharedPreferences sp = getSharedPreferences("br_ui", 0);
                    sp.edit().putBoolean("restore_pending", true).putBoolean("restore_done", false).commit();
                } catch (Throwable ignored) { }
                try { Thread.sleep(400); } catch (Throwable ignored) { }
                Process.killProcess(Process.myPid());
            }}, "br-restore-progress").start();
        } catch (Throwable t) { toast("恢复失败：" + t); }
    }

    /** 写入设置后结束进程，并发出可点击的通知（Android 14 禁止后台自动拉起 Activity）。 */
    private void restartSoon() {
        Relauncher.relaunchWithNotice(this, "BlueRebirth 设置已保存", "点击此通知重新打开，完成导入/还原（由服务端启动前执行）");
    }

    private void requestAllFiles() {
        try {
            if (Build.VERSION.SDK_INT >= 30) {
                Intent i = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                i.setData(Uri.parse("package:" + getPackageName()));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                toast("请在本页打开『允许管理所有文件』后返回");
            } else {
                toast("当前系统无需该权限，直接使用 Mod 目录即可");
            }
        } catch (Throwable t) {
            try { startActivity(new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)); }
            catch (Throwable t2) { toast("无法打开权限页，请到系统设置手动授权"); }
        }
    }

    private void openLauncher() {
        finish();
    }

    private void toast(String s) {
        try { Toast.makeText(this, s, Toast.LENGTH_SHORT).show(); } catch (Throwable ignored) { }
    }
}
