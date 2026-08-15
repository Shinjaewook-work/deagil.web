#!/usr/bin/env python3
"""Snapshot/compare the protected harness files around generators."""

from hashlib import sha256
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT = ROOT / ".harness_hashes.json"
PROTECTED = ("AGENTS.md", "LUNA_IMPLEMENTATION_MASTER.md", "docs", "scripts")


def files():
    paths = []
    for entry in PROTECTED:
        path = ROOT / entry
        if path.is_file():
            paths.append(path)
        elif path.is_dir():
            paths.extend(p for p in path.rglob("*") if p.is_file())
    return sorted(paths)


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def main(command):
    current = {str(path.relative_to(ROOT)): digest(path) for path in files()}
    if command == "snapshot":
        SNAPSHOT.write_text(json.dumps(current, indent=2) + "\n", encoding="utf-8")
        print(f"SNAPSHOT: {len(current)} files")
        return 0
    if command == "compare":
        if not SNAPSHOT.exists():
            print("ERROR: snapshot missing; run snapshot first")
            return 1
        expected = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
        if current != expected:
            print("ERROR: protected harness changed")
            return 1
        print(f"PASS: {len(current)} protected files unchanged")
        return 0
    if command == "clear":
        if SNAPSHOT.exists():
            SNAPSHOT.unlink()
        print("CLEARED")
        return 0
    print("usage: harness_hashes.py snapshot|compare|clear")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) == 2 else ""))
