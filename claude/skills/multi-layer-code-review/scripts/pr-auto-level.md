# Script: PR Auto-Level Detector

Analyzes the diff and suggests the review level (base, medium, deep). Invoked from Stage 0.2 of `SKILL.md` when the user does not specify a level.

## Instructions

### 1. Determine the diff to analyze

**Remote PR mode** (SKILL.md detected a URL in arguments):
```bash
# `git fetch origin <headRef>` already ran in Stage 0.1.
BASE_BRANCH=$(gh pr view <N> --repo <repo> --json baseRefName -q .baseRefName)
DIFF_REF="origin/${BASE_BRANCH}...FETCH_HEAD"
```

**Local mode** (no URL):
```bash
# Uncommitted changes:
DIFF_REF="HEAD"
# Or if the current branch differs from develop/main:
# DIFF_REF="origin/develop...HEAD"
```

### 2. Collect stats

```bash
total_lines=$(git diff ${DIFF_REF} --stat 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
total_lines=${total_lines:-0}

files_changed=$(git diff ${DIFF_REF} --name-only 2>/dev/null | wc -l | tr -d ' ')

critical_files=$(git diff ${DIFF_REF} --name-only 2>/dev/null | grep -cE '(auth|security|payment|infra|migration|database|config|secrets|credential|iam|policy)' || echo 0)

echo "Lines: $total_lines | Files: $files_changed | Critical: $critical_files"
```

### 3. Determine recommended level

| Condition | Level |
|-----------|-------|
| `critical_files >= 1` | **deep** (touches critical areas) |
| `total_lines > 500` OR `files_changed > 20` | **deep** (large PR) |
| `100 <= total_lines <= 500` no critical files | **medium** |
| `5 <= files_changed <= 20` no critical files | **medium** |
| `total_lines < 100` AND `files_changed < 5` | **base** |
| Only tests/docs changes | **base** |

### 4. Output

```
AUTO_LEVEL_RECOMMENDATION:
  recommended: base|medium|deep
  reason: "[1 sentence]"
  stats:
    total_lines: [N]
    files_changed: [N]
    critical_files: [N]
```

Ask the user: `"Detected level: **[level]** ([reason]). Continue? [Enter=yes / type another level]"`.

If they type a different level → use that. No response → use the recommended one.
