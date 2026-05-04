---
name: local-review
description: Multi-agent local code review of pending changes. Mirrors the /ultrareview pattern but runs locally and applies an opinionated rubric. Spawns six parallel subagents covering security, bugs/correctness, code quality, consistency, documentation, and customer-facing doc clarity. Use when the user runs /local-review or asks to review the current branch or a PR locally.
---

# Local review

Run a parallel multi-agent review of the current branch's diff (or a specified PR). Same fan-out shape as `/ultrareview` but local, free per run, and tuned to an opinionated rubric.

## Diff selection

1. If invoked with a `<PR#>` argument: `gh pr diff <PR#>`. If `gh` is not authed or the PR is unreachable, surface that and stop.
2. Otherwise: diff current branch against its merge-base with `origin/main`:
   - `base=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main)`
   - `git diff $base..HEAD`
3. If neither resolves (no git, no main branch, etc.), ask the user which diff to review.

Capture both the diff and the changed-files list (`git diff --name-only $base..HEAD`). If the diff is large, write it to a temp file under `/tmp/local-review-<timestamp>.diff` and pass the path to subagents instead of inlining.

## Process

Spawn six subagents **in parallel** via the Agent tool (single message, six tool-use blocks). Use `subagent_type: general-purpose` so each can read files in the repo for context.

Each subagent prompt includes:
- The diff (inline if small, else the temp file path)
- The list of changed files
- The category-specific rubric (below)
- The required output format (see "Subagent output format")
- Permission to read additional files in the repo for context, but not to make any edits

After all six return, aggregate findings into a single report (see "Final report").

## Subagent output format

Each subagent must return findings as a JSON-ish list, one per line, using this exact shape:

```
[severity] file:line — message
```

- `severity` is one of: `blocker`, `important`, `nit`
- `file:line` is `path/to/file.ext:42`. Omit `:line` only if the finding is file-wide.
- `message` is one short sentence stating what's wrong and why it matters

If no findings, return the literal: `No findings.`

## Severity definitions

- **blocker**: must fix before merge. Security holes, broken correctness, data loss, public-API breakage.
- **important**: should fix before merge or follow up immediately. DRY violations, missing tests for new code paths, doc/code drift, public-facing copy issues.
- **nit**: minor. Naming, style, small simplifications, optional improvements.

## Rubric (one subagent per section)

### 1. Security

Look for:
- Input validation gaps at trust boundaries (user input, network input, file/env input)
- Injection vectors: SQL, command, path traversal, XSS, prompt injection in LLM-facing code
- Auth/authz mistakes: missing checks, IDOR, privilege escalation, session handling errors
- Secrets, tokens, or credentials in code, logs, error messages, or test fixtures
- Unsafe defaults: open permissions, weak crypto, verbose errors leaking internals, disabled TLS verification
- Risky new dependencies or version bumps
- Hardcoded URLs/endpoints that should be configurable

### 2. Bugs / correctness

Look for:
- Logic errors, off-by-one, wrong operators, inverted conditions
- Null/undefined/None handling, missing edge cases, empty collections
- Race conditions, ordering bugs, missing locks/awaits in concurrent code
- Wrong API usage: misread parameters, return-value misinterpretation
- Error paths that swallow errors, mishandle them, or use the wrong error type
- Tests that don't actually exercise the new behavior, or that pass for the wrong reason
- Resource leaks: files, connections, goroutines/promises not cleaned up

### 3. Code quality

Apply these preferences:
- Clean, not over-engineered
- DRY but no premature abstraction. Three similar lines is better than a premature abstraction.
- Don't add error handling, fallbacks, or validation for scenarios that can't happen
- No backwards-compat shims or hypothetical-future-requirement scaffolding
- Validation only at system boundaries, trust internal code
- Comments explain WHY (only when non-obvious), never WHAT

Look for:
- Duplicated logic that should be DRY'd
- Abstractions added before justified, or interfaces with one implementation
- Unused vars, imports, dead code
- Comments that explain what the code already says
- Comments that reference the current task or callers ("added for X flow", "used by Y")
- Half-finished implementations
- Defensive programming on inputs that come from trusted internal code

### 4. Consistency

Look for:
- Naming patterns that don't match the rest of the file/module/codebase
- File structure inconsistent with neighbors
- New patterns introduced where an established one already exists
- Inconsistent error handling style within the same module (some throw, some return Result)
- Inconsistent API shapes across sibling functions
- Mixed style: tabs vs spaces, quote style, import ordering, where established

You may read related files in the repo to verify "is this consistent with how the rest of the code does it?"

### 5. Documentation review

Scope: technical documentation (READMEs, design docs, code comments, docstrings, ARCHITECTURE.md, etc.).

Look for:
- Code changes that should have updated comments/docstrings/READMEs but didn't
- Stale docs that no longer match the changed code
- New public APIs (exported functions, CLI flags, config keys) that lack documentation
- Examples in docs that wouldn't run against the new code
- Broken intra-doc links, references to renamed symbols, or outdated file paths
- Changelogs/release notes not updated when a feature/fix landed

### 6. Customer-facing doc clarity

Scope: ONLY docs in customer-facing locations (top-level `README.md`, `docs/`, `getting-started/`, marketing copy, public-facing API docs, onboarding flows). Skip internal-only docs.

Look for:
- Sequential instructions that aren't numbered when they should be (1, 2, 3 steps)
- Steps that assume knowledge or state not yet introduced earlier in the doc
- Jargon a new user wouldn't know, with no glossary or short definition inline
- Missing prerequisites ("before you start, you'll need...")
- Error states or troubleshooting not addressed
- Code samples without expected output, so the reader can't verify they did it right
- Tone that isn't cheerful, positive, helpful
- Em-dashes anywhere (author preference; remove this line if your project allows them)

## Final report

After all six subagents return, print this exact structure to chat. Do not write to a file unless the user asks.

```
# Local review report

Scope: <branch vs base | PR #N>
Diff: <N files changed, +X/-Y lines>

## Blockers
[grouped by category, or "None"]

## Important
[grouped by category, or "None"]

## Nits
[grouped by category, or "None"]

## Summary
- Blockers: N
- Important: N
- Nits: N
- Recommendation: <ship | fix-blockers-then-ship | needs-rework>
```

Recommendation rules:
- Any blocker → `needs-rework` (or `fix-blockers-then-ship` if the blocker count is small and clearly addressable in one pass)
- No blockers but >5 important → `fix-blockers-then-ship` (treat important as soft-blockers when they accumulate)
- Otherwise → `ship`

## Notes for the orchestrating agent

- Run the six subagents in a single message with six parallel Agent tool-use blocks. Do not serialize.
- If the diff is empty (HEAD matches base), say so and stop. Don't spin up agents.
- If `git` is not available or the cwd isn't a repo, say so and stop.
- Do not save findings to disk. Print them to chat; the user iterates from there.
- This skill is invoked via `/local-review`. The slash form is the canonical entry point.
- The rubric encodes one author's preferences. Adjust the sections under "Rubric" to match your team's standards.
