"""The filename migration keeps an existing project's config and refuses ambiguity."""

import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
script = root / "_tasks/migrate_token_config.py"
default = root / "_shared/astro/breacan.config.mjs.partial"

for name in ("tokens.config.mjs", "kumiko.config.mjs"):
    with tempfile.TemporaryDirectory() as directory:
        project = Path(directory)
        old = project / name
        new = project / "breacan.config.mjs"
        old.write_text('export default { modules: ["custom"] };\n')
        new.write_bytes(default.read_bytes())
        subprocess.run(["python3", script, project, default], check=True)
        assert not old.exists(), name
        assert new.read_text() == 'export default { modules: ["custom"] };\n', name

    with tempfile.TemporaryDirectory() as directory:
        project = Path(directory)
        old = project / name
        new = project / "breacan.config.mjs"
        old.write_text("old custom")
        new.write_text("new custom")
        result = subprocess.run(["python3", script, project, default], capture_output=True, text=True)
        assert result.returncode != 0, name
        assert "reconcile" in result.stderr, name
        assert old.read_text() == "old custom" and new.read_text() == "new custom", name

with tempfile.TemporaryDirectory() as directory:
    project = Path(directory)
    (project / "tokens.config.mjs").write_text("a")
    (project / "kumiko.config.mjs").write_text("b")
    result = subprocess.run(["python3", script, project, default], capture_output=True, text=True)
    assert result.returncode != 0 and "reconcile" in result.stderr

print("token config migration: PASS")
