package com.bluerebirth.mods;

import android.app.Activity;
import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/** Builds the launcher UI from assets/bluerebirth/ui_layout.xml (keeps layout out of code). */
public final class UiLayout {
    private final Activity activity;
    private final Map<String, View> views = new HashMap<String, View>();

    private UiLayout(Activity a) { this.activity = a; }

    public static Map<String, View> inflate(Activity a, LinearLayout root, String xml) {
        UiLayout ui = new UiLayout(a);
        try {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder()
                    .parse(new java.io.ByteArrayInputStream(xml.getBytes("UTF-8")));
            Element top = doc.getDocumentElement();
            NodeList kids = top.getChildNodes();
            for (int i = 0; i < kids.getLength(); i++) {
                Node n = kids.item(i);
                if (n instanceof Element) ui.build((Element) n, root, -1);
            }
        } catch (Throwable t) {
            Logx.e("ui_layout parse failed, using minimal UI", t);
            TextView tv = new TextView(a);
            tv.setText("UI 加载失败: " + t);
            tv.setTextColor(Color.WHITE);
            root.addView(tv);
        }
        return ui.views;
    }

    private int pad(String s, int idx) {
        try {
            String[] p = s.split(",");
            return Integer.parseInt(p[idx % p.length].trim());
        } catch (Throwable t) { return 0; }
    }

    private void build(Element e, LinearLayout parent, int weight) {
        String tag = e.getTagName();
        String id = attr(e, "id", null);
        if ("text".equals(tag)) {
            TextView tv = new TextView(activity);
            tv.setText(attr(e, "text", ""));
            String style = attr(e, "style", "");
            if ("title".equals(style)) { tv.setTextSize(22); tv.setTextColor(0xFF1C2B4A); tv.setGravity(Gravity.CENTER); tv.setPadding(0, 6, 0, 4); }
            else if ("status".equals(style)) { tv.setTextSize(10); tv.setTextColor(0xFF5B6C8F); tv.setPadding(24, 2, 24, 2); }
            else { tv.setTextSize(14); tv.setTextColor(0xFF1C2B4A); }
            add(parent, tv, weight, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f);
            if (id != null) views.put(id, tv);
        } else if ("button".equals(tag)) {
            Button b = new Button(activity);
            b.setText(attr(e, "text", ""));
            b.setTextSize(16);
            b.setTextColor(0xFFFFFFFF);
            b.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
            b.setMinHeight(dp(44));
            b.setElevation(dp(2));
            try {
                int bg = activity.getResources().getIdentifier("btn_blue", "drawable", activity.getPackageName());
                if (bg != 0) b.setBackgroundResource(bg);
            } catch (Throwable ignored) { }
            add(parent, b, weight, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f);
            if (id != null) views.put(id, b);
        } else if ("row".equals(tag)) {
            LinearLayout row = new LinearLayout(activity);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setPadding(dp(20), dp(6), dp(20), dp(6));
            NodeList kids = e.getChildNodes();
            for (int i = 0; i < kids.getLength(); i++) {
                if (kids.item(i) instanceof Element) build((Element) kids.item(i), row, -1);
            }
            parent.addView(row);
        } else if ("scroll".equals(tag)) {
            ScrollView sv = new ScrollView(activity);
            LinearLayout inner = new LinearLayout(activity);
            inner.setOrientation(LinearLayout.VERTICAL);
            String p = attr(e, "padding", "");
            if (p.length() > 0) inner.setPadding(pad(p, 0), pad(p, 1), pad(p, 2), pad(p, 3));
            sv.addView(inner);
            String w = attr(e, "weight", "");
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, 0, w.length() > 0 ? 1.0f : 0.0f);
            parent.addView(sv, lp);
            if (id != null) views.put(id, inner);
        } else {
            NodeList kids = e.getChildNodes();
            for (int i = 0; i < kids.getLength(); i++) {
                if (kids.item(i) instanceof Element) build((Element) kids.item(i), parent, -1);
            }
        }
    }

    private int dp(int v) {
        try { return (int) (v * activity.getResources().getDisplayMetrics().density + 0.5f); }
        catch (Throwable t) { return v * 2; }
    }

    private void add(LinearLayout parent, View v, int weight, int height, float w) {
        LinearLayout.LayoutParams lp;
        if (parent.getOrientation() == LinearLayout.HORIZONTAL) {
            lp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1.0f);
            lp.setMargins(dp(6), 0, dp(6), 0);
        } else {
            lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT);
        }
        parent.addView(v, lp);
    }

    private static String attr(Element e, String name, String def) {
        try {
            String v = e.getAttribute(name);
            return v == null || v.length() == 0 ? def : v;
        } catch (Throwable t) { return def; }
    }

    public static String readAsset(Activity a, String name) throws Exception {
        InputStream in = a.getAssets().open(name);
        try {
            java.io.ByteArrayOutputStream bo = new java.io.ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0) bo.write(buf, 0, n);
            return new String(bo.toByteArray(), "UTF-8");
        } finally { in.close(); }
    }
}
