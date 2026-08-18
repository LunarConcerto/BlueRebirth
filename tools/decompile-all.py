#!/usr/bin/env python3
"""Batch-decompile all normalized JP Lua bytecode with unluac."""
import os
import subprocess
import sys

root = r"E:\逆向工程\苍蓝誓约项目"
src = os.path.join(root, "runtime", "lua-normalized")
dst = os.path.join(root, "lua_tools", "BlueoathLuaJP")
unluac = r"C:\Users\LUNARC~1\AppData\Local\Temp\opencode\unluac.jar"

ok = fail = 0
for dirpath, _, names in os.walk(src):
    for n in names:
        if not n.endswith(".lua"):
            continue
        sp = os.path.join(dirpath, n)
        rel = os.path.relpath(sp, src)
        dp = os.path.join(dst, rel)
        os.makedirs(os.path.dirname(dp), exist_ok=True)
        if os.path.exists(dp) or os.path.exists(dp + ".err"):
            ok += 1
            continue
        try:
            r = subprocess.run(
                ["java", "-jar", unluac, sp],
                capture_output=True, timeout=60,
            )
            out = r.stdout
            if r.returncode != 0 or not out.strip():
                fail += 1
                with open(dp + ".err", "wb") as f:
                    f.write(r.stderr)
                continue
            # write decompiled source (strip trailing newline, add one)
            with open(dp, "wb") as f:
                f.write(out.rstrip(b"\r\n") + b"\n")
            ok += 1
        except Exception as e:
            fail += 1
            with open(dp + ".err", "wb") as f:
                f.write(str(e).encode())
    if ok + fail and (ok + fail) % 200 == 0:
        print(f"progress: ok={ok} fail={fail}", flush=True)

print(f"DONE: ok={ok} fail={fail} -> {dst}")
