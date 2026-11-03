"""Carry an existing project's custom token config across the kumiko filename change."""

from pathlib import Path
from sys import argv

project = Path(argv[1])
default = Path(argv[2]).read_bytes()
old = project / "tokens.config.mjs"
new = project / "kumiko.config.mjs"

if old.exists():
    if new.exists() and new.read_bytes() != default:
        raise SystemExit(f"Both {old} and {new} exist; reconcile them before updating the stack")
    old.replace(new)
