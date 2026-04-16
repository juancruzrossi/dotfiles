---
name: deslopify
description: Deslop a codebase — run a comprehensive, parallelized code-quality cleanup using 8 specialized subagents in isolated git worktrees. Each agent owns one dimension (DRY, shared types, dead code, circular deps, weak types, defensive code, legacy/fallback paths, AI slop/comments), does detailed research, writes a critical assessment, and implements all high-confidence recommendations. Use this whenever the user says "deslopify", asks to "clean up the codebase", "improve code quality", "remove AI slop", "refactor for quality", "kill dead code", do a "health audit" or "tech debt cleanup" — and especially when they want multiple quality dimensions addressed together rather than one-by-one. Trigger on any broad code-hygiene request even if the user doesn't explicitly say "parallel" or "subagents".
keep-coding-instructions: true
---

# Deslopify

Coordinate 8 specialized subagents in parallel, each owning one dimension of code quality, each working in an isolated git worktree. After all finish, reconcile the changes into a single branch and open a PR for the user to approve.

This is a high-leverage workflow: it attacks several orthogonal quality dimensions at once instead of serializing them, and it uses worktrees so agents don't step on each other. The tradeoff is that **combining the results takes real judgment** — the reconciliation phase is the hardest part, not an afterthought.

## Canonical Brief

The skill exists to execute this exact request. Everything below derives from it. If anything in this file conflicts with this brief, the brief wins.

> I want to clean up my codebase and improve code quality. This is a complex task, so we'll need 8 subagents. Make a sub agent for each of the following:
>
> 1. **Deduplicate and consolidate all code, and implement DRY where it reduces complexity**
> 2. **Find all type definitions and consolidate any that should be shared**
> 3. **Use tools like knip to find all unused code and remove, ensuring that it's actually not referenced anywhere**
> 4. **Untangle any circular dependencies, using tools like madge**
> 5. **Remove any weak types, for example `unknown` and `any` (and the equivalent in other languages), research what the types should be, research in the codebase and related packages to make sure that the replacements are strong types and there are no type issues**
> 6. **Remove all try-catch and equivalent defensive programming if it doesn't serve a specific role of handling unknown or unsanitized input or otherwise has a reason to be there, with clear error handling and no error hiding or fallback patterns**
> 7. **Find any deprecated, legacy or fallback code, remove, and make sure all code paths are clean, concise and as singular as possible**
> 8. **Find any AI slop, stubs, LARP, unnecessary comments and remove. Any comments that describe in-motion work, replacements of previous work with new work, or otherwise are not helpful should be either removed or replaced with helpful comments for a new user trying to understand the codebase — but if you do edit, be concise**
>
> I want each to do detailed research on their task, write a critical assessment of the current code and recommendations, and then implement all high confidence recommendations.

Three things to notice in the brief and keep at the front of your mind:

- **Detailed research** before any edit.
- **Critical assessment** as a written artifact (use the commit message).
- **Implement only high-confidence recommendations** — leave the rest reported, not changed.

## Workflow

### 1. Confirm scope with the user

Briefly tell the user what you're going to do and how many agents. Proceed on "go" or equivalent. If they want a narrower scope (fewer dimensions, specific folders), respect that and spawn only the relevant agents.

### 2. Spawn all agents in ONE message

All `Agent` tool calls in a single message so they run concurrently. Sequencing them defeats the whole point.

Each agent needs:
- `isolation: "worktree"` — non-negotiable; prevents agents trampling each other
- `run_in_background: true` — frees the main conversation
- `mode: "bypassPermissions"` — agents need to install tools, apply patches, etc. without pausing
- `subagent_type: "general-purpose"` unless a more specific one fits
- `name`: short identifier so you can track which agent returned what

**Embed in every prompt** (this is the heart of the brief):
- Do detailed research on the task before touching anything
- Detect the stack first (Node/TS, Python, Go, Rust, Java/Kotlin, Ruby, .NET, PHP, etc.) by inspecting config files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `*.csproj`, `composer.json`, etc.) and choose the right verification commands
- Write a critical assessment of the current code and recommendations in the commit message
- Implement only HIGH-CONFIDENCE recommendations — report the rest, don't change them
- After changes, run the project's **type-check / static analysis** and **build/compile** commands (see Stack-Aware Tooling below)
- Commit with a conventional-commit message
- Comments in English; user-facing copy stays in its original language

