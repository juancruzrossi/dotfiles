# Script: Context Gatherer

Collects project context from all available sources and produces a compact `PROJECT_CONTEXT:` block that is passed to finding agents, triage, and judge.

Runs once in Stage 0.5 — before launching any pipeline subagents.

## Instructions

### 1. Detect available sources

Check what sources exist in the current project. Do not fail if a source is unavailable.

#### 1a. Local rules and conventions

```bash
# Project CLAUDE.md
[ -f CLAUDE.md ] && echo "found:claude-md" || echo "skip"

# Agent rules
[ -d .claude/rules ] && ls .claude/rules/ || echo "skip"

# Security rules
[ -d .agentic-rules ] && ls .agentic-rules/ || echo "skip"
```

If present: read contents and extract rules relevant to the diff (forbidden patterns, code conventions, architecture restrictions, security requirements).

#### 1b. Project memory

```bash
[ -d .claude/memory ] && ls .claude/memory/ || echo "skip"
```

If present: read memory files and extract info relevant to the diff (past technical decisions, known tech debt, established patterns).

#### 1c. Available MCP servers

```bash
[ -f .mcp.json ] && cat .mcp.json || echo "skip"
```

If `.mcp.json` exists: identify configured MCP servers. Prioritize those that provide architecture, API, or documentation context. For each relevant MCP, run queries focused on the diff files (API specs, review instructions, ADRs, runbooks).

#### 1d. Repository context

```bash
# Tech stack
head -50 README.md 2>/dev/null || echo "skip"

# Main dependencies
[ -f package.json ] && cat package.json | head -30 || true
[ -f pom.xml ] && head -40 pom.xml || true
[ -f go.mod ] && cat go.mod || true
[ -f requirements.txt ] && cat requirements.txt || true
[ -f Gemfile ] && cat Gemfile || true
```

### 2. Filter by diff relevance

Do not include all available context — only what is relevant to the diff files.
For each fragment, ask: "does this affect how this diff should be reviewed?"

Relevance criteria:
- Conventions that apply to the language/framework of modified files
- Architecture restrictions the changes may violate
- Security patterns required for the touched modules
- Known tech debt in the modified areas
- APIs or contracts the diff may be changing

### 3. Produce PROJECT_CONTEXT:

Synthesize all relevant info into a compact block:

```
PROJECT_CONTEXT:
  RULES:
    - [project rule or convention]
    - [architecture restriction applicable to the diff]
    - [required security pattern]

  MEMORY:
    - [relevant past technical decision]
    - [known tech debt in diff areas]

  MCP_CONTEXT:
    - [API or architecture info from MCP]
    - [relevant ADR or doc found]

  TECH_STACK:
    language: [main language]
    framework: [detected framework]
    key_deps: [key dependencies relevant to the diff]

  SOURCES_USED: [claude-md, rules, memory, mcp, readme]
  SOURCES_SKIPPED: [sources not available in this project]
---END_PROJECT_CONTEXT---
```

If no source is available: produce `PROJECT_CONTEXT: NONE`.

### 4. Show summary to the user

```
Context Gatherer complete:
  Sources used: [list]
  Rules found: N
  Memory items: N
  MCP context: [available / not available]
```
