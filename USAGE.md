# Token usage by phase

One phase = one Claude Code session (see PROMPTS.md), so session totals map onto phases.
Numbers come from `ccusage`, which reads Claude Code's local session logs in
`~/.claude/projects/`.

Log a phase right after it passes its Definition of Done, before starting the next one:

    .\scripts\log-usage.ps1 "Phase 1"

Then commit the updated file:

    git add USAGE.md && git commit -m "chore: log phase usage" && git push

Note on cost: the dollar figure is an estimate computed locally from token counts. On a
Max plan it is NOT a bill - usage is included in the subscription. It is here only as a
rough sense of relative phase weight.

| Phase | Date | Models | Input | Output | Cache read | Cache write | Total tokens | Est. cost |
|---|---|---|---|---|---|---|---|---|