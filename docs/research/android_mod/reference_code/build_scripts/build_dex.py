# -*- coding: utf-8 -*-
"""Compile Java mod runtime -> classes2.dex (javac + d8)."""
import os, subprocess, sys, zipfile, shutil, glob
ROOT = r'E:/苍蓝_work/work/lead/modsrc'
WORK = r'E:/苍蓝_work/work/lead/build'
JDK = r'E:/苍蓝_work/work/tools/jdk-17.0.20.1+1/bin'
JAVAC = os.path.join(JDK, 'javac.exe')
JAR = os.path.join(JDK, 'jar.exe')
JAVA = os.path.join(JDK, 'java.exe')
R8 = r'E:/苍蓝_work/work/tools/dl/r8-8.2.42.jar'
LUAJ = r'E:/苍蓝_work/work/tools/dl/luaj-jse-3.0.1.jar'
OUT = os.path.join(WORK, 'dex')

def run(cmd, **kw):
    print('+', ' '.join(cmd[:4]), '...')
    p = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if p.returncode != 0:
        print(p.stdout[-6000:]); print(p.stderr[-6000:])
        raise SystemExit('FAILED: ' + ' '.join(cmd[:3]) + ' rc=' + str(p.returncode))
    return p

def main():
    os.makedirs(OUT, exist_ok=True)
    stubs_out = os.path.join(WORK, 'stubclasses')
    mod_out = os.path.join(WORK, 'modclasses')
    for d in (stubs_out, mod_out):
        shutil.rmtree(d, ignore_errors=True); os.makedirs(d)
    stubs = []
    for root, _, files in os.walk(os.path.join(ROOT, 'stubs')):
        for f in files:
            if f.endswith('.java'): stubs.append(os.path.join(root, f))
    srcs = []
    for root, _, files in os.walk(os.path.join(ROOT, 'src')):
        for f in files:
            if f.endswith('.java'): srcs.append(os.path.join(root, f))
    print('stubs', len(stubs), 'srcs', len(srcs))
    run([JAVAC, '-nowarn', '-source', '8', '-target', '8', '-encoding', 'UTF-8', '-d', stubs_out] + stubs)
    run([JAVAC, '-nowarn', '-source', '8', '-target', '8', '-encoding', 'UTF-8',
         '-cp', stubs_out + os.pathsep + LUAJ, '-d', mod_out] + srcs)
    our_jar = os.path.join(WORK, 'mod.jar')
    if os.path.exists(our_jar): os.remove(our_jar)
    run([JAR, 'cf', our_jar, '-C', mod_out, '.'])
    # strip luaj classes that need Java SE only packages
    lua_jar = os.path.join(WORK, 'luaj-dex.jar')
    zin = zipfile.ZipFile(LUAJ)
    with zipfile.ZipFile(lua_jar, 'w', zipfile.ZIP_DEFLATED) as zout:
        for info in zin.infolist():
            n = info.filename
            if n.startswith('org/luaj/vm2/script/') or n.startswith('org/luaj/vm2/luajc/'): continue
            zout.writestr(info, zin.read(n))
    print('luaj stripped classes ->', lua_jar, os.path.getsize(lua_jar))
    run([JAVA, '-cp', R8, 'com.android.tools.r8.D8', '--min-api', '22', '--no-desugaring',
         '--output', OUT, our_jar, lua_jar])
    dex = os.path.join(OUT, 'classes.dex')
    print('DEX OK', dex, os.path.getsize(dex) if os.path.exists(dex) else 'MISSING')

if __name__ == '__main__':
    main()
