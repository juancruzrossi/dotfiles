---
level: medium
flag: --medium
description: "Standard review for regular use, balanced quality/speed"
finding-agents: [code-reviewer, silent-failure-hunter, pr-test-analyzer, security-expert]
max-findings-per-agent: 5
triage-strategy: default
judge-strictness: standard
output-detail: standard
---

## Judge context — medium level

Apply standard criteria. Balance precision and coverage.

**Verdict criteria:**
- Triage CONCERN_LEVEL: MEDIUM or HIGH influences the verdict.
- DISMISS requires a specific, articulable prerequisite gap or compensating control.
- DOWNGRADE when triage evidence is solid but not conclusive.

**GITHUB_COMMENT format for this level:**
Clear issue description (1-2 sentences) + proposed solution (1-2 sentences) + fix code snippet if the finding agent provided one. Max 6 sentences + snippet. Professional, constructive tone.

**DISMISS threshold:** standard — requires concrete evidence of a false positive, not just triage speculation.
