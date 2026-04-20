---
name: symlink
description: Link a skill from ~/.agents/skills/ to any agent's skills directory via symlink. Use when installing, linking, or wiring a skill for one or more agents. Do not use for unlinking, deleting, or managing skill content.
---

# Symlink — Skill Linker

## Usage

```
/symlink <skill-name> [agent-1 agent-2 ...]
```

## Steps

1. **Verify source** — Confirm `~/.agents/skills/<name>/SKILL.md` exists.
   - **If missing**, check agent skill directories (`~/.claude/skills/<name>`, `~/.codex/skills/<name>`, etc.) for a non-symlinked copy.
     - **If found in an agent dir**: move it to `~/.agents/skills/<name>/` (`mv`), then remove any stale symlink or directory left behind at the original location.
     - **If not found anywhere**: ask the user for the source path or whether to create the skill first.

2. **Resolve targets** — For each agent name provided, locate `~/.<agent>/skills/`. If the directory does not exist, ask the user for the correct path. If no agents are provided, default to **all known agent directories** (`~/.claude/skills/`, `~/.codex/skills/`, and any others that exist under `~/.*agent*/skills/`).

3. **Create symlinks** — For each target agent, compute the relative path **from the target directory** to the source using `realpath --relative-to` or manual calculation, then run:
   ```bash
   ln -s "$(realpath --relative-to="$HOME/.<agent>/skills" "$HOME/.agents/skills/<name>")" ~/.<agent>/skills/<name>
   ```
   For example, from `~/.claude/skills/` the relative path to `~/.agents/skills/<name>` is always `../../.agents/skills/<name>` (2 levels up from `~/.claude/skills/`, NOT 3).
   If `realpath --relative-to` is not available (macOS), use Python: `python3 -c "import os; print(os.path.relpath('$HOME/.agents/skills/<name>', '$HOME/.<agent>/skills'))"`.
   If a file, directory, or symlink already exists at the target, report it and ask before overwriting.

4. **Verify** — Run `ls -la` on each created symlink. Read the SKILL.md through one of them to confirm correct resolution.

5. **Report** — Display final state:
   ```
   ~/.agents/skills/<name>/SKILL.md   ← source
   ~/.<agent-1>/skills/<name>          ← symlink ✓
   ~/.<agent-2>/skills/<name>          ← symlink ✓
   ```

Repeat steps 1–5 for each skill name when multiple are provided.
