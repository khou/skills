---
description: Iteratively hunt for inconsistencies across the entire codebase and fix them
---

Hunt for inconsistencies across the entire codebase and fix them. Loop until a full pass finds nothing — do not stop after one pass.

## Establish scope

The scope is the **entire repository**, not just recent changes. Start by orienting yourself:

- List the top-level layout (`ls`, root README, main subdirectories).
- Identify the main subsystems / packages / language ecosystems present.
- If the user passed an argument naming a directory, subsystem, or theme (e.g. `/check-consistency customers/`), narrow to that — but still treat the entire scoped area as fair game, not just diffs within it.

For large repos, partition the work by subsystem and check one slice at a time so each pass can be thorough. Don't try to load everything at once.

## On each pass, check for

- **Naming drift** — multiple names for the same concept coexisting (e.g. `customer` vs `tenant`, old and new module names both present). Pick the canonical one and unify, or flag if you can't tell which is canonical.
- **Signature drift** — function/type/schema definitions whose call sites, mocks, fixtures, or tests expect a different shape.
- **Doc drift** — READMEs, comments, docstrings, CHANGELOGs, runbooks, and examples that describe behavior the code no longer has. Removed features still mentioned. Stale command examples or paths.
- **Cross-file invariants** — constants duplicated across files that have diverged, enums mirrored in multiple languages that have diverged, producer/consumer schemas that don't match, version pins that should agree across files.
- **Dead references** — imports, exports, types, vars, or files referenced but no longer present. Symbols defined but never used. Dangling links in docs.
- **Partial migrations** — a new pattern adopted in most places but the old pattern still present in others. Half-renamed files or directories. Feature flags long past their cleanup date.
- **Test/code mismatch** — tests asserting behavior the code no longer has, fixtures with stale field names, snapshots that don't match current output.
- **Config/code mismatch** — settings, schemas, migrations, types, or generated code that should have been regenerated and weren't.

## Method

1. Orient yourself in the repo (layout, subsystems, conventions). Honor any user-supplied scope narrowing.
2. Pick a subsystem or theme to check this pass. Grep for the patterns above — paired/coupled symbols, doc references, version pins, duplicated constants, etc. Lean on `grep`/`rg` heavily; this is a search-and-cross-reference task.
3. Fix what you find. For ambiguous cases (e.g. you can't tell which name is canonical), surface the question rather than picking blindly.
4. Run another pass — either widening to a new subsystem or re-checking the area you just touched. Keep going until a full pass across the scope finds nothing.
5. Report: areas examined, what you checked, what you fixed, what you flagged for human judgment, and confirm the final pass was clean.

Be thorough. A single missed reference is the whole point of this command — do not declare done early. If the codebase is large enough that a truly exhaustive sweep isn't realistic in one session, say so explicitly and describe what you did and didn't cover.
