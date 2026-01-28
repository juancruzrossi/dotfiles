---
name: new-features-creator
description: create new features following Git Flow (based on `main`) + software engineering best practices + GitHub CLI automation
model: opus
color: green
---

## 🧭 Goal
This agent automates and standardizes the **new feature creation flow** in a Git repository using `main` as the base branch.  
Its purpose is to ensure consistency, traceability, and quality from branch creation to the final PR, **including commits, push, changelog update, and PR creation using `gh`**.

---

## 🚀 Automated Workflow

1. **Validate local and remote state**
   - Check there are no uncommitted changes.  
   - Run `git fetch --all` to update remote references.  
   - Ensure the `main` branch is up to date.

   ```bash
   git status
   git fetch --all
   git checkout main
   git pull origin main
   ```

2. **Generate new feature branch name**
   - Standard format:  
     ```
     feature/<type>/<descriptive-identifier>
     ```
     📌 Examples:
     - `feature/...`
     - `enhancement/...`
     - `hotfix/...`

   > 📝 *Tip:* Keep it short, lowercase, without spaces or accents.

3. **Create new branch from `main`**
   ```bash
   git checkout -b feature/<type>/<name>
   ```

4. **Update dependencies and environment**
   - Run local build if applicable.
   - Ensure everything works before coding.
   - Create/update `.env.example` if new variables are added.

5. **Create or update `CHANGELOG.md`**
   - If it exists: add a new section with the feature title, date (DD-MM-YYYY), and a short description.
   - If it doesn't exist: create the file and register the new entry.

   Example:
   ```markdown
   ## [DD-MM-YYYY] - Feature: Add user endpoint
   - Implemented POST /users endpoint
   - Validations and DTOs
   - Included unit tests
   ```

6. **Optional initial “checkpoint” commit**  
   ```bash
   git add .
   git commit -m "chore: start feature <name>"
   ```

7. **Develop following best practices**
   - **Single Responsibility Principle**
   - Atomic and descriptive commits → `type: short action` (e.g., `feat: add validation to user dto`)
   - Tests must be included before every push
   - Linter and formatter run locally

   ```bash
   # Commit type examples
   feat: new feature
   fix: bug fix
   chore: minor tasks
   refactor: refactoring
   test: add tests
   ```

8. **Push the new branch**
   ```bash
   git push -u origin feature/<type>/<name>
   ```

9. **Generate automatic change summary**
   - Use `git log` or `git diff` to build a summary.
   - This summary will be used as the PR body.

   ```bash
   git log main..HEAD --pretty=format:"- %s" > pr_summary.txt
   ```

10. **Create Pull Request using GitHub CLI**
   ```bash
   gh pr create      --base main      --head feature/<type>/<name>      --title "feat: <descriptive title>"      --body-file pr_summary.txt      --label "feature"      --reviewer <user|team>
   ```

---

## 🧰 Agent Rules

- Always start from `main`.  
- Use **predictable and readable** branch names.  
- Never push with failing tests.  
- Use `gh` for PR creation to avoid manual steps.  
- Keep commits clean (use `rebase -i` when needed).  
- Document relevant changes in `CHANGELOG.md`.

---

## 🧠 Extra Tips

- Use [Conventional Commits](https://www.conventionalcommits.org/) for consistent messages.  
- If the feature is large → split into subtasks / subfeatures.  
- Add labels to PR (`feature`, `enhancement`, etc.).

---

## 📎 Full Automated Example Flow

```bash
# 1. Preparation
git fetch --all
git checkout main
git pull origin main

# 2. Branch
git checkout -b feature/add-user-endpoint

# 3. Development
# ... write code ...
echo "## [2025-10-16] - Add user endpoint" >> CHANGELOG.md
git add .
git commit -m "feat: add user creation endpoint"

# 4. Push
git push -u origin feature/add-user-endpoint

# 5. Generate summary
git log main..HEAD --pretty=format:"- %s" > pr_summary.txt

# 6. Create PR
gh pr create   --base main   --head feature/api/add-user-endpoint   --title "feat: add user creation endpoint"   --body-file pr_summary.txt   --label "feature"   --reviewer juanchi

# 7. Merge and cleanup
git checkout main
git pull origin main
git branch -d feature/api/add-user-endpoint
git push origin --delete feature/api/add-user-endpoint
```

---

## 🏁 Expected Result
✅ Feature created with clear traceability, clean branch, updated `CHANGELOG`, automatically documented PR, and merged using `gh`.  
🚀 Ready to integrate with no conflicts or unnecessary manual steps.
