"""Add the stack's MCP servers to .mcp.json and .codex/config.toml when missing.

Never changes or removes a server the project already defines, so a project's own
tuning (auth helpers, extra servers) survives every copier copy and update.
Usage: python3 ensure_mcp.py <project> name=url [name=url ...]
"""

import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
servers = dict(arg.split("=", 1) for arg in sys.argv[2:])

claude = root / ".mcp.json"
data = json.loads(claude.read_text()) if claude.is_file() else {}
entries = data.setdefault("mcpServers", {})
added = [name for name in servers if name not in entries]
for name in added:
    entries[name] = {"type": "http", "url": servers[name]}
if added or not claude.is_file():
    claude.write_text(json.dumps(data, indent=2) + "\n")

codex = root / ".codex" / "config.toml"
text = codex.read_text() if codex.is_file() else ""
blocks = [f'[mcp_servers.{name}]\nurl = "{url}"\n' for name, url in servers.items()
          if not re.search(rf"^\[mcp_servers\.{re.escape(name)}\]", text, re.M)]
if blocks:
    codex.parent.mkdir(exist_ok=True)
    codex.write_text(text + ("\n" if text and not text.endswith("\n\n") else "") + "\n".join(blocks))
