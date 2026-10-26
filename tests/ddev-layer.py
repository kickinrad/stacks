#!/usr/bin/env python3
"""Render the reusable DDEV parts through a temporary Copier stack without Docker."""

import json
import os
import shutil
import subprocess
import tempfile
import tomllib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def include(path: str, prefix: str = "") -> str:
    return prefix + '{% include "_shared/' + path + '" %}'


with tempfile.TemporaryDirectory(prefix="stacks-ddev-") as temporary:
    work = Path(temporary)
    template = work / "template"
    project = work / "project"
    shutil.copytree(ROOT, template, ignore=shutil.ignore_patterns(".git"))

    copier = template / "copier.yml"
    choices = copier.read_text()
    assert "    A uv + Python package or tool: python\n" in choices
    copier.write_text(choices.replace(
        "    A uv + Python package or tool: python\n",
        "    A uv + Python package or tool: python\n    DDEV layer fixture: ddev-fixture\n",
    ))

    fixture = template / "ddev-fixture"
    fixture.mkdir()
    for source in (template / "python").rglob("*.jinja"):
        relative = source.relative_to(template / "python")
        if relative.parts[0] in {"src", "tests"} or relative.name == "pyproject.toml.jinja":
            continue
        destination = fixture / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
    (fixture / ".agents/project.toml.jinja").write_text(include(
        "base/project.toml.partial", '{% set mise_tools = [] %}{% set package_manager = "" %}',
    ))
    (fixture / ".agents/stack/STACK.md.jinja").write_text(
        include("base/STACK.md.partial") + include("ddev/STACK.md.partial"),
    )
    (fixture / ".config/mise/conf.d/stack.toml.jinja").write_text(include("ddev/stack.toml.partial"))
    (fixture / ".gitignore.jinja").write_text(include("base/gitignore.partial") + include("ddev/gitignore.partial"))
    (fixture / ".ddev").mkdir()
    (fixture / ".ddev/config.yaml.jinja").write_text(include("ddev/config.yaml.partial"))
    (fixture / "composer.json.jinja").write_text(include("ddev/composer.json.partial"))
    (fixture / ".php-cs-fixer.dist.php.jinja").write_text(include("ddev/php-cs-fixer.dist.php.partial"))
    (fixture / "phpstan.neon.jinja").write_text(include("ddev/phpstan.neon.partial"))
    (fixture / "web").mkdir()
    (fixture / "web/index.php.jinja").write_text("<?php\n\necho 'DDEV fixture';\n")
    (fixture / "src").mkdir()
    (fixture / "src/Example.php.jinja").write_text("<?php\n\nfinal class Example {}\n")
    (fixture / "tests").mkdir()
    (fixture / "tests/ExampleTest.php.jinja").write_text("<?php\n\nit('works', fn () => expect(true)->toBeTrue());\n")

    subprocess.run([
        "copier", "copy", "--quiet", "--defaults", "--trust", "--skip-tasks",
        "--data", "stack=ddev-fixture", "--data", "project_name=ddev-fixture",
        str(template), str(project),
    ], check=True)
    subprocess.run(["python3", ".agents/stack/check", "--structure"], cwd=project, check=True)
    if project_setup := os.environ.get("PROJECT_SETUP"):
        subprocess.run(["python3", project_setup, str(project), "--mode", "verify", "--format", "human"], check=True)
    subprocess.run(["php", "-l", str(project / ".php-cs-fixer.dist.php")], check=True, capture_output=True)

    tasks = tomllib.loads((project / ".config/mise/conf.d/stack.toml").read_text())["tasks"]
    assert {"setup", "check", "test", "fix", "dev"} <= tasks.keys()
    assert tasks["setup"]["run"] == ["ddev start", "ddev composer install"]
    assert all(command.startswith("ddev ") for name in ("check", "test") for command in
               (tasks[name]["run"] if isinstance(tasks[name]["run"], list) else [tasks[name]["run"]]))
    assert (project / ".ddev/config.yaml").read_text().find("type: php\ndocroot: web") != -1
    packages = json.loads((project / "composer.json").read_text())["require-dev"]
    assert {"phpstan/phpstan", "friendsofphp/php-cs-fixer", "pestphp/pest"} <= packages.keys()
    assert "'@PER-CS' => true" in (project / ".php-cs-fixer.dist.php").read_text()
    assert "## PHP with DDEV" in (project / ".agents/stack/STACK.md").read_text()
    print("ddev layer render: PASS (offline fixture; Docker runtime not exercised)")
