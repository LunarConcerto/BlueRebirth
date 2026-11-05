package com.bluerebirth.mods;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import com.bluerebirth.savesync.SetupActivity;

/**
 * Keeps the launcher/server process out of the Android "cached app freezer".
 * When the game is in the foreground the launcher becomes a cached process; Android 12+
 * freezes it and the local HTTP server stops answering -> the client update times out with
 * "ダウンロードに失敗しました". A foreground service keeps the process active.
 */
public class KeepAliveService extends Service {
    public static final String CHANNEL = "br_keepalive";
    public static final int NOTIF_ID = 7001;

    public void onCreate() {
        super.onCreate();
        try { startForeground(NOTIF_ID, buildNotification("BlueRebirth 本地服务器运行中", "保持后台运行，游戏内更新/登录正常")); }
        catch (Throwable t) { Logx.e("KeepAliveService startForeground failed", t); }
        try {
            java.io.File hint = new java.io.File(ModPaths.privateDir, "import-hint.flag");
            if (hint.exists()) {
                String txt = "正在加载新账号数据…如大厅仍显示旧号，请稍等片刻或重启游戏";
                ImportHintOverlay.show(this, txt, 300000L);
                hint.delete();
                Logx.i("import hint scheduled from keepalive service (flag cleared)");
            }
        } catch (Throwable t) { Logx.w("keepalive hint failed: " + t); }
    }

    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    public IBinder onBind(Intent intent) { return null; }

    private Notification buildNotification(String title, String text) {
        try {
            Intent i = new Intent(this, SetupActivity.class);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
            PendingIntent pi = PendingIntent.getActivity(this, 0, i, flags);
            NotificationManager nm = (NotificationManager) getSystemService("notification");
            if (nm != null && Build.VERSION.SDK_INT >= 26) {
                try { nm.createNotificationChannel(new android.app.NotificationChannel(
                        CHANNEL, "BlueRebirth 后台服务", NotificationManager.IMPORTANCE_LOW)); }
                catch (Throwable ignored) { }
            }
            Notification.Builder b;
            if (Build.VERSION.SDK_INT >= 26) b = new Notification.Builder(this, CHANNEL);
            else b = new Notification.Builder(this);
            return b.setContentTitle(title).setContentText(text)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setContentIntent(pi).setOngoing(true).build();
        } catch (Throwable t) {
            Logx.e("KeepAliveService buildNotification failed", t);
            return null;
        }
    }

    /** Start (or keep) the foreground service. Safe to call from provider/activity. */
    public static void ensure(Context c) {
        try {
            Intent i = new Intent(c, KeepAliveService.class);
            if (Build.VERSION.SDK_INT >= 26) c.startForegroundService(i);
            else c.startService(i);
            Logx.i("KeepAliveService.ensure called");
        } catch (Throwable t) {
            Logx.w("KeepAliveService.ensure failed: " + t);
        }
    }
}
