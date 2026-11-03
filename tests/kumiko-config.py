"""The filename migration keeps an existing project's config and refuses ambiguity."""

import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
script = root / "_tasks/migrate_kumiko_config.py"
default = root / "_shared/astro/kumiko.config.mjs.partial"

with tempfile.TemporaryDirectory() as directory:
    project = Path(directory)
    old = project / "tokens.config.mjs"
    new = project / "kumiko.config.mjs"
    old.write_text('export default { targets: ["custom"] };\n')
    new.write_bytes(default.read_bytes())
    subprocess.run(["python3", script, project, default], check=True)
    assert not old.exists()
    assert new.read_text() == 'export default { targets: ["custom"] };\n'

with tempfile.TemporaryDirectory() as directory:
    project = Path(directory)
    old = project / "tokens.config.mjs"
    new = project / "kumiko.config.mjs"
    old.write_text("old custom")
    new.write_text("new custom")
    result = subprocess.run(["python3", script, project, default], capture_output=True, text=True)
    assert result.returncode != 0
    assert "reconcile" in result.stderr
    assert old.read_text() == "old custom"
    assert new.read_text() == "new custom"

print("kumiko config migration: PASS")