### 3. Wait for completion

You get a notification per agent. Don't poll. Summarize each result to the user as it lands — progress visibility matters for a long-running task.

### 4. Reconcile

The hard part. See **Reconciliation Strategy** below.

### 5. Hand off to the human for review

**Do NOT commit, push, or open a PR.** The output of this skill is a new branch with all reconciled changes in the working tree, uncommitted, ready for the human to review on their own terms.

What to do:
- Leave the target branch checked out
- Leave the combined changes **uncommitted** in the working tree
- Clean up the per-agent worktrees and their branches (see below)
- Print a summary of what each dimension contributed, plus the key files touched
- Tell the human the branch name and that changes are uncommitted. Stop there — don't prescribe commands. The human knows their repo (default branch might be `main`, `master`, `develop`, whatever) and their own workflow.

What NOT to do:
- **No `git commit`** — the human commits.
- **No `git push`** — the human pushes.
- **No `gh pr create`** — the human opens the PR (or not).
- **No `gh pr merge`** — obviously.
- **No unsolicited suggestions** about which commands to run or which branch to diff against. Report the state and stop.

Rationale: a broad quality cleanup touches many files and is easy to get subtly wrong. A human reviewing the uncommitted working tree in their editor catches things that `tsc` + `build` don't, without GitHub noise that needs cleanup if they reject parts.

### 6. Worktree cleanup

Regardless of what the human decides, clean up the scratch worktrees — they're the skill's internal state, not artifacts:

```bash
for wt in .claude/worktrees/agent-*/; do
  git worktree unlock "$wt" 2>/dev/null
  git worktree remove --force "$wt" 2>/dev/null
done
git worktree prune
git branch -D $(git branch | grep worktree-agent-) 2>/dev/null
```

## Stack-Aware Tooling

The skill is stack-agnostic. The main thing each agent must do is **detect the stack** and pick the right tools. Use this table as a starting point, but don't treat it as exhaustive — inspect the repo and pick what makes sense.

| Concern | TS/JS | Python | Go | Rust | Java/Kotlin | Ruby | .NET | PHP |
|---|---|---|---|---|---|---|---|---|
| Type/static check | `tsc --noEmit`, `biome check`, `eslint` | `mypy`, `pyright`, `ruff check` | `go vet`, `staticcheck` | `cargo check`, `clippy` | `./gradlew check`, `mvn verify` | `sorbet tc`, `rubocop` | `dotnet build` with `/warnaserror` | `phpstan`, `psalm` |
| Build/compile | `npm run build` (or `pnpm`, `yarn`, `bun`) | `python -m build`, `poetry build` | `go build ./...` | `cargo build` | `./gradlew build`, `mvn package` | `rake build` | `dotnet build` | `composer validate` |
| Dead code | `knip`, `ts-prune`, `unimported` | `vulture`, `ruff --select F401`, `deadcode` | `deadcode`, `unused` | `cargo-udeps`, `warnings` | IDE warnings, `detekt` unused rules | `debride` | `dotnet format --verify-no-changes` + analyzers | `phpstan` |
| Circular deps | `madge`, `dependency-cruiser` | `pylint cyclic-import`, `pycycle` | `go-cyclo`, compiler rejects most | `cargo-modules` | `jdeps`, `depgraph` | `rubrowser` | analyzers | `phpstan` |
| Install tool | `npm install -D X` | `pip install X` (dev extra), `poetry add --group dev X` | `go install` | `cargo install X` | add to `build.gradle`/`pom.xml` | `gem install` / `Gemfile` dev group | `dotnet add package` | `composer require --dev` |

**How agents should apply this:**
1. Detect the stack (look for `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile`, `*.csproj`, `composer.json`)
2. Check the repo's existing scripts/tasks (`package.json#scripts`, `Makefile`, `justfile`, `tox.ini`, `Taskfile.yml`, CI workflows) — prefer re-using what's already wired
3. Only install new tools when the codebase clearly lacks an equivalent AND the user would benefit long-term (keep as dev dependency)
4. If unsure what to run, read CI config or `README`/`CONTRIBUTING.md` — they usually name the real commands

If a language/stack isn't in the table, apply the same logic: there's always some form of compile/lint/static-analysis available — find it and use it.

## Agent Prompts

