---
name: commit
description: Create a git commit following project conventions. Past tense, detailed multiline, area-based sections, no co-authored-by.
argument-hint: [message override]
---

# Git Commit

Create a git commit following project conventions. If `$ARGUMENTS` is provided, use it as a message hint. Otherwise, analyze staged/unstaged changes and draft the message.

## Commit Conventions

1. **Past tense** — "Added", "Fixed", "Updated", "Removed" (not "Add", "Fix")
2. **No Co-Authored-By** — do not include any co-authored-by trailer
3. **Detailed multiline** — short summary line, blank line, then detailed body with sections

## Workflow

### Step 1: Assess Changes

```bash
git status
git diff --stat HEAD
git diff HEAD
```

Categorize changes as: new files, modified files, deleted files, renamed files.

### Step 2: Check for Sensitive Content

Never commit files containing:
- `.env` files with real values
- API keys, tokens, or credentials
- Large binary files

### Step 3: Draft Commit Message

Structure:
```
<Summary line in past tense — what changed and why>

<Section 1 heading>:
- Detail 1
- Detail 2

<Section 2 heading>:
- Detail 1
- Detail 2
```

Section headings should group by area of change, e.g.:
- "Containers:"
- "Helm:"
- "CI:"
- "Taskfile:"
- "Documentation:"

### Step 4: Present for Review

Show the user:
1. Files to be staged (with `git add` commands)
2. The proposed commit message
3. The commit command (using HEREDOC format)

Do NOT automatically run `git add` or `git commit` — wait for user approval.

### Commit Command Format

Always use HEREDOC for multiline messages:
```bash
git commit -m "$(cat <<'EOF'
Summary line here

Section:
- Detail
EOF
)"
```

## Example Commit Messages

**Good:**
```
Standardized container paths to /opt/ and added Helm ConfigMap entrypoints

Containers:
- Updated all WORKDIR paths from /yamcs/ to /opt/yamcs/
- Added COPY entrypoint.sh /entrypoint.sh and CMD to all Containerfiles
- Added explicit cd comments in all entrypoint scripts

Helm:
- Added ConfigMap-based entrypoint templates for all charts
- Updated deployment command and volumeMount to use /entrypoint.sh
- Added env vars from Containerfile ARGs to values.yaml
```

**Bad:**
```
update containers and helm charts
```
