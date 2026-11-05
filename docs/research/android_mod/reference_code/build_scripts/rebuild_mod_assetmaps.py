
# -*- coding: utf-8 -*-
import os, json, hashlib, shutil, zipfile
import UnityPy

MODS = r'E:/苍蓝_work/deliver/Mods'
LOCMOD = os.path.join(MODS, 'localization.mod')
VOICEMOD = os.path.join(MODS, 'cn-voice.mod')
LOC_AM = os.path.join(LOCMOD, 'files', 'bundle', 'assetmap')
VOICE_AM = os.path.join(VOICEMOD, 'files', 'bundle', 'assetmap')
W = os.path.join(VOICEMOD, 'files', 'bundle', 'wwise')
VERSION = '1.4.145'

def read_am(path):
    env = UnityPy.load(path)
    items = []
    for obj in env.objects:
        if obj.type.name != 'TextAsset': continue
        x = obj.read(); s = getattr(x, 'm_Script', None) or getattr(x, 'script', None)
        t = (s.encode('utf-8') if isinstance(s, str) else bytes(s)).decode('utf-8')
        items.append((obj, x, t))
    assert len(items) == 1
    return env, items[0]

def patch_am(path_in, out_path, patches, version):
    env, (obj, ta, text) = read_am(path_in)
    lines = text.splitlines()
    idx = {ln.split(',')[0]: i for i, ln in enumerate(lines) if ',' in ln}
    for key, line in patches.items():
        if key in idx:
            lines[idx[key]] = line
        else:
            lines.append(line); idx[key] = len(lines) - 1
    lines[0] = version
    new = '\n'.join(lines) + ('\n' if text.endswith('\n') else '')
    ta.m_Script = new
    ta.save()
    data = env.file.save()
    open(out_path, 'wb').write(data)
    return len(data)

def file_entry_rel(rel, path, gz_size=0):
    data = open(path, 'rb').read()
    return rel + ',' + hashlib.md5(data).hexdigest().upper() + ',' + str(len(data)) + ',' + str(gz_size)

# 1) localization assetmap: update two config dbs
patches_local = {}
for fn in ['config_plot_episode_character.db', 'config_plot_episode_event.db']:
    db = os.path.join(LOCMOD, 'files', 'bundle', 'config', fn)
    gz = os.path.join(LOCMOD, 'files', 'bundle', 'compressed', 'config', fn)
    patches_local['config/' + fn] = file_entry_rel('config/' + fn, db, os.path.getsize(gz))
n = patch_am(LOC_AM, LOC_AM, patches_local, VERSION)
print('localization assetmap updated ->', n, 'bytes')

# 2) cn-voice assetmap: rebuild from updated localization assetmap + wwise entries
patches_voice = {}
for b in sorted(os.listdir(W)):
    rel = 'wwise/' + b
    patches_voice[rel] = file_entry_rel(rel, os.path.join(W, b), 0)
n2 = patch_am(LOC_AM, VOICE_AM, patches_voice, VERSION)
print('cn-voice assetmap rebuilt ->', n2, 'bytes')

# 3) bump clientVersion in both mod.json
for md, newver in [(LOCMOD, '2.0.1'), (VOICEMOD, VERSION)]:
    p = os.path.join(md, 'mod.json')
    o = json.load(open(p, encoding='utf-8'))
    if 'clientVersion' in o: o['clientVersion'] = VERSION
    if md == LOCMOD: o['version'] = newver
    else: o['version'] = VERSION
    json.dump(o, open(p, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)

# 4) rebuild core mods zip in final package
zpath = r'E:/苍蓝_work/发给我朋友的最终包/04_核心Mod包(解压放手机里).zip'
tmp = zpath + '.new'
if os.path.exists(tmp): os.remove(tmp)
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for r0, ds, fs in os.walk(MODS):
        for f in fs:
            p = os.path.join(r0, f)
            rel = os.path.relpath(p, MODS).replace('\\', '/')
            z.write(p, rel)
os.replace(tmp, zpath)
print('core mods zip rebuilt:', os.path.getsize(zpath))

# 5) verify
env = UnityPy.load(VOICE_AM)
for obj in env.objects:
    if obj.type.name != 'TextAsset': continue
    x = obj.read(); s = getattr(x, 'm_Script', None) or getattr(x, 'script', None)
    t = (s.encode('utf-8') if isinstance(s, str) else bytes(s)).decode('utf-8')
    lines = t.splitlines()
    print('VOICE assetmap v', lines[0], 'lines', len(lines))
    for key in ['config/config_plot_episode_character.db','config/config_plot_episode_event.db','wwise/c_cl_ninghai_jp_bank.bnk']:
        hit = [l for l in lines if l.startswith(key + ',')]
        print(' ', hit[0] if hit else 'MISSING ' + key)
print('mod.json loc:', json.load(open(os.path.join(LOCMOD,'mod.json'), encoding='utf-8')))
print('mod.json voice:', json.load(open(os.path.join(VOICEMOD,'mod.json'), encoding='utf-8')))
