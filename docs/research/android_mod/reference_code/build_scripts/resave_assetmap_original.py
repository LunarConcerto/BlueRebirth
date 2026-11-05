
# -*- coding: utf-8 -*-
import os, json, hashlib, zipfile
import UnityPy
MODS = r'E:/苍蓝_work/deliver/Mods'
LOCMOD = os.path.join(MODS, 'localization.mod')
VOICEMOD = os.path.join(MODS, 'cn-voice.mod')
LOC_AM = os.path.join(LOCMOD, 'files', 'bundle', 'assetmap')
VOICE_AM = os.path.join(VOICEMOD, 'files', 'bundle', 'assetmap')
W = os.path.join(VOICEMOD, 'files', 'bundle', 'wwise')
VERSION = '1.4.145'

# 备份当前 2.4MB 版本，重新按原压缩格式保存
for p in [LOC_AM, VOICE_AM]:
    if not os.path.exists(p + '.big'): os.replace(p, p + '.big')

def load_text(p):
    env = UnityPy.load(p)
    for obj in env.objects:
        if obj.type.name != 'TextAsset': continue
        x = obj.read(); s = getattr(x, 'm_Script', None) or getattr(x, 'script', None)
        return env, obj, x, (s.encode('utf-8') if isinstance(s, str) else bytes(s)).decode('utf-8')
    raise SystemExit('no textasset')

def save_with(env, obj, x, text, out):
    x.m_Script = text
    x.save()
    try:
        data = env.file.save(packer='original')
    except Exception:
        data = env.file.save()
    open(out, 'wb').write(data)
    return len(data)

# 从大文件中读出已修正的文本内容，按原压缩格式写回
env, obj, x, loc_text = load_text(LOC_AM + '.big')
n1 = save_with(env, obj, x, loc_text, LOC_AM)
env, obj, x, voice_text = load_text(VOICE_AM + '.big')
n2 = save_with(env, obj, x, voice_text, VOICE_AM)
print('resaved LOC', n1, 'VOICE', n2)

# 更新 localization 描述中的版本号
p = os.path.join(LOCMOD, 'mod.json')
o = json.load(open(p, encoding='utf-8'))
o['description'] = o['description'].replace('assetmap 1.4.143', 'assetmap 1.4.145')
json.dump(o, open(p, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)

# 重新打包 04
zpath = r'E:/苍蓝_work/发给我朋友的最终包/04_核心Mod包(解压放手机里).zip'
tmp = zpath + '.new'
if os.path.exists(tmp): os.remove(tmp)
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for r0, ds, fs in os.walk(MODS):
        for f in fs:
            if f.endswith('.big'): continue
            p = os.path.join(r0, f)
            rel = os.path.relpath(p, MODS).replace('\\', '/')
            z.write(p, rel)
os.replace(tmp, zpath)

# 验证重载 & entry
for tag, p in [('LOC', LOC_AM), ('VOICE', VOICE_AM)]:
    env, obj, x, t = load_text(p)
    lines = t.splitlines()
    def find(k): return next((l for l in lines if l.startswith(k+',')), 'MISSING')
    print(tag, 'size', os.path.getsize(p), 'v', lines[0])
    print('  char:', find('config/config_plot_episode_character.db'))
    print('  event:', find('config/config_plot_episode_event.db'))
    print('  wwise:', find('wwise/c_cl_ninghai_jp_bank.bnk'))
print('zip size', os.path.getsize(zpath), 'sha256', hashlib.sha256(open(zpath,'rb').read()).hexdigest())