Eight prompts below, one per subagent. Each wraps the canonical brief's bullet in an executable template. Keep them long; terse prompts yield shallow cleanup. Substitute `<PROJECT INTRO>` with a paragraph identifying the stack and purpose — agents don't have the parent conversation's context.

Every prompt ends with the same verification step: **run the project's type-check/static-analysis and build commands** (see Stack-Aware Tooling above). The specific commands below are placeholders — the agent chooses the right ones for the detected stack.

### 1. DRY / Deduplication

```
<PROJECT INTRO>

Your task: Deduplicate and consolidate all code, and implement DRY where it reduces complexity.

1. Do detailed research first — explore the codebase structure, read key modules
2. Identify duplicated logic, repeated patterns, copy-pasted blocks
3. Write a critical assessment of what you found (include it in the commit message)
4. Implement all HIGH CONFIDENCE deduplication — consolidate shared logic into helpers, merge near-identical components
5. Do NOT over-abstract. The goal is DRY "where it reduces complexity". Three similar lines is fine; three identical 10-line blocks is not. If introducing a helper makes the code harder to follow, don't.
6. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling)
7. Commit with a conventional commit message

Constraints:
- Comments in English, brief, only when intent isn't obvious
- Don't add abstractions for one-time operations
- Don't change user-facing behavior
```

### 2. Type Consolidation

```
<PROJECT INTRO>

Your task: Find all type definitions and consolidate any that should be shared.

1. Research: search for all type/interface definitions across the codebase
2. Identify types that are duplicated, nearly identical, or structurally equivalent
3. Check for types defined inline that belong in a shared module
4. Look for inconsistent type usage (same data shaped differently in different files)
5. Write a critical assessment in the commit message
6. Consolidate HIGH CONFIDENCE cases — create or use a shared types location
7. Leave alone types that are intentionally distinct (view-types of specific queries, contracts of pure functions, projections for charts)
8. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling)
9. Commit with conventional commit message

Notes:
- If the stack has a schema source of truth (Drizzle, Prisma, SQLAlchemy models, Hibernate entities, Protobuf, OpenAPI spec), consolidate toward it rather than creating parallel definitions
- Don't create new type files unless there's real duplication
```

### 3. Unused Code (knip)

```
<PROJECT INTRO>

Your task: Use tools like knip to find all unused code and remove it, ENSURING that it's actually not referenced anywhere.

1. Detect the stack and pick the right dead-code tool (knip for TS/JS, vulture for Python, cargo-udeps for Rust, `go vet`/`deadcode` for Go, IDE/linter warnings for Java/Kotlin/.NET, etc.). Install it as a development-only dependency if missing.
2. Run the tool to list unused exports, files, dependencies, and declarations
3. For EACH finding, manually verify it's truly unused. The brief explicitly demands that we "ensure that it's actually not referenced anywhere" — this is the key constraint. Check:
   - Dynamic imports (`import(...)`)
   - String references / indirect usage
   - Framework conventions (routing files loaded by convention: Next.js `page.tsx`/`layout.tsx`/`route.ts`, Rails controllers, Spring `@Component`/`@Controller`, Django URL includes, Go `init()`, etc.)
   - ORM/schema exports consumed by tooling (Drizzle, Prisma, SQLAlchemy, Diesel, Hibernate, ActiveRecord)
   - Build tool / config file references
   - Environment variable usage
4. Write a critical assessment in the commit message distinguishing:
   - Confirmed unused → removed
   - Flagged but used by convention → kept with note
   - Unclear → reported, not removed
5. Remove only confirmed-unused. Be CONSERVATIVE.
6. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling)
7. Commit with conventional commit message
8. Keep the dead-code tool installed as a development-only dependency for future audits
```

### 4. Circular Dependencies (madge)

```
<PROJECT INTRO>

Your task: Untangle any circular dependencies, using tools like madge.

1. Pick the right circular-dependency tool for the stack (madge or dependency-cruiser for TS/JS, pycycle/pylint for Python, `go list -deps` / go-cyclo for Go, cargo-modules for Rust, jdeps for Java, etc.). Install as a development-only dependency if missing.
2. Run it and collect the list of cycles
3. For each cycle found:
   - Analyze WHY it's circular
   - Determine the cleanest way to break it (extract shared code, reorganize imports, invert a dependency)
   - Implement the fix
4. Also review for:
   - Barrel files (index.ts) that cause unnecessary coupling
   - Files importing from too many unrelated modules
   - Dual-source imports (same symbol imported from two different paths)
5. Write a critical assessment in the commit message — including 0 cycles is a valid finding worth reporting
6. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling)
7. Commit with conventional commit message
8. Keep the circular-dep tool installed as a development-only dependency
```

