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

1. **Verify source** — Confirm `~/.agents/skills/<name>/SKILL.md` exists. If missing, ask the user for the source path or whether to create the skill first.

2. **Resolve targets** — For each agent name provided, locate `~/.<agent>/skills/`. If the directory does not exist, ask the user for the correct path. If no agents are provided, ask which agents to target.

3. **Create symlinks** — For each target agent, run:
   ```bash
   ln -s <relative-path-to-source> ~/.<agent>/skills/<name>
   ```
   Use relative paths. If a file, directory, or symlink already exists at the target, report it and ask before overwriting.

4. **Verify** — Run `ls -la` on each created symlink. Read the SKILL.md through one of them to confirm correct resolution.

5. **Report** — Display final state:
   ```
   ~/.agents/skills/<name>/SKILL.md   ← source
   ~/.<agent-1>/skills/<name>          ← symlink ✓
   ~/.<agent-2>/skills/<name>          ← symlink ✓
   ```

Repeat steps 1–5 for each skill name when multiple are provided.
