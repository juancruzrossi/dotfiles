---
name: explain-code
description: Explain code as a detailed, conversational markdown file written to the user's cwd
disable-model-invocation: true
keep-coding-instructions: true
---

# Explain Code

Explain the user-scoped code as a detailed, conversational markdown document. Write the explanation to a file in the user's current working directory — do not just print it to chat.

## Output target

- Write the full explanation to a markdown file in the cwd using the `Write` tool.
- Filename: `CODE_EXPLAINED.md` by default. If a scope is explicit (e.g. a single file or feature name), use `<scope-slug>.explained.md` (lowercase, kebab-case, max 40 chars).
- If the file already exists, overwrite it without asking.
- After writing, reply in chat with a **single short line**: the file path and a one-sentence summary of what it covers. No repeated content.

## Tone

- Colloquial and conversational — close and direct, not academic.
- First-person plural ("let's see…", "notice how…") is allowed.
- Match the user's language. If the prompt is in Spanish, write the whole document in Spanish. If English, English.
- Clear, not casual to the point of sloppy. No filler ("basically", "simply just").

## Structure

Write the file with exactly this structure:

1. `#` Title — one plain-English line naming the topic.
2. `📋 TLDR` — 2-4 sentences with the gist. Optionally one small `mermaid` block if a diagram genuinely helps.
3. Horizontal rule `---`.
4. One or more `##` sections, each covering one idea.
5. Optional `## 🗺️ Quick map` section near the top with a file-tree or bullet index when the scope is multi-file.

## Each `##` section

- Title with at least one emoji.
- 2-4 sentences of plain-language lead-in explaining the *why* and the *what*.
- One fenced code block (required).
- 1-3 sentences after the code block explaining the key lines, gotchas, or how it connects to other sections. (This is the one place prose-after-code is allowed — use it to teach, not to repeat.)
- Separate sections with `---`.

## Code blocks

- Show only the code needed for the section's point. Aim for 8-20 non-blank lines.
- Use the correct language tag (```` ```ts ````, ```` ```python ````, etc.).
- Prefer behavior-faithful sketches over verbatim excerpts when the real code has noise.
- Include short intent comments on the key lines — tell the reader why this line matters, not what it syntactically does.
- Use `...`, `// ...`, or simplified identifiers when that makes the idea clearer.
- For multi-file stories, one section can show a small `diff`-style or tree block instead of code.

## Depth

- Cover the full scope the user asked about. If they said "todo el código", map every major module/app/route.
- For each main piece: what it does, how it plugs into the rest, and one concrete gotcha or detail worth knowing.
- Do not invent intent, bugs, or features that the code does not support.
- If the scope is huge, group by layer (backend / frontend / cross-cutting) and cap at ~12 sections total — quality over exhaustiveness.

## Scope fallback

- If the user specifies a scope (file, directory, feature, diff), use exactly that.
- If no scope and there are unstaged changes, default to the unstaged diff.
- If no scope and no unstaged changes, ask the user what to explain before writing anything.

## Guardrails

- Do not include secrets, long literals, or opaque blobs — use placeholders.
- Do not write line-by-line transcripts unless the user asked for that.
- Do not add "Next steps", "Conclusion", or "Further reading" sections unless the user asked.
- Do not add features to the skill's output (TOC, badges, timestamps, author lines, etc.) that the user did not request.
- The chat reply after writing must be one short line — never paste the document content back into chat.
