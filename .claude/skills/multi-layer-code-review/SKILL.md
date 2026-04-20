---
name: multi-layer-code-review
description: |
  Multi-layer PR review pipeline (Finding → Triage → Judge) that reduces false positives via
  adversarial validation. Use when reviewing a PR (URL, branch, or uncommitted changes),
  before opening a PR, or publishing inline GitHub comments.
  Triggers: "review PR", "multi-layer review", "pre-PR check", "review my changes".
keep-coding-instructions: true
argument-hint: "[PR-URL] [--base|--medium|--deep] [--cli|--manual]"
---

# Multi-Layer Code Review

Adversarial PR review pipeline designed to reduce false positives.
Three stages: **Finding** (multiple parallel agents detect issues) → **Triage** (adversarial agent attacks each finding) → **Judge** (neutral arbiter decides VALID | DOWNGRADE | DISMISS).

**Arguments received:** "$ARGUMENTS"

Each agent declares its `model` in its own frontmatter (`sonnet` by default).

---

## Stage 0 — Initialization

### 0.1 Detect review target

Parse `$ARGUMENTS`:
- If it contains a URL `https://github.com/.../pull/N` → **remote PR mode**: `gh pr view N --repo ... --json headRefName,baseRefName` + `git fetch origin <headRef>` and use `git diff origin/<base>...FETCH_HEAD`.
- Otherwise → **local mode**: `git diff HEAD` (uncommitted changes) or `git diff <base-branch>...HEAD` if the current branch differs from base.

Save the full diff to `/tmp/mcr-diff-<timestamp>.txt` so finding agents can read it (avoids inflating prompts).

### 0.2 Detect review level

Parse `$ARGUMENTS` for `--base`, `--medium`, or `--deep`.

If not specified: run `scripts/pr-auto-level.md` on the diff, show the recommendation, and confirm with the user before continuing.

Once confirmed, read `levels/[level].md` to obtain:
- `finding-agents`: list or "all"
- `max-findings-per-agent`
- `output-detail`: summary | standard | full
- File body: LEVEL_CONTEXT for the judge (includes strictness criteria)

### 0.3 Detect output mode

Parse `--cli` or `--manual`. Default: `--cli`. Load `outputs/[mode].md` for Stage 4.

### 0.4 Detect agent filter

If `$ARGUMENTS` contains `code`, `errors`, `tests`, `types`, or `comments`: filter to only the corresponding agent (code-reviewer, silent-failure-hunter, pr-test-analyzer, type-design-analyzer, comment-analyzer).

### 0.5 Gather PROJECT_CONTEXT

Run `scripts/context-gatherer.md`. Save the `PROJECT_CONTEXT:` block to pass to every subsequent stage. If no sources available → `PROJECT_CONTEXT: NONE`.

### 0.6 Determine applicable finding agents

For each agent in `stages/finding/`:
1. Read frontmatter (`when`, `description`).
2. `when: always` → include.
3. `when: test-files-changed` → only if diff contains test files.
4. `when: error-handling-changed` → only if diff touches try/catch/throw.
5. `when: types-added` → only if it introduces new types/DTOs.
6. `when: docs-changed` → only if it modifies `*.md`/docs or comments (exclude pre-implementation design docs — see `comment-analyzer.md`).
7. Apply filter from 0.4 if present.

If `finding-agents: all` → include all applicable. If list → intersect with applicable.

Announce: `"Stage 1 — Starting [LEVEL] review with [N] agents: [list]"`.

---

## Stage 1 — Finding Agents (parallel)

Launch all applicable agents in **a single batch of parallel Task tools**. Each agent:

- Launched with `subagent_type: general-purpose` and the `model` from its frontmatter.
- Receives as prompt: the body of its `.md` + FINDING format instructions + PROJECT_CONTEXT.
- Receives the path `/tmp/mcr-diff-<timestamp>.txt` and is instructed to read it with `Read`.
- Must respect `max-findings-per-agent` from the active level.

**Mandatory format per finding (no prose outside the block):**

```
FINDING:
  AGENT: [agent name]
  SEVERITY: CRITICAL|HIGH|MEDIUM|LOW
  LOCATION: [file:line]
  TITLE: [one-line summary]
  DESCRIPTION: |
    [detailed explanation]
  FIX_SUGGESTION: |
    [concrete fix with code snippet when applicable]
---END_FINDING---
```

