
# -*- coding: utf-8 -*-
import os, json, hashlib, zipfile
import UnityPy
MODS = r'E:/苍蓝_work/deliver/Mods'
LOCMOD = os.path.join(MODS, 'localization.mod')
VOICEMOD = os.path.join(MODS, 'cn-voice.mod')
LOC_AM = os.path.join(LOCMOD, 'files', 'bundle', 'assetmap')
VOICE_AM = os.path.join(VOICEMOD, 'files', 'bundle', 'assetmap')

def load_text(p):
    env = UnityPy.load(p)
    for obj in env.objects:
        if obj.type.name != 'TextAsset': continue
        x = obj.read(); s = getattr(x, 'm_Script', None) or getattr(x, 'script', None)
        return env, obj, x, (s.encode('utf-8') if isinstance(s, str) else bytes(s)).decode('utf-8')
    raise SystemExit('no textasset')

def save_uncompressed(src, out, version='1.4.145'):
    env, obj, x, text = load_text(src)
    lines = text.splitlines()
    lines[0] = version
    newtext = '\n'.join(lines) + '\n'
    x.m_Script = newtext
    x.save()
    data = env.file.save(packer='none')
    open(out, 'wb').write(data)
    # verify plain-text version bytes present
    raw = open(out, 'rb').read()
    token = version.encode() + b'\n'
    ok = raw.find(token) >= 0
    print(os.path.basename(out), len(data), 'plaintext_version_found=', ok, 'offset=', raw.find(token))
    return len(data)

# 先备份
for p in [LOC_AM, VOICE_AM]:
    if not os.path.exists(p + '.lz4bak'):
        open(p + '.lz4bak','wb').write(open(p,'rb').read())
save_uncompressed(LOC_AM + '.lz4bak', LOC_AM)
save_uncompressed(VOICE_AM + '.lz4bak', VOICE_AM)

# 重新打包 04
zpath = r'E:/苍蓝_work/发给我朋友的最终包/04_核心Mod包(解压放手机里).zip'
tmp = zpath + '.new'
if os.path.exists(tmp): os.remove(tmp)
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for r0, ds, fs in os.walk(MODS):
        for f in fs:
            if f.endswith('.lz4bak'): continue
            p = os.path.join(r0, f)
            rel = os.path.relpath(p, MODS).replace('\\','/')
            z.write(p, rel)
os.replace(tmp, zpath)
print('zip', os.path.getsize(zpath), hashlib.sha256(open(zpath,'rb').read()).hexdigest())
