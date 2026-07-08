---
name: precommit
description: Pre-commit review — remove Claude references, update docs/diagrams/schemas/mappings, check skills for stale references, then draft a detailed multiline commit message per submodule. Does not auto-add or auto-commit.
argument-hint: [scope hint]
---

# Pre-Commit Review

Full pre-commit hygiene pipeline. If `$ARGUMENTS` is provided, use it to scope the review. Otherwise review all changes since the last commit. Works with any project — auto-detects repo root and submodules.

## Step 1: Remove Claude References

Search the entire codebase for any references to Claude, Anthropic, or co-authored-by trailers:

```bash
grep -ri "claude\|anthropic\|co-authored-by" --include="*.{py,yaml,yml,md,xml,json,txt,cfg,java}" .
```

If found, remove them. Report what was found and removed, or confirm none were found.

## Step 2: Identify All Changes

Detect the repo root and check for submodules:

```bash
git rev-parse --show-toplevel
git submodule status
```

Check both the main repo and any submodules with changes:

```bash
git status
git diff --stat HEAD
```

For each submodule with changes:
```bash
cd <submodule> && git status && git diff --stat HEAD
```

Categorize changes as: new files, modified files, deleted files, renamed files.

## Step 3: Update Docs, Diagrams, Schemas, Mappings

For each category, check if updates are needed based on the changes found in Step 2:

- **Docs** (`docs/` directory, `README.md` files): Check if any docs reference changed files, paths, or features. Update stale references.
- **Diagrams** (Mermaid in `.md` files, standalone diagram files): Check if changes invalidate any diagrams.
- **Schemas** (`.xsd`, `.xtce`, schema definitions): Check if data model changes require schema updates.
- **Mappings** (`*mapping*`, `*_mappings.yaml`): Check if renamed or restructured files need mapping updates.

Report what was checked and what (if anything) was updated.

## Step 3.5: Check Skills for Stale References

Scan `~/.claude/skills/*/skill.md` for references that may have been invalidated by the changes found in Step 2. Only check skills whose content references the current project (match by repo name, mission name, or paths within the repo).

For each relevant skill, check whether it references:
- **Paths** that were moved, renamed, or deleted
- **Taskfile targets** that were renamed or removed
- **Class names, function names, or CLI commands** that changed
- **Conventions** (commit message style, file formats) that were updated

Cross-reference against the actual diff from Step 2 — only flag concrete matches, not speculative ones.

If stale references are found, report them with the skill name, the stale reference, and what it should be updated to. Do NOT edit skills automatically — just flag them for the user.

If no skills are affected, confirm with: "Skills: no stale references found."

## Step 4: Draft Commit Messages

Draft separate commit messages for each scope that has changes.

### Submodule(s) — if changed

Submodules must be committed first. Draft each submodule's message based only on its own changes.

### Main repo — if changed

Draft the main repo message. If a submodule was also changed, the main repo commit should mention the updated submodule pointer.

### Message format

```
<Summary line in past tense — what changed and why>

<Area heading>:
- Specific detail
- Specific detail

<Area heading>:
- Specific detail
```

**Rules:**
- Past tense: "Added", "Removed", "Updated", "Fixed", "Replaced", "Renamed"
- No Co-Authored-By trailer referencing Claude or Anthropic
- Detailed multiline with area-based sections

## Step 5: Present for Review

Show the user:

1. Claude reference scan result (clean or what was removed)
2. Docs/diagrams/schemas/mappings update summary
3. Skills staleness check result (clean or what needs updating)
4. For each scope with changes:
   - Files to stage (with exact `git add` commands)
   - Proposed commit message (the message text only, not wrapped in a git command)

**Do NOT run `git add` or `git commit` — only present the commands and message for the user to run.**