No valid findings → exact output: `NO_FINDINGS`.

**Note:** do not request `FINDING_ID` from the agent. It is assigned globally after consolidation.

When all complete, collect `FINDING:` blocks and assign `FINDING_ID: F-01, F-02, ...` sequentially.

If all agents return `NO_FINDINGS` → show `"No issues found. Code passes all checks at [LEVEL] level."` and terminate.

---

## Stage 2 — Triage (one agent per finding, parallel)

For **each** finding, launch an independent triage Task. This preserves adversarial depth: each finding gets a fresh skeptic with no cross-finding contamination.

If there are more than 5 findings: launch in concurrent batches of 4 Task tools at a time to avoid overload. Within a batch, Tasks run in parallel; batches run sequentially.

Each triage Task:
- Launched with `subagent_type: general-purpose` and the `model` from the strategy file's frontmatter.
- Base prompt: the body of `stages/triage/default.md`.
- The FINDING block being evaluated.
- The list of ALL finding titles from this run (for cross-run duplicate detection).
- PROJECT_CONTEXT.

The triage agent does **not** have access to source code. It attacks the finding purely on the text of the report.

Collect all TRIAGE_REPORT blocks indexed by FINDING_ID.

---

## Stage 3 — Judge (one agent per finding, parallel)

For **each** (FINDING, TRIAGE_REPORT) pair, launch an independent judge Task. The judge is a neutral arbiter — it must not have orchestrator context that could bias the verdict.

Same batching rule as Stage 2: concurrent batches of 4 Task tools, sequential batches.

Each judge Task:
- Launched with `subagent_type: general-purpose` and the `model` from the strategy file's frontmatter.
- Base prompt: the body of `stages/judge/default.md`.
- LEVEL_CONTEXT: the body of `levels/[level].md`.
- PROJECT_CONTEXT.
- INPUT 1: the FINDING block.
- INPUT 2: the corresponding TRIAGE_REPORT block.

**Decision rules** (enforced by `stages/judge/default.md`):
- When in doubt between VALID and DOWNGRADE → prefer VALID.
- When in doubt between DOWNGRADE and DISMISS → prefer DOWNGRADE.
- Never DISMISS a CRITICAL finding solely for low activation probability.
- If triage marked DUPLICATE=true → DISMISS the current, keep the original.

Collect all JUDGE_VERDICT blocks indexed by FINDING_ID.

---

## Stage 4 — Output

Classify verdicts:
- **Action required**: VALID or DOWNGRADE with ACTION_REQUIRED=true.
- **Informational**: DOWNGRADE with ACTION_REQUIRED=false.
- **Dismissed**: DISMISS.

Sort by FINAL_SEVERITY: CRITICAL → HIGH → MEDIUM → LOW.

Load `outputs/[mode].md` and follow its instructions with the JUDGE_VERDICTs, original FINDING blocks, and active level.

---

## Anti-duplication (key principle)

Finding agents have overlapping scopes (code-reviewer ↔ silent-failure-hunter ↔ security-expert ↔ type-design-analyzer). To minimize duplicates:

1. **Each agent** reads its `SCOPE` section (when present) and avoids overlapping territories.
2. **Triage** explicitly marks duplicates with DUPLICATE=true + original FINDING_ID.
3. **Judge** dismisses duplicates (DISMISS with rationale "Duplicate of F-XX").

Typically 20–30% of findings in a large PR are cross-agent duplicates; the pipeline filters them.

---

## Extensibility

| Item | Location | Format |
|------|----------|--------|
| Finding agent | `stages/finding/` | `.md` with frontmatter `type`, `when`, `description` + prompt body |
| Triage strategy | `stages/triage/` | `.md` with full triage agent prompt |
| Judge strategy | `stages/judge/` | `.md` with full judge agent prompt |
| Output mode | `outputs/` | `.md` with frontmatter `flag` + instructions |
| Level | `levels/` | `.md` with config frontmatter + LEVEL_CONTEXT body |
| Utility script | `scripts/` | `.md` with instructions |
