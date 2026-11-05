package com.bluerebirth.mods;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

public final class FileOps {
    public static void copy(File src, File dst) throws Exception {
        File parent = dst.getParentFile();
        if (parent != null) parent.mkdirs();
        InputStream in = new FileInputStream(src);
        try {
            OutputStream out = new FileOutputStream(dst);
            try {
                byte[] buf = new byte[65536];
                int n;
                while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
                out.flush();
            } finally { out.close(); }
        } finally { in.close(); }
    }

    public static void copyOrMove(File src, File dst) throws Exception { copy(src, dst); }

    public static List<File> listFilesRec(File root) {
        List<File> out = new ArrayList<File>();
        walk(root, out);
        return out;
    }

    private static void walk(File f, List<File> out) {
        if (f == null || !f.exists()) return;
        if (f.isFile()) { out.add(f); return; }
        File[] children = f.listFiles();
        if (children == null) return;
        for (File c : children) walk(c, out);
    }

    public static boolean deleteRec(File f) {
        if (f == null || !f.exists()) return true;
        if (f.isDirectory()) {
            File[] cs = f.listFiles();
            if (cs != null) for (File c : cs) deleteRec(c);
        }
        return f.delete();
    }

    public static String readText(File f) throws Exception {
        FileInputStream in = new FileInputStream(f);
        try {
            byte[] b = new byte[(int) f.length()];
            int off = 0;
            while (off < b.length) {
                int n = in.read(b, off, b.length - off);
                if (n <= 0) break;
                off += n;
            }
            return new String(b, 0, off, "UTF-8");
        } finally { in.close(); }
    }

    /** Read text trying UTF-8 first, then GBK (PC mods may be ANSI/GBK). */
    public static String readTextAuto(File f) throws Exception {
        byte[] b = readBytes(f);
        try {
            java.nio.charset.CharsetDecoder dec = java.nio.charset.Charset.forName("UTF-8").newDecoder();
            dec.onMalformedInput(java.nio.charset.CodingErrorAction.REPORT);
            dec.onUnmappableCharacter(java.nio.charset.CodingErrorAction.REPORT);
            return dec.decode(java.nio.ByteBuffer.wrap(b)).toString();
        } catch (Throwable t) {
            try { return new String(b, "GBK"); } catch (Throwable t2) { return new String(b, "UTF-8"); }
        }
    }

    public static byte[] readBytes(File f) throws Exception {
        FileInputStream in = new FileInputStream(f);
        try {
            byte[] b = new byte[(int) f.length()];
            int off = 0;
            while (off < b.length) {
                int n = in.read(b, off, b.length - off);
                if (n <= 0) break;
                off += n;
            }
            if (off == b.length) return b;
            byte[] r = new byte[off];
            System.arraycopy(b, 0, r, 0, off);
            return r;
        } finally { in.close(); }
    }

    public static void writeText(File f, String text) throws Exception {
        File parent = f.getParentFile();
        if (parent != null) parent.mkdirs();
        FileOutputStream out = new FileOutputStream(f);
        try { out.write(text.getBytes("UTF-8")); out.flush(); } finally { out.close(); }
    }

    public static void writeBytes(File f, byte[] data) throws Exception {
        File parent = f.getParentFile();
        if (parent != null) parent.mkdirs();
        FileOutputStream out = new FileOutputStream(f);
        try { out.write(data); out.flush(); } finally { out.close(); }
    }
}