### 5. Weak Types → Strong Types

```
<PROJECT INTRO>

Your task: Remove any weak types — `any`, `unknown`, and equivalents in other languages. Research what the types SHOULD be. Research in the codebase AND in related packages to make sure replacements are strong types and there are no type issues.

1. Search the codebase for the language's weak-type escape hatches. Examples:
   - TypeScript: `any`, `unknown` (unless at a system boundary), `as`/`<T>` casts, `@ts-ignore`/`@ts-expect-error`, non-null assertions (`!.`, trailing `!`)
   - Python: missing type hints, `Any` from `typing`, `# type: ignore`, excessive `cast()`
   - Java/Kotlin: raw types, `Object` where a generic applies, `@SuppressWarnings`, `!!` (Kotlin non-null assertion)
   - Go: `interface{}` / `any`, unchecked type assertions (`x.(T)`)
   - Rust: `unsafe`, `as` casts between numerics without justification, `mem::transmute`
   - C#: `dynamic`, `object` where generics apply, unchecked casts, `#pragma warning disable`
   - PHP: missing type declarations, `mixed`, `@phpstan-ignore-line`
2. For EACH finding, do the research the brief demands:
   - Read surrounding code
   - Read the imported package's type definitions (`.d.ts` for TS, `.pyi` stubs for Python, generated Java docs, Rust docs, etc.)
   - Check the schema / validation source of truth
   - Determine the correct strong type
3. Replace with strong types — prefer language-native narrowing (TS type guards, Python `TypeGuard`, Rust match on enums, Kotlin smart casts) over raw casts
4. Write a critical assessment in the commit message
5. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling) — ensure there are no type issues after replacement
7. Commit with conventional commit message

Important:
- Keep weak types at real system boundaries (JSON parsing, external API response, user input) until validated — that's their legitimate use
- Narrowing constructs (TS `as const`, Kotlin smart casts, Rust pattern matching) are not weakening — leave them
- If you can't determine the right type after research, leave it and report — don't guess
```

### 6. Defensive Programming Cleanup

```
<PROJECT INTRO>

Your task: Remove all try-catch and equivalent defensive programming if it doesn't serve a specific role of handling unknown or unsanitized input or otherwise has a reason to be there. Clear error handling, no error hiding, no fallback patterns.

1. Search for:
   - try/catch blocks
   - Null checks the type system already guarantees
   - Fallback values that hide errors instead of surfacing them (TS `?? default`, `|| default`; Python `dict.get(k, default)` hiding missing keys; Go empty-value returns; Ruby `rescue nil`; Java `Optional.orElse(x)` masking failures)
   - Error swallowing (catch that logs and continues, or returns default values hiding failures)
   - Defensive guards that can't actually trigger given the types
2. For each, evaluate against the brief's specific criteria:
   - Handles unknown or unsanitized input (user input, external API, file I/O)? → KEEP
   - Handles a genuinely unpredictable failure (constraint violation, network error, rate limit)? → KEEP
   - Catch does something meaningful (retry, user-facing error message, cleanup)? → KEEP
   - Silently swallowing errors or returning fake defaults? → REMOVE
   - Defensive against impossible states given the type system? → REMOVE
3. When refactoring makes callers simpler (e.g. throw-based → return-based), do it — the brief wants CLEAR error handling
4. Write a critical assessment in the commit message
5. Implement all HIGH CONFIDENCE removals
6. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling)
7. Commit with conventional commit message
```

### 7. Legacy / Fallback Code

```
<PROJECT INTRO>

Your task: Find any deprecated, legacy, or fallback code and remove it. Make sure all code paths are clean, concise, and as singular as possible.

1. Search for:
   - Comments mentioning "deprecated", "legacy", "old", "fallback", "workaround", "hack", "TODO", "FIXME", "TEMP", "temporary"
   - Code checking for old/new API patterns (migration compat)
   - Multiple code paths doing the same thing (old way + new way)
   - Unused feature flags or conditional logic
   - Backwards-compatibility shims
   - Dead branches that can never be reached
   - Env var checks for deprecated features
