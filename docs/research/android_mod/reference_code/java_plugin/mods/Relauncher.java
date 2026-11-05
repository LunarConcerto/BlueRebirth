package com.bluerebirth.mods;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.os.Build;
import android.os.Process;
import com.bluerebirth.savesync.SetupActivity;

/**
 * Android 13/14 forbid starting an activity from the background (AlarmManager was blocked on
 * Android 14), so after writing a pending-operation marker we post a notification: the user tap
 * is a legal foreground start and the marker is consumed by the next process start.
 */
public final class Relauncher {
    private static final String CHANNEL = "br_setup";

    public static void relaunchWithNotice(Activity a, String title, String text) {
        try {
            Intent i = new Intent(a, SetupActivity.class);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= 23) flags |= PendingIntent.FLAG_IMMUTABLE;
            PendingIntent pi = PendingIntent.getActivity(a, 0, i, flags);
            NotificationManager nm = (NotificationManager) a.getSystemService("notification");
            if (nm != null) {
                if (Build.VERSION.SDK_INT >= 26) {
                    try {
                        nm.createNotificationChannel(new android.app.NotificationChannel(
                                CHANNEL, "BlueRebirth", NotificationManager.IMPORTANCE_DEFAULT));
                    } catch (Throwable ignored) { }
                }
                Notification n;
                if (Build.VERSION.SDK_INT >= 26) {
                    n = new Notification.Builder(a, CHANNEL)
                            .setContentTitle(title).setContentText(text)
                            .setSmallIcon(android.R.drawable.ic_dialog_info)
                            .setContentIntent(pi).setAutoCancel(true).build();
                } else {
                    n = new Notification.Builder(a)
                            .setContentTitle(title).setContentText(text)
                            .setSmallIcon(android.R.drawable.ic_dialog_info)
                            .setContentIntent(pi).setAutoCancel(true).build();
                }
                nm.notify(1001, n);
            }
            Logx.i("relaunch notice posted: " + title);
        } catch (Throwable t) {
            Logx.e("relaunch notice failed", t);
        }
        try { Thread.sleep(900); } catch (Throwable ignored) { }
        try { Process.killProcess(Process.myPid()); } catch (Throwable ignored) { }
    }
}
