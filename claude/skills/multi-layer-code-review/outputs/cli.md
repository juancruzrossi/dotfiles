---
flag: --cli
description: "Renders the full review report in the terminal. Does not publish anything to GitHub."
required-skills: []
---

## Output Instructions — CLI Mode

Generate the final report in the terminal with all validated findings.
Format varies by the `output-detail` of the active level.

### For output-detail: summary (base level)

```markdown
# PR Review — Report [base]

## Summary
| ID | Severity | File | Title |
|----|----------|------|-------|
| F-01 | HIGH | app/repo.py:42 | SQL injection in user_query |
| F-03 | MEDIUM | app/service.py:15 | Missing error handling |

Findings analyzed: N | False positives dismissed: N | Action required: N
```

### For output-detail: standard (medium level)

```markdown
# PR Review — Report [medium]

## Findings Requiring Action

### HIGH — F-01: SQL injection in user_query
**File:** `app/repo.py:42`
**Agent:** code-reviewer

[GITHUB_COMMENT from JUDGE_VERDICT]

---

### MEDIUM — F-03: Missing error handling
...

## Dismissed (false positives)
- F-02: Race condition in cache — DISMISS: compensating control (Redis TTL lock)
- F-04: XSS in admin panel — DISMISS: endpoint requires ADMIN role (prerequisite gap)

Findings analyzed: N | Dismissed: N | Action required: N
```

### For output-detail: full (deep level)

Additionally include:
- Full judge RATIONALE for each VALID/DOWNGRADE finding.
- Fix code snippet (replace [CODE_FIX_HERE] with the finding's FIX_SUGGESTION).
- For CRITICAL: blast radius analysis from GITHUB_COMMENT.
- Detailed dismissed section with triage reasoning.

```markdown
# PR Review — Report [deep]

## CRITICAL

### F-01: [TITLE]
**File:** `file:line` | **Agent:** [agent]
**Judge verdict:** VALID — [RATIONALE]

[Full GITHUB_COMMENT with code snippet]

---
```

### Report footer

Always end with:
```markdown
---
To publish these comments on GitHub:
- Manual: `/multi-layer-code-review [level] --manual`
```
