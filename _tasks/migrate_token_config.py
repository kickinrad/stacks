"""Carry an existing project's custom token config across the engine's filename changes: tokens.config.mjs (the
tokens tool) and kumiko.config.mjs (kumiko) both become breacan.config.mjs."""

from pathlib import Path
from sys import argv

project = Path(argv[1])
default = Path(argv[2]).read_bytes()
new = project / "breacan.config.mjs"
olds = [path for path in (project / "tokens.config.mjs", project / "kumiko.config.mjs") if path.exists()]

if len(olds) > 1:
    raise SystemExit(f"Both {olds[0]} and {olds[1]} exist; reconcile them before updating the stack")
if olds:
    if new.exists() and new.read_bytes() != default:
        raise SystemExit(f"Both {olds[0]} and {new} exist; reconcile them before updating the stack")
    olds[0].replace(new)
