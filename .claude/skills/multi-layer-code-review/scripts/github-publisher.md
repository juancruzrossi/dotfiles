# Script: GitHub Publisher

Publishes inline comments on a GitHub PR via `gh api`.
Receives the comment data and publishes it at the exact location (file:line).

## Instructions

### 0. Verify `gh` is available

```bash
gh --version 2>/dev/null
```

If the command fails (gh not installed):

Show the user:
```
Publishing to GitHub requires the GitHub CLI (gh).
Install it now? [y/n]:
```

**If "y" (or "yes"):**

Detect the OS via `uname -s` and show the exact commands to run. Tell the user to paste them in their terminal or use `! <command>` directly in chat:

**macOS:**
```
Run these commands in your terminal:

  brew install gh
  sudo chown -R $(whoami) ~/.config   # only if you got a permissions error
  gh auth login

In gh auth login pick: GitHub.com → HTTPS → Login with a web browser
When done, type "ready" to continue.
```

**Linux (Debian/Ubuntu):**
```
Run these commands in your terminal:

  sudo apt-get install gh -y
  sudo chown -R $(whoami) ~/.config   # only if you got a permissions error
  gh auth login
```

**Linux (RedHat/CentOS):**
```
Run these commands in your terminal:

  sudo yum install gh -y
  sudo chown -R $(whoami) ~/.config   # only if you got a permissions error
  gh auth login
```

Wait for user confirmation. Then verify with `gh auth status` and resume from step 1.

**If "n":**

Show the formatted comment on screen so the user can copy it:
```
To publish manually, copy this comment into the PR:
─────────────────────────────────────
[GITHUB_COMMENT]
─────────────────────────────────────
File: [file_path] line [line_number]
```
Then stop.

### 1. Get PR info

```bash
pr_number=$(gh pr view --json number --jq '.number' 2>/dev/null)
commit_id=$(gh pr view --json headRefOid --jq '.headRefOid' 2>/dev/null)
owner_repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)

if [ -z "$pr_number" ]; then
  echo "ERROR: No open PR for this branch. Create the PR first with gh pr create."
  exit 1
fi

echo "PR #$pr_number | Commit: $commit_id | Repo: $owner_repo"
```

### 2. Verify the file and line exist in the diff

```bash
# Check file:line is in the PR diff
gh api "repos/$owner_repo/pulls/$pr_number/files" \
  --jq ".[] | select(.filename == \"$file_path\") | .patch" 2>/dev/null | head -5
```

If the file is not in the diff: the comment cannot be inline — publish as a general PR comment (step 3b).

### 3a. Publish inline comment (specific file:line)

```bash
gh api "repos/$owner_repo/pulls/$pr_number/comments" \
  --method POST \
  -f body="$comment_body" \
  -f path="$file_path" \
  -f line=$line_number \
  -f commit_id="$commit_id" \
  --jq '.html_url' 2>/dev/null
```

If it fails (line outside the diff, file not modified): fall back to 3b.

### 3b. Fallback: general PR comment

```bash
gh pr review "$pr_number" \
  --comment \
  --body "$comment_body" 2>/dev/null
```

### 4. Confirm publication

Return the URL of the published comment. On failure: show the error with context so the user can post it manually.

## Expected input

Caller must provide:
- `$comment_body`: markdown text of the comment (with code snippet already replaced)
- `$file_path`: relative path of the file (e.g., `app/domain/entities/mcp_data.py`)
- `$line_number`: line number in the file
- (optional) `$pr_number`, `$commit_id`, `$owner_repo` if already obtained

## Security notes

- Do not log the full comment contents in output (may contain sensitive snippets).
- If the GitHub token lacks `pull-requests: write` permissions, publish will fail with 403.
- Verify permissions before attempting: `gh auth status`.
