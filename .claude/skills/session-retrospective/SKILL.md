---
name: session-retrospective
description: Review the current conversation to extract actionable learnings — errors and corrections, user preferences, technical discoveries, skill opportunities, and memory updates. Use when the user asks to review the session, recap what was learned, or capture learnings before context is lost.
---

# Session Retrospective

Analyze the current conversation to extract actionable knowledge, then present findings to the user for selective persistence.

## When to Use

- At the end of a work session to capture learnings before context is lost
- When the user asks to review what happened in the session
- After a particularly complex or error-prone task sequence
- When the user wants to update memory or create/improve skills based on session work

## Analysis Framework

Review the entire conversation and extract findings in these categories:

### Category 1: Errors & Corrections

Scan for moments where:
- A tool call failed and required a different approach
- The user corrected a mistake or wrong assumption
- A command was blocked (hooks, permissions, safety nets)
- An approach was tried and abandoned for a better one

For each, capture: **what went wrong**, **what fixed it**, **the takeaway**.

### Category 2: User Preferences & Feedback

Scan for moments where:
- The user expressed a preference ("always do X", "never do Y", "I prefer Z")
- The user gave stylistic feedback ("too green", "make it brighter", "in English")
- The user corrected communication style or language
- The user rejected an approach and suggested another

For each, capture: **the preference**, **whether it's project-specific or global**.

### Category 3: Technical Discoveries

Scan for moments where:
- A non-obvious solution was found after investigation
- A workaround was needed for a tool/framework limitation
- Configuration or environment quirks were discovered
- A pattern emerged that would help in similar future tasks

For each, capture: **the discovery**, **when it applies**, **whether it's reusable**.

### Category 4: Skill Opportunities

Scan for:
- Repeated workflows that could be automated into a skill
- Domain knowledge that was built up during the session
- Existing skills that were used but could be improved
- Missing skills that would have saved time

For each, capture: **the opportunity**, **estimated value (high/medium/low)**.

### Category 5: Memory Updates

Scan for:
- Project-specific knowledge worth persisting (architecture, patterns, file paths)
- Debugging insights that apply to this codebase
- Tool configurations or environment setup details
- Anything the user explicitly asked to remember

For each, capture: **what to remember**, **which memory file it belongs to**.

## Presentation Format

After analysis, present findings to the user in this format:

```
## Session Retrospective

### Errors & Corrections
1. [finding] → **Takeaway:** [lesson]
2. ...

### User Preferences
1. [preference] → **Scope:** project / global
2. ...

### Technical Discoveries
1. [discovery] → **Reusable:** yes/no
2. ...

### Skill Opportunities
1. [opportunity] → **Value:** high/medium/low → **Action:** create new / update [name]
2. ...

### Memory Updates
1. [what to remember] → **File:** MEMORY.md / [topic].md
2. ...
```

## User Decision

After presenting findings, ask the user which items to act on. Use AskUserQuestion with multiSelect to let the user pick specific items. Group the question by action type:

1. **Write to memory** — which findings to persist in auto-memory files
2. **Create new skill** — which opportunities to turn into new skills (invoke skill-creator)
3. **Update existing skill** — which existing skills to improve
4. **Skip** — acknowledge but don't persist

## Execution

For each selected action:

- **Memory updates**: Write directly to the appropriate memory file using Edit or Write tools. Keep entries concise. Link to topic files from MEMORY.md when details are long.
- **New skills**: Invoke the `skill-creator` skill via the Skill tool for each new skill to create.
- **Skill updates**: Read the existing skill's SKILL.md, apply improvements, and write back.

## Guidelines

- Be selective. Not every conversation moment is worth persisting. Focus on non-obvious, reusable knowledge.
- Avoid duplicating information already in CLAUDE.md, AGENTS.md, or existing memory files. Check first.
- User preferences that contradict existing instructions should be flagged, not silently overwritten.
- Present findings concisely. The user should be able to scan the list in 30 seconds.
- If the session was routine with no notable learnings, say so honestly instead of forcing extraction.
- When in doubt about whether something is worth persisting, include it in the presentation but mark it as low priority — let the user decide.