2. For each:
   - If the legacy path is no longer needed → remove it, keep only the clean singular path
   - If it's still needed → document why briefly
3. The brief insists on "singular" paths — wherever you find two ways to do the same thing, pick one and delete the other
4. Write a critical assessment in the commit message
5. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling)
6. Commit with conventional commit message

Caveats:
- Don't remove DB schema fields just because UI doesn't use them (data persistence ≠ UI usage)
- Framework patterns that look like fallbacks may be intentional (error boundaries, polyfills, back-compat shims mandated by library authors)
```

### 8. AI Slop / Comment Cleanup

```
<PROJECT INTRO>

Your task: Find any AI slop, stubs, LARP, unnecessary comments and remove them. Any comments that describe in-motion work, replacements of previous work with new work, or otherwise are not helpful should be either removed or replaced with helpful comments for a new user trying to understand the codebase — but if you do edit, be concise.

1. Search for:
   - AI slop: overly verbose comments explaining obvious code, "This function does X" JSDoc on trivial functions
   - Stubs: `// TODO: implement`, empty bodies, placeholder returns
   - LARP code: code that looks functional but does nothing meaningful
   - In-motion / replacement artifacts: "replaced X with Y", "moved from old location", "previously this was…", "new implementation of…"
   - Comments that just restate the code: `// increment counter` above `counter++`
   - Section dividers: `// ========`, `# --------`, `/* ***** */`, etc. — any decorative separator
   - Migration artifacts explaining WHY something was removed or changed
   - Commented-out code blocks
   - Leftover debug output (`console.log`, `print`, `fmt.Println`, `logger.debug`, `var_dump`, `System.out.println`, etc.)
   - Overly verbose AI-generated error messages
2. For each:
   - Useless → REMOVE
   - In-motion / migration artifact → REMOVE; or if it contains useful context, rewrite as a comment that helps a NEW reader understand the current state
   - Explains non-obvious WHY (business logic, security rationale, non-obvious decision) → KEEP, make concise
   - Stub → implement (if trivial) or remove
3. The brief explicitly says: "if you do edit, be concise". A rewritten comment that's longer than the original is a regression.
4. Write a critical assessment in the commit message
5. Run the project type-check / static-analysis AND the build (see Stack-Aware Tooling)
6. Commit with conventional commit message

