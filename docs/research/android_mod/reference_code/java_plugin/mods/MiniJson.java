package com.bluerebirth.mods;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/** Minimal JSON parser/serializer preserving object key order; used for config db payloads. */
public final class MiniJson {
    private final String s;
    private int p;

    private MiniJson(String s) { this.s = s; this.p = 0; }

    public static Object parse(String text) {
        MiniJson j = new MiniJson(text);
        j.ws();
        Object v = j.value();
        j.ws();
        return v;
    }

    private void ws() { while (p < s.length() && Character.isWhitespace(s.charAt(p))) p++; }

    private Object value() {
        if (p >= s.length()) throw new RuntimeException("json: eof");
        char c = s.charAt(p);
        if (c == '{') return obj();
        if (c == '[') return arr();
        if (c == '"') return str();
        if (s.startsWith("true", p)) { p += 4; return Boolean.TRUE; }
        if (s.startsWith("false", p)) { p += 5; return Boolean.FALSE; }
        if (s.startsWith("null", p)) { p += 4; return null; }
        return num();
    }

    private Map<String, Object> obj() {
        Map<String, Object> m = new LinkedHashMap<String, Object>();
        p++; ws();
        if (p < s.length() && s.charAt(p) == '}') { p++; return m; }
        while (true) {
            ws();
            String k = str();
            ws();
            if (p >= s.length() || s.charAt(p) != ':') throw new RuntimeException("json: expected :");
            p++;
            ws();
            m.put(k, value());
            ws();
            if (p < s.length() && s.charAt(p) == ',') { p++; continue; }
            if (p < s.length() && s.charAt(p) == '}') { p++; return m; }
            throw new RuntimeException("json: bad obj");
        }
    }

    private List<Object> arr() {
        List<Object> a = new ArrayList<Object>();
        p++; ws();
        if (p < s.length() && s.charAt(p) == ']') { p++; return a; }
        while (true) {
            ws();
            a.add(value());
            ws();
            if (p < s.length() && s.charAt(p) == ',') { p++; continue; }
            if (p < s.length() && s.charAt(p) == ']') { p++; return a; }
            throw new RuntimeException("json: bad arr");
        }
    }

    private String str() {
        if (s.charAt(p) != '"') throw new RuntimeException("json: expected string");
        p++;
        StringBuilder b = new StringBuilder();
        while (p < s.length()) {
            char c = s.charAt(p++);
            if (c == '"') return b.toString();
            if (c != '\\') { b.append(c); continue; }
            if (p >= s.length()) break;
            char e = s.charAt(p++);
            switch (e) {
                case '"': b.append('"'); break;
                case '\\': b.append('\\'); break;
                case '/': b.append('/'); break;
                case 'b': b.append('\b'); break;
                case 'f': b.append('\f'); break;
                case 'n': b.append('\n'); break;
                case 'r': b.append('\r'); break;
                case 't': b.append('\t'); break;
                case 'u':
                    b.append((char) Integer.parseInt(s.substring(p, p + 4), 16));
                    p += 4;
                    break;
                default: throw new RuntimeException("json: bad escape");
            }
        }
        throw new RuntimeException("json: unterminated string");
    }

    private Object num() {
        int st = p;
        while (p < s.length()) {
            char c = s.charAt(p);
            if (c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E' || (c >= '0' && c <= '9')) p++;
            else break;
        }
        String t = s.substring(st, p);
        if (t.length() == 0) throw new RuntimeException("json: bad number at " + st);
        try {
            if (t.indexOf('.') < 0 && t.indexOf('e') < 0 && t.indexOf('E') < 0) {
                long l = Long.parseLong(t);
                if (l >= Integer.MIN_VALUE && l <= Integer.MAX_VALUE) return Integer.valueOf((int) l);
                return Long.valueOf(l);
            }
            return Double.valueOf(t);
        } catch (NumberFormatException ex) {
            return Double.valueOf(t);
        }
    }

    public static String write(Object v) { StringBuilder b = new StringBuilder(); writeTo(b, v, false); return b.toString(); }
    public static String writeSorted(Object v) { StringBuilder b = new StringBuilder(); writeTo(b, v, true); return b.toString(); }

    @SuppressWarnings("unchecked")
    private static void writeTo(StringBuilder b, Object v, boolean sorted) {
        if (v == null) { b.append("null"); return; }
        if (v instanceof String) { esc(b, (String) v); return; }
        if (v instanceof Boolean) { b.append(((Boolean) v).booleanValue() ? "true" : "false"); return; }
        if (v instanceof Number) {
            double d = ((Number) v).doubleValue();
            if (d == Math.rint(d) && !Double.isInfinite(d) && Math.abs(d) < 9.007199254740992E15) {
                b.append((long) d);
            } else {
                b.append(Double.toString(d));
            }
            return;
        }
        if (v instanceof Map) {
            Map<String, Object> m = (Map<String, Object>) v;
            if (sorted) m = new TreeMap<String, Object>(m);
            b.append('{');
            boolean first = true;
            for (Map.Entry<String, Object> e : m.entrySet()) {
                if (!first) b.append(',');
                first = false;
                esc(b, e.getKey());
                b.append(':');
                writeTo(b, e.getValue(), sorted);
            }
            b.append('}');
            return;
        }
        if (v instanceof List) {
            b.append('[');
            boolean first = true;
            for (Object o : (List<Object>) v) {
                if (!first) b.append(',');
                first = false;
                writeTo(b, o, sorted);
            }
            b.append(']');
            return;
        }
        esc(b, String.valueOf(v));
    }

    private static void esc(StringBuilder b, String s) {
        b.append('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"': b.append("\\\""); break;
                case '\\': b.append("\\\\"); break;
                case '\n': b.append("\\n"); break;
                case '\r': b.append("\\r"); break;
                case '\t': b.append("\\t"); break;
                case '\b': b.append("\\b"); break;
                case '\f': b.append("\\f"); break;
                default:
                    if (c < 0x20) b.append(String.format("\\u%04x", (int) c));
                    else b.append(c);
            }
        }
        b.append('"');
    }
}
