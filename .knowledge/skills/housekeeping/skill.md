---
name: housekeeping
description: Audit a codebase for redundant, stale, unused, or inefficient code. Scans scripts, configs, data files, tasks, skills, and documentation for drift, dead code, orphaned files, and stale references. Produces a categorized findings report with severity and actionable fixes.
argument-hint: [directory or scope hint]
---

# Codebase Housekeeping Audit

Run a systematic audit of the codebase (or a scoped subset if `$ARGUMENTS` is provided). Auto-detects the project root. Produces a categorized findings report — never auto-fixes without user approval.

## Audit Categories

Scan for all of the following. Report each finding with severity (critical / warning / info) and the exact file:line.

### 1. Stale Documentation & Skill References

Check all `.md` files, `SKILL.md` frontmatter, and `references/*.md` for:
- References to files that no longer exist
- Table/column names that have been renamed
- Outdated counts or stats
- CLI syntax or usage examples that no longer match actual commands
- Task names that have been renamed in Taskfile.yaml
- Stale task lists that omit recently added tasks

**How to check:** Read each `.md` file. Cross-reference every filename, table name, column name, task name, and CLI flag against the actual codebase. Flag any that don't resolve.

### 2. Redundant or Dead Code

Check scripts for:
- Functions/classes that are defined but never called (from any script or Taskfile)
- Import statements for modules that are never used
- Scripts that duplicate functionality already in another script
- Commented-out code blocks longer than 5 lines
- Variables assigned but never read
- `TODO`/`FIXME`/`HACK` markers older than 30 days

**How to check:** For each function in each script, grep the entire codebase for call sites. For imports, check whether the imported name appears after the import line.

### 3. Orphaned & Misplaced Files

Check data directories for:
- Files not referenced by any script, Taskfile task, or processing manifest
- Derived/generated files mixed in with canonical source files
- Temp files, `.bak`, `.tmp`, `.orig` files left behind
- Cache files that should be in `.gitignore` but aren't
- Empty files or placeholder files with no content

**How to check:** For each file in data directories, grep scripts and configs for its filename stem. Flag any that appear nowhere.

### 4. Taskfile Staleness

Check `Taskfile.yaml` for:
- Tasks that reference scripts or files that no longer exist
- Tasks that call other tasks (via `task:`) where the callee has been renamed or deleted
- Duplicate task logic (two tasks that do substantially the same thing)
- Tasks listed in `desc` or comments with outdated information
- Variables defined but never interpolated
- Tasks with no callers (not referenced by any other task, and not commonly run standalone)

**How to check:** Extract all task names, all `task:` references, all file paths, and all variable interpolations. Cross-reference.

### 5. Schema & Pipeline Drift

For database-backed projects, check:
- Tables in schema DDL that have no corresponding handler or seed data
- FK references in SQL that don't match field names
- Column names in schema vs. column names in handlers
- Indexes on columns that no longer exist or have been renamed

**How to check:** Parse the schema DDL for table/column names. Parse handlers for column lists. Diff.

### 6. Efficiency & Code Smell

Flag (as info-level) patterns that work but could be improved:
- Shell pipelines that read the same large file multiple times
- Scripts that load entire datasets into memory when streaming would suffice
- Taskfile tasks that could use `deps:` or `sources:`/`generates:` for caching
- Repeated boilerplate across multiple handlers that could be factored out

## Output Format

Present findings grouped by category. For each finding:

```
### [Category Name]

**[severity]** `file:line` — Description of the issue.
  - Current: what exists now
  - Expected: what it should be (or "remove")
  - Fix: one-line description of the remediation
```

At the end, provide a summary table:

| Severity | Count |
|----------|-------|
| Critical | N     |
| Warning  | N     |
| Info     | N     |

## Important

- Never auto-fix. Present all findings and wait for user to approve which to address.
- If a finding is ambiguous (might be intentional), flag it as info and note the ambiguity.
- Focus on drift between documentation and reality — stale docs are worse than missing docs.
- For large codebases, prioritize: stale docs > dead code > orphaned files > efficiency.
