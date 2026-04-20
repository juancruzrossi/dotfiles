---
flag: --manual
description: "Interactive CLI: shows each finding and asks whether to publish it on GitHub. User controls what is published."
required-skills: [github-publisher]
---

## Output Instructions — Manual Mode

Process each VALID/DOWNGRADE finding one by one, showing the generated comment and asking the user whether to publish it on GitHub.

### For each finding (in severity order: CRITICAL → HIGH → MEDIUM → LOW)

Show:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[F-NN] [FINAL_SEVERITY] — [TITLE]
File: [LOCATION]
Agent: [FINDING_AGENT]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GitHub comment:
─────────────────────────────────────────────────────
[GITHUB_COMMENT with [CODE_FIX_HERE] replaced by the FIX_SUGGESTION snippet]
─────────────────────────────────────────────────────
Publish on GitHub? [y=yes / n=no / e=edit / r=view rationale]: _
```

### Response handling

**y (publish):**
Invoke `scripts/github-publisher.md` with the GITHUB_COMMENT and LOCATION (file:line) of the finding.
Show: "Published: [comment URL]" or "Error: [message]".

**n (skip):**
Show: "Skipped — F-NN" and continue with the next finding.

**e (edit):**
Show the comment line by line. Ask the user for the edited comment.
Example:
```
Current comment:
> [GITHUB_COMMENT]

Enter the edited comment (double Enter to finish):
```
After editing, publish the modified comment via `scripts/github-publisher.md`.

**r (view rationale):**
Show the full judge RATIONALE for this finding:
```
Judge rationale:
[RATIONALE]
```
Then re-prompt [y/n/e/r].

### [CODE_FIX_HERE] replacement

Before showing the GITHUB_COMMENT, replace the `[CODE_FIX_HERE]` placeholder with the FIX_SUGGESTION from the original FINDING formatted as code:
```
[FIX_SUGGESTION contents]
```
If FIX_SUGGESTION contains no concrete code: remove the placeholder and keep only the text.

### Final summary

After processing all findings, show:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Review session complete
  Published: N comments
  Skipped: N findings
  Dismissed by pipeline: N false positives
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
