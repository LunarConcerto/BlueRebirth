#!/usr/bin/env python3
"""Correctly re-extract JP Lua bytecode (binary) and normalize header to standard Lua 5.3."""
import os
import sys
import UnityPy

root = r"E:\逆向工程\苍蓝誓约项目"
base = os.path.join(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "bundles", "share", "lua")
outdir = os.path.join(root, "runtime", "lua-normalized")
os.makedirs(outdir, exist_ok=True)

prefix = "assets/generatedfiles/lua/32bit/"
total = 0
for fn in sorted(os.listdir(base)):
    p = os.path.join(base, fn)
    if not os.path.isfile(p) or fn.endswith(".manifest"):
        continue
    try:
        env = UnityPy.load(p)
    except Exception:
        continue
    for path, obj in env.container.items():
        if obj.type.name != "TextAsset":
            continue
        ta = obj.read()
        s = ta.m_Script
        raw = bytearray(s.encode('utf-8', 'surrogateescape'))
        # normalize header: fork (format=01, Instruction=8, 4 sizeof) -> standard (format=00, Instruction=4, 5 sizeof)
        if len(raw) >= 16 and raw[:4] == b"\x1bLua":
            raw[5] = 0x00      # format
            raw[14] = 0x04     # sizeof Instruction -> 4
            raw.insert(16, 0x08)  # insert sizeof lua_Number = 8
        logical = path
        if logical.startswith(prefix):
            logical = logical[len(prefix):]
        if logical.endswith(".bytes"):
            logical = logical[:-len(".bytes")]
        if not logical.endswith(".lua"):
            logical += ".lua"
        dest = os.path.join(outdir, logical.replace("/", os.sep))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "wb") as f:
            f.write(bytes(raw))
        total += 1
print(f"TOTAL: {total} normalized lua files -> {outdir}")
