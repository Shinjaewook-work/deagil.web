#!/usr/bin/env python3
"""Small, dependency-free audit for the Master contract's hard invariants."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
master = (ROOT / "LUNA_IMPLEMENTATION_MASTER.md").read_text(encoding="utf-8")
errors = []

required = (
    "3/3이어도 Rewarded Ad를 막지 않는다",
    "AD_SECURITY_MODE = fast | reward_gated | ssv_strict",
    "Client-callable `start-fortune-generation` endpoint는 만들지 않는다",
    "MockFortuneProvider",
    "available + reserved <= 3",
    "No `unlock_status`",
)
for phrase in required:
    if phrase not in master:
        errors.append(f"missing Master invariant: {phrase}")

for path in (ROOT / "lib", ROOT / "supabase"):
    if not path.exists():
        continue
    for source in path.rglob("*"):
        if source.is_file() and "unlock_status" in source.read_text(
            encoding="utf-8", errors="ignore"
        ):
            errors.append(f"forbidden unlock_status reference: {source.relative_to(ROOT)}")

if errors:
    for error in errors:
        print(f"ERROR: {error}")
    print(f"FAIL: {len(errors)} errors")
    sys.exit(1)

print("PASS: Master contract invariants present")
