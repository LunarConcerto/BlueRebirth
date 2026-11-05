# -*- coding: utf-8 -*-
"""Build patched launcher APK: raw-copy base APK entries, replace classes.dex,
add classes2.dex + assets/bluerebirth/bootstrap.lua, drop old signatures."""
import sys, os, struct, zlib

def u16(b, o): return struct.unpack_from('<H', b, o)[0]
def u32(b, o): return struct.unpack_from('<I', b, o)[0]

def main():
    base = r'E:/苍蓝_work/work/saves/launcher-saveexport-fixed.apk'   # patched manifest/resources
    orig = r'E:/苍蓝_work/work/lead/build/base.apk'                    # clean classes.dex
    dex2 = r'E:/苍蓝_work/work/lead/build/dex/classes.dex'
    boot = r'E:/苍蓝_work/work/lead/modsrc/assets/bluerebirth/bootstrap.lua'
    out  = r'E:/苍蓝_work/work/lead/out/launcher-mods-unsigned.apk'
    add = {}
    add['classes.dex'] = open(orig, 'rb')  # placeholder replaced below
    # read original classes.dex entry bytes
    import zipfile
    zorig = zipfile.ZipFile(orig)
    add['classes.dex'] = zorig.read('classes.dex')
    add['classes2.dex'] = open(dex2, 'rb').read()
    add['assets/bluerebirth/bootstrap.lua'] = open(boot, 'rb').read()
    ui = r'E:/苍蓝_work/work/lead/modsrc/assets/bluerebirth/ui_layout.xml'
    add['assets/bluerebirth/ui_layout.xml'] = open(ui, 'rb').read()
    keep_add_names = ['classes2.dex', 'assets/bluerebirth/bootstrap.lua', 'assets/bluerebirth/ui_layout.xml']

    f = open(base, 'rb')
    fsize = os.path.getsize(base)
    tail_len = min(fsize, 66000)
    f.seek(fsize - tail_len); tail = f.read()
    i = tail.rfind(b'PK\x05\x06'); assert i >= 0
    eocd = tail[i:i+22]
    n_total = u16(eocd, 10); cd_size = u32(eocd, 12); cd_off = u32(eocd, 16)
    f.seek(cd_off); cd = f.read(cd_size)
    out_f = open(out, 'wb')
    new_cd = bytearray(); off = 0; p = 0; n_out = 0; replaced = 0
    while p < len(cd):
        assert cd[p:p+4] == b'PK\x01\x02'
        flags = u16(cd, p+8); method = u16(cd, p+10)
        crc = u32(cd, p+16); csize = u32(cd, p+20); usize = u32(cd, p+24)
        fnl = u16(cd, p+28); exl = u16(cd, p+30); cml = u16(cd, p+32)
        ext_attr = u32(cd, p+38); lho = u32(cd, p+42)
        name_b = cd[p+46:p+46+fnl]
        name = name_b.decode('utf-8', 'replace')
        rec_len = 46 + fnl + exl + cml
        if name.startswith('META-INF/'):
            p += rec_len; continue
        if name in add:
            data = add[name]; method = 8; flags &= ~0x8
            co = zlib.compressobj(6, zlib.DEFLATED, -15)
            payload = co.compress(data) + co.flush()
            crc = zlib.crc32(data) & 0xffffffff
            csize = len(payload); usize = len(data)
            replaced += 1
        else:
            f.seek(lho); lh = f.read(30)
            lfnl = u16(lh, 26); lexl = u16(lh, 28)
            f.seek(lho); lhfull = f.read(30 + lfnl + lexl)
            payload = f.read(csize)
            flags &= ~0x8
        lh = struct.pack('<IHHHHHIIIHH', 0x04034b50, 20, flags, method, 0, 0, crc, csize, usize, fnl, 0)
        out_f.write(lh); out_f.write(name_b); out_f.write(payload)
        new_cd += struct.pack('<IHHHHHHIIIHHHHHII', 0x02014b50, 20, 20, flags, method, 0, 0,
                              crc, csize, usize, fnl, 0, 0, 0, 0, ext_attr, off)
        new_cd += name_b
        off += 30 + fnl + len(payload); n_out += 1
        p += rec_len
    for name in keep_add_names:
        data = add[name]; name_b = name.encode('utf-8')
        co = zlib.compressobj(6, zlib.DEFLATED, -15)
        payload = co.compress(data) + co.flush()
        crc = zlib.crc32(data) & 0xffffffff
        lh = struct.pack('<IHHHHHIIIHH', 0x04034b50, 20, 0, 8, 0, 0, crc, len(payload), len(data), len(name_b), 0)
        out_f.write(lh); out_f.write(name_b); out_f.write(payload)
        new_cd += struct.pack('<IHHHHHHIIIHHHHHII', 0x02014b50, 20, 20, 0, 8, 0, 0,
                              crc, len(payload), len(data), len(name_b), 0, 0, 0, 0, 0, off)
        new_cd += name_b
        off += 30 + len(name_b) + len(payload); n_out += 1
    cd_start = out_f.tell()
    out_f.write(new_cd)
    out_f.write(struct.pack('<IHHHHIIH', 0x06054b50, 0, 0, n_out, n_out, len(new_cd), cd_start, 0))
    out_f.close()
    print('built', out, os.path.getsize(out), 'entries', n_out, 'replaced', replaced)

main()
