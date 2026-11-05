# -*- coding: utf-8 -*-
import io, os, zipfile, shutil, sys
UI = r'E:/苍蓝_work/UI修改/_uiwork'
BASE = os.path.join(UI, 'BlueRebirth_ui-aligned-debugSigned.apk')
LEAD = r'E:/苍蓝_work/work/lead'
DEX2 = os.path.join(LEAD, 'build', 'dex', 'classes.dex')
UIXML = os.path.join(LEAD, 'modsrc', 'assets', 'bluerebirth', 'ui_layout.xml')
OUT = os.path.join(LEAD, 'out', 'ui_redo', 'launcher-ui-redo-unsigned.apk')
os.makedirs(os.path.dirname(OUT), exist_ok=True)

# 改 assets ui_layout.xml 文案
s = io.open(UIXML, encoding='utf-8').read()
s = s.replace('打开启动器 ▶', '返回启动器主页').replace('打开启动器', '返回启动器主页')
io.open(UIXML, 'w', encoding='utf-8', newline='\n').write(s)

repl = {
  'classes2.dex': open(DEX2, 'rb').read(),
  'assets/bluerebirth/ui_layout.xml': s.encode('utf-8'),
}
zin = zipfile.ZipFile(BASE)
zout = zipfile.ZipFile(OUT, 'w', zipfile.ZIP_DEFLATED)
written = set()
for info in zin.infolist():
    name = info.filename
    if name.startswith('META-INF/'):
        continue
    if name in repl:
        continue
    data = zin.read(name)
    if name.endswith('.arsc') or info.compress_type == 0:
        zout.writestr(info, data, compress_type=zipfile.ZIP_STORED)
    else:
        zout.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)
for name, data in repl.items():
    zi = zipfile.ZipInfo(name)
    zi.compress_type = zipfile.ZIP_DEFLATED
    zout.writestr(zi, data)
zout.close(); zin.close()
print('built', OUT, os.path.getsize(OUT))