KEEP rules (so slop removal doesn't become comment massacre):
- Comments explaining WHY (not WHAT)
- Security rationale (CSRF checks, timing-safe compare, etc.)
- Driver/framework limitations that affect usage
- Business invariants not obvious from the types
- User-facing copy in its original language — only touch code comments
```

## Reconciliation Strategy

After all 8 agents complete, each lives on its own branch/worktree. The job now is to combine them into a single branch without losing anyone's good work.

### Setup

1. Detect the repo's default branch (don't hardcode `main` — check `git symbolic-ref refs/remotes/origin/HEAD` or `git branch --show-current` on a clean clone). Call it `<base>` in the steps below.
2. Create target branch from `<base>`: `git checkout -b refactor/code-quality-cleanup <base>`
3. Look at each worktree's diff against `<base>` to know who touched what: `git -C <wt> diff <base> --stat`
4. Build a mental map: which files did multiple agents modify?

### Application order

Apply patches from **lowest conflict risk** to **highest**:

1. Small isolated changes (legacy, weak-types — usually 1-3 files)
2. Type consolidation (usually a new file + small edits)
3. Unused code (many files but mostly orthogonal to behavior changes)
4. Circular deps (usually minimal)
5. AI slop (many files but only comment changes)
6. Defensive programming (restructures API routes / shared guards)
7. DRY (largest structural change — apply last)

Use `git apply --check` before each patch. If it applies cleanly:
```bash
git -C <worktree> diff main -- <files> | git apply
```

### Handling conflicts

When two agents touched the same file:

- **Inspect both diffs.** Read what each agent changed, not just where.
- **Pick the better approach, not both.** Agents often converge on similar solutions; sometimes one is strictly better. Example from the canonical run: one agent refactored `requireAdmin` to return-based; another wrapped the throw-based version in a helper. The return-based refactor was strictly better — the wrapper became redundant and was dropped.
- **Apply the "winner" first, then cherry-pick non-conflicting bits from the other** (e.g. keep the `parseBody` helper even if you drop the `guardAdmin` wrapper).
- **Verify after each layered application.** The project's type-check / static analysis catches breaks fast — run it between patches, not just at the end.

### Final verification before handoff

- Project type-check / static analysis passes
- Project build / compile passes
- `git diff <base> --stat` matches what you expected
- If refactors changed runtime behavior (error classes, decorators, reflection, generics), spot-check with a minimal script that exercises the new pattern
- Grep every caller of a refactored API to confirm it uses the new pattern

Everything is left **uncommitted** on the target branch for the human to review.

## Handoff Summary Template

When the reconciliation is done, print a summary to the human like this (adapt to what actually happened — omit dimensions that found nothing):

```
Branch: refactor/code-quality-cleanup (uncommitted)
Base: <detected-base-branch>

Summary of changes by dimension:

1. DRY: <what was deduplicated, e.g. "extracted parseBody() helper used by 7 routes">
2. Types: <what was consolidated, e.g. "PlayerSummary shared between 2 files">
3. Dead code: <files/exports removed>
4. Circular deps: <cycles fixed, or "0 cycles found">
5. Weak types: <casts replaced with guards>
6. Defensive: <try-catch patterns cleaned>
7. Legacy: <dead paths removed>
8. Comments: <slop removed>

Verification:
- <type-check command> ✓
- <build command> ✓

Stats: N files changed, M deleted, K new.

Everything is uncommitted on the target branch.
```

State the facts and stop. Don't append "next steps" or command suggestions — the human knows their own workflow.

## Non-Negotiables

- **Worktree isolation.** Never spawn without `isolation: "worktree"`. They will conflict.
- **Parallel spawn.** All Agent calls in one message. Sequenced spawns defeat the skill.
- **High-confidence only.** The brief demands it. Missed improvements are cheap; wrong "improvements" that break prod are expensive.
- **Detailed research and critical assessment.** Every agent must research before editing and leave a written assessment in the commit. This is the brief's explicit requirement.
- **Verify at every layer.** Each agent type-checks and builds before finishing. The main conversation re-verifies after reconciliation. And again after merge.
- **No commit, no push, no PR on the target branch.** The skill's deliverable is an uncommitted working tree on a new branch. The human commits, pushes, and opens the PR (or rejects parts) on their own terms. Per-agent worktrees commit internally (that's how their diffs survive long enough to be applied) — but those worktrees are disposable scratch space, deleted at the end.

## Common Pitfalls

- **Over-abstracting.** The brief says DRY "where it reduces complexity" — not everywhere. Three similar lines is fine.
- **Deleting framework files that look unused.** Many frameworks load code by convention, not by direct import — file-system routing (Next.js, SvelteKit, Remix, Rails, Django), annotation-based discovery (Spring `@Controller`, Quarkus, ASP.NET), ORM/schema exports consumed by CLI tooling (Drizzle, Prisma, Alembic), reflection/decorators (NestJS, FastAPI, Laravel). The brief says "ensure that it's actually not referenced anywhere" — treat that as a literal verification step: if a static analyzer flags a file as unused but the framework picks it up at runtime, it's NOT unused.
- **Weakening types to eliminate `any`.** The brief says research the right type and make sure "there are no type issues". If you can't determine it, leave and report — don't replace with something equally vague.
- **Killing legitimate try/catch.** The brief explicitly keeps try/catch that "serves a specific role of handling unknown or unsanitized input or otherwise has a reason to be there". System boundaries stay.
- **Removing `unknown` at real boundaries.** JSON-parsing external input should stay `unknown` until validated.
- **Comment massacre.** The brief says comments that describe in-motion work should be "removed OR replaced with helpful comments" — and "if you do edit, be concise". Don't just nuke; rewrite where the underlying information helps a new reader.
- **Stale worktrees.** Always clean up `.claude/worktrees/agent-*/` and delete the `worktree-agent-*` branches once reconciliation finishes.
- **Assuming branch names.** Never hardcode `main` — detect the base branch (`git symbolic-ref refs/remotes/origin/HEAD`) and use that. Repos use `main`, `master`, `develop`, `trunk`, whatever.
- **Unsolicited next-step prescriptions.** After the handoff summary, stop. The human decides whether to commit, squash, push, open a PR, or throw it all away.
