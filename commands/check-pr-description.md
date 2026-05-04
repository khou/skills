---
description: Audit a PR description for conciseness and reviewer-focus, tighten it
---

Audit a PR description against the actual diff and tighten it. Run before `gh pr create` or against an existing PR.

1. **Fetch.** If user passed a PR number (or branch has an open PR), get the body with `gh pr view <num> --json body,title` and the diff with `gh pr diff <num>`. Otherwise the user pasted a draft in chat — diff is `git diff <base>...HEAD`. Read both fully, not just file lists.

2. **Audit.** Cross-check every factual claim against the diff. Cut anything that isn't load-bearing for a reviewer reading the description with the diff in front of them:
   - iteration narration ("first commit", "after discussion", "second-pass cleanup")
   - stale or untrue claims (iteration drift is common)
   - per-file links into the branch (`[file](.../blob/<branch>/...)` — diff lists files already)
   - padding (duplicate "what's new" + "what's updated" sections, marketing language, the same fact restated three times)
   - speculative content (Q&As nobody asked, hypothetical edges, future work outside scope)

   Verify the essentials are there: one-line summary, *why* (most common gap), test plan. Right-size to the change.

3. **Apply.** Produce the tightened version. Report: short bullets of what you cut, the new body in a fence, and the action — `gh pr edit <num> --body "..."` for an existing PR (confirm with the user first, it's reviewer-visible) or "ready for `gh pr create`" for a draft.

If the description is already fine, say so. Don't invent improvements to justify the run.
