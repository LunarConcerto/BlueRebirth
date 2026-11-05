
# -*- coding: utf-8 -*-
import os, json, hashlib, zipfile
import UnityPy
MODS = r'E:/苍蓝_work/deliver/Mods'
LOCMOD = os.path.join(MODS, 'localization.mod')
VOICEMOD = os.path.join(MODS, 'cn-voice.mod')
LOC_AM = os.path.join(LOCMOD, 'files', 'bundle', 'assetmap')
VOICE_AM = os.path.join(VOICEMOD, 'files', 'bundle', 'assetmap')

def save_lz4(src_big, out):
    env = UnityPy.load(src_big)
    for obj in env.objects:
        if obj.type.name != 'TextAsset': continue
        x = obj.read()
        s = getattr(x,'m_Script',None) or getattr(x,'script',None)
        text = (s.encode('utf-8') if isinstance(s,str) else bytes(s)).decode('utf-8')
        break
    data = env.file.save(packer='lz4')
    open(out,'wb').write(data)
    # verify
    env2 = UnityPy.load(out)
    for o2 in env2.objects:
        if o2.type.name != 'TextAsset': continue
        y = o2.read(); s2 = getattr(y,'m_Script',None) or getattr(y,'script',None)
        t2 = (s2.encode('utf-8') if isinstance(s2,str) else bytes(s2)).decode('utf-8')
        break
    lines = t2.splitlines()
    def find(k): return next((l for l in lines if l.startswith(k+',')), 'MISSING')
    return len(data), lines[0], find('config/config_plot_episode_character.db'), find('config/config_plot_episode_event.db'), find('wwise/c_cl_ninghai_jp_bank.bnk')

n1, v1, c1, e1, w1 = save_lz4(LOC_AM + '.big', LOC_AM)
n2, v2, c2, e2, w2 = save_lz4(VOICE_AM + '.big', VOICE_AM)
print('LOC', n1, v1, 'char_ok', 'E572D9F1' in c1, 'wwise_orig', '2E7D3164' in w1)
print('VOICE', n2, v2, 'char_ok', 'E572D9F1' in c2, 'wwise_cn', '800F2FBB' in w2)

# cleanup temp
for f in os.listdir(os.path.dirname(LOC_AM)):
    if f.endswith(('.big','.lz4','.lzma','.original','.none')):
        os.remove(os.path.join(os.path.dirname(LOC_AM), f))
for f in os.listdir(os.path.dirname(VOICE_AM)):
    if f.endswith(('.big','.lz4','.lzma','.original','.none')):
        os.remove(os.path.join(os.path.dirname(VOICE_AM), f))

# rebuild zip
zpath = r'E:/苍蓝_work/发给我朋友的最终包/04_核心Mod包(解压放手机里).zip'
tmp = zpath + '.new'
if os.path.exists(tmp): os.remove(tmp)
with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
    for r0, ds, fs in os.walk(MODS):
        for f in fs:
            p = os.path.join(r0, f)
            rel = os.path.relpath(p, MODS).replace('\\','/')
            z.write(p, rel)
os.replace(tmp, zpath)

# final summary
summary = {
  'assetmap_loc': {'size': os.path.getsize(LOC_AM), 'md5': hashlib.md5(open(LOC_AM,'rb').read()).hexdigest().upper()},
  'assetmap_voice': {'size': os.path.getsize(VOICE_AM), 'md5': hashlib.md5(open(VOICE_AM,'rb').read()).hexdigest().upper()},
  'zip': {'size': os.path.getsize(zpath), 'sha256': hashlib.sha256(open(zpath,'rb').read()).hexdigest()},
  'db_char': {'size': os.path.getsize(os.path.join(LOCMOD,'files','bundle','config','config_plot_episode_character.db')),
              'md5': hashlib.md5(open(os.path.join(LOCMOD,'files','bundle','config','config_plot_episode_character.db'),'rb').read()).hexdigest().upper()},
  'db_event': {'size': os.path.getsize(os.path.join(LOCMOD,'files','bundle','config','config_plot_episode_event.db')),
               'md5': hashlib.md5(open(os.path.join(LOCMOD,'files','bundle','config','config_plot_episode_event.db'),'rb').read()).hexdigest().upper()},
}
print(json.dumps(summary, ensure_ascii=False, indent=1))
