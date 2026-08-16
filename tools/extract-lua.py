#!/usr/bin/env python3
"""Extract Lua TextAssets from the game's AssetBundles.

Requires: pip install UnityPy

Reads StreamingAssets/bundles/share/lua/* and writes the Lua scripts
(assets/generatedfiles/lua/32bit/...) to runtime/lua-extract/ preserving their
logical paths. The scripts are compiled Lua 5.3-variant bytecode, not plaintext.
"""
import os
import sys

import UnityPy


def main() -> int:
    root = os.environ.get("BLUEOATH_ROOT", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    base = os.path.join(root, "blueoath", "blueoath", "blueoath_Data", "StreamingAssets", "bundles", "share", "lua")
    out = os.path.join(root, "runtime", "lua-extract")
    if not os.path.isdir(base):
        print(f"Lua bundle directory not found: {base}", file=sys.stderr)
        return 2

    os.makedirs(out, exist_ok=True)
    prefix = "assets/generatedfiles/lua/32bit/"
    total = 0
    for fn in sorted(os.listdir(base)):
        p = os.path.join(base, fn)
        if not os.path.isfile(p) or fn.endswith(".manifest"):
            continue
        try:
            env = UnityPy.load(p)
        except Exception as e:
            print(f"[skip] {fn}: {e}")
            continue
        count = 0
        for path, obj in env.container.items():
            if obj.type.name != "TextAsset":
                continue
            ta = obj.read()
            logical = path
            if logical.startswith(prefix):
                logical = logical[len(prefix):]
            if logical.endswith(".bytes"):
                logical = logical[:-len(".bytes")]
            if not logical.endswith(".lua"):
                logical += ".lua"
            dest = os.path.join(out, logical.replace("/", os.sep))
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "w", encoding="utf-8", errors="ignore") as f:
                f.write(ta.m_Script)
            count += 1
        total += count
        print(f"{fn}: {count}")
    print(f"TOTAL: {total} lua files -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
