# Token usage by phase

One phase = one Claude Code session (see PROMPTS.md), so session totals map onto phases.
Numbers come from `ccusage`, which reads Claude Code's local session logs in
`~/.claude/projects/`.

Log a phase right after it passes its Definition of Done, before starting the next one:

    .\scripts\log-usage.ps1 "Phase 1"

Then commit the updated file:

    git add USAGE.md; git commit -m "chore: log phase usage"; git push

Note on cost: the dollar figure is an estimate computed locally from token counts. On a
Max plan it is NOT a bill - usage is included in the subscription. It is here only as a
rough sense of relative phase weight.

Phase 0 spanned several sessions; its row reflects the largest one only. From Phase 1 on,
one phase = one session, so the numbers are accurate.

| Phase | Date | Models | Input | Output | Cache read | Cache write | Total tokens | Est. cost |
|---|---|---|---|---|---|---|---|---|
| Phase 0 | 2026-07-24 | sonnet-5, opus-4-8 | 3,773 | 72,657 | 5,029,754 | 198,557 | 5,304,741 | $5.34 |
| Phase 1 | 2026-07-24 | sonnet-5 | 142 | 73,553 | 10,013,913 | 165,268 | 10,252,876 | $3.4 |
| Phase 2 | 2026-07-24 | sonnet-5 | 28,455 | 169,659 | 21,850,056 | 424,238 | 22,472,408 | $7.82 |
