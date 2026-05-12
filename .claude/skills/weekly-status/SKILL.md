---
name: weekly-status
description: Read-only dashboard of the current week. Runs scripts/weekly-status.sh which does the file-tree walk in pure bash for token efficiency. Lists each of the 7 slots with draft / approved / posted state plus a today's-nudge. Run when user says "weekly status" or "what's the state of this week".
---

# weekly-status

Pure local read-only dashboard. **Delegates to `scripts/weekly-status.sh`** for token efficiency — that script does the file-tree walk in bash in one invocation instead of Claude orchestrating multiple Read calls. Saves ~80-90% of the tokens this skill used to cost.

## Repo policy

This skill does NOT touch git. It only reads.

## Inputs

- **Week** (optional, defaults to current ISO week in Manila): e.g. `2026-W19`
- **`--quiet`** flag (optional): just the status table, no today's-nudge / stories-nudge

## Required tools

- `Bash` only. No `Read`, no MCPs, no `Glob`, no walking-the-tree-manually. The script does everything.

## Steps

1. Run the script:
   ```bash
   bash scripts/weekly-status.sh [<iso_week>] [--quiet]
   ```
2. Print the output verbatim to the user. **Do not summarize, paraphrase, or "improve."** The script's output is the canonical format.
3. If the user asked about a state element not surfaced by the script (e.g. "what's in the W19 SAT draft specifically?"), THEN do a targeted `Read` on that one file. Don't pre-fetch.

## Output (verbatim from the script)

```
Weekly status — <iso_week>
Today: <day> <date> PHT (day N of 7)

| Slot                      | Day | State    | Drop (PHT) |
|---------------------------|-----|----------|------------|
| 01-mon-set-the-tone       | MON | draft    | 19:00      |
| 02-tue-member-story       | TUE | missing  | 19:00      | *TODAY*
| ...

Drafted: X/7 · Approved: X/7 · Posted: X/7 · Missing: X/7
Stories packs this week: N days covered (target: 7)

TODAY'S NUDGE: <slot> has no draft. Drop is at 19:00 PHT. Run 'produce-post <slot>'.
STORIES NUDGE: Stories pack for today not yet generated. Run 'stories-pack'.
```

## Failure modes

| Failure | Surface to user |
|---------|-----------------|
| Script not found | "scripts/weekly-status.sh not found. Has the repo been cloned with all files? Re-run `git pull origin main`." |
| Week folder missing | The script already handles this: outputs "No content folder for `<week>` yet." Skill just prints it. |
| Script returns non-zero | Print the error verbatim; the script's `set -e` strategy is conservative, so non-zero is meaningful. |

## Why this design

`weekly-status` used to walk the content tree via individual Read/Bash tool calls + reasoning. That cost ~5-10k tokens per check, mostly burned on Claude orchestrating the walk. For a skill that the operator runs multiple times a day, that's expensive over a week.

The script does the same work in pure bash in ~50ms and ~30 lines of output. The skill becomes "invoke the script and print its output" — ~500 tokens total instead of ~10,000.

If you need to add new state checks later (e.g. tracking video vs image format, capturing approval timestamps), modify `scripts/weekly-status.sh` directly. The SKILL.md doesn't need updating; it just delegates.
