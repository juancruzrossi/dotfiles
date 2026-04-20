---
level: base
flag: --base
description: "Lightweight review for small or low-impact PRs"
finding-agents: [code-reviewer, silent-failure-hunter, security-expert]
max-findings-per-agent: 3
triage-strategy: default
judge-strictness: lenient
output-detail: summary
---

## Judge context — base level

Apply lenient criteria. The goal is speed with a minimum quality floor.

**Verdict criteria:**
- Only triage CONCERN_LEVEL: HIGH should influence the verdict.
- If triage has any reasonable doubt (CONCERN_LEVEL: MEDIUM or HIGH): prefer DISMISS.
- DOWNGRADE only when the issue is clearly real but the severity is obviously exaggerated.

**GITHUB_COMMENT format for this level:**
One sentence describing the problem + one sentence with the fix. No mandatory code snippet.
3 sentences total max. Direct and concise tone.

**DISMISS threshold:** aggressive — when in doubt, dismiss. Better a false negative than unnecessary noise in a small PR.
