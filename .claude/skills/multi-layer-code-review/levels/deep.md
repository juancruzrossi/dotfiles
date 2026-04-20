---
level: deep
flag: --deep
description: "Exhaustive review for critical high-impact PRs"
finding-agents: all
max-findings-per-agent: unlimited
triage-strategy: default
judge-strictness: strict
output-detail: full
---

## Judge context — deep level

Apply strict criteria. Exhaustiveness takes priority over speed.

**Verdict criteria:**
- Any CONCERN_LEVEL >= LOW from triage requires explicit analysis.
- DISMISS only with concrete, irrefutable evidence of a false positive.
- DOWNGRADE: document explicitly why severity is reduced.
- For CRITICAL findings: NEVER dismiss solely for low activation probability.

**For CRITICAL findings at this level:**
Include in GITHUB_COMMENT:
1. Full issue description and how it manifests.
2. Blast radius analysis: which systems, data, or users are affected.
3. Concrete exploitation scenario (if applicable).
4. Proposed fix with code snippet (mandatory).
5. Suggested verification: how to confirm the fix resolves the issue.

**GITHUB_COMMENT format for this level:**
Full description (2-3 sentences) + impact context (1-2 sentences) + solution (1-2 sentences) + fix code snippet (mandatory). No length limit.

**DISMISS threshold:** conservative — only with concrete evidence. In doubt, emit VALID or DOWNGRADE with an uncertainty note in RATIONALE.
