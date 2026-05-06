---
name: weekly-status
description: Read-only dashboard of the current week. Lists each of the 7 slots with draft / approved / posted state. Run when user says "weekly status" or "what's the state of this week".
---

# weekly-status

Read-only. No external calls. Safe first thing to run when verifying the system is alive.

## Inputs

- **Week** (optional, defaults to current ISO week): e.g. `2026-W19`

## Required tools (run-time)

- `Read`, `Glob`, `Bash` only. No MCPs needed — this is fully local.

## Steps

### 1. Resolve week

- Default to current ISO week in Manila: `TZ='Asia/Manila' date +%G-W%V`.
- If `content/<year>-W<week>/` doesn't exist, REPORT: "No content folder for <iso_week> yet. Run `daily-check` to create it."
- Stop if missing.

### 2. Walk the 7 slots

For each slot in `templates.json`, check the matching folder under `content/<iso_week>/<slot.id>/`:

- `drafts/draft.json` → state has reached "draft"
- `approved/draft.json` (or any file in approved/) → state has reached "approved"
- Cross-reference with a `.posted` marker file or absence thereof — leave as `?` if not tracked yet

### 3. Build status table

| Slot | Day | Pillar | State | Drop time |
|------|-----|--------|-------|-----------|
| 01-mon-set-the-tone | MON | Community | `draft` / `approved` / `posted` / `missing` | 19:00 PHT |
| 02-tue-member-story | TUE | Spotlight | … | 19:00 PHT |
| ... | ... | ... | ... | ... |

State values:
- `missing` — `slot_dir` doesn't exist or `drafts/` is empty
- `draft` — has `drafts/draft.json`
- `approved` — has anything in `approved/`
- `posted` — has `.posted` marker file (created by post-approve when scheduling complete)

### 4. Summary line

Compute:
- `<approved_count> / 7 approved`
- `<posted_count> / 7 posted`
- `<days_remaining_in_week>`

### 5. Stories rollup (optional)

If `content/<iso_week>/stories/` exists, list each daily file: `<date>.json — <count> stories`. If a recent date has none, flag it.

## Output

```
Weekly status — <iso_week>

| Slot                      | Day | State    | Drop time |
|---------------------------|-----|----------|-----------|
| 01-mon-set-the-tone       | MON | approved | 19:00 PHT |
| 02-tue-member-story       | TUE | draft    | 19:00 PHT |
| 03-wed-value-trust        | WED | missing  | 19:00 PHT |
| ...                       | ... | ...      | ...       |

Approved: 1/7 · Posted: 0/7 · Days remaining: 5

STORIES THIS WEEK:
  2026-05-04 — 7 stories ✓
  2026-05-05 — 0 stories ✗ (today, run stories-pack)
```

## Failure modes

| Failure | Surface to user |
|---------|-----------------|
| Week folder missing | "No content folder for <iso_week> — run daily-check to create it." |
| `templates.json` malformed | Show the parse error; halt. |
