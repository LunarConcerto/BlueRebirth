#!/usr/bin/env python3
"""Static analysis helpers for the extracted Lua bytecode.

The Lua files are compiled Lua 5.3-variant bytecode; string constants (class names,
method names, local variable names, JSON field names) remain readable. This script
extracts printable strings and reports which files match the given keywords.

Usage:
  python tools/lua-strings.py <keyword...>
"""
import os
import sys


def strings(data: bytes):
    out, cur = [], []
    for b in data:
        if 0x20 <= b < 0x7F:
            cur.append(chr(b))
        else:
            if len(cur) >= 3:
                out.append("".join(cur))
            cur = []
    if len(cur) >= 3:
        out.append("".join(cur))
    return out


def main() -> int:
    root = os.environ.get("BLUEOATH_ROOT", os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    extract = os.path.join(root, "runtime", "lua-extract")
    if not os.path.isdir(extract):
        print(f"Extracted Lua not found: {extract} (run tools/extract-lua.py first)", file=sys.stderr)
        return 2

    terms = sys.argv[1:]
    if not terms:
        print(__doc__, file=sys.stderr)
        return 2

    files = []
    for dirpath, _, names in os.walk(extract):
        for n in names:
            if n.endswith(".lua"):
                files.append(os.path.join(dirpath, n))

    for term in terms:
        print(f"===== TERM: {term} =====")
        for fp in files:
            with open(fp, "rb") as f:
                ss = strings(f.read())
            hits = [s for s in ss if term.lower() in s.lower()]
            if not hits:
                continue
            rel = os.path.relpath(fp, extract)
            seen, uniq = set(), []
            for s in hits:
                if s not in seen:
                    seen.add(s)
                    uniq.append(s)
            print(f"{rel}:")
            for s in uniq[:15]:
                print(f"    {s!r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
