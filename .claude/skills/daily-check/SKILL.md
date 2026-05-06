---
name: daily-check
description: Morning entry point. Determines tomorrow's slot in Manila time and produces a draft for it via produce-post. Run when user says "daily check" or as part of an automated morning cron.
---

# daily-check

The "every morning" skill. One command, drafts ready by the time you finish coffee.

## Inputs

None. Computes everything from today's date (Manila / PHT, UTC+8).

## Required tools (run-time)

- All tools that `produce-post` needs (this skill delegates to it)
- `Bash` for date calculations

## Steps

### 1. Compute target date

- Get current date/time in Manila timezone: `TZ='Asia/Manila' date +%Y-%m-%d`
- **Target = tomorrow** (D-1 to D-0 workflow): `TZ='Asia/Manila' date -d 'tomorrow' +%Y-%m-%d`
- Compute target's day-of-week: `TZ='Asia/Manila' date -d 'tomorrow' +%u` → 1=Mon … 7=Sun

### 2. Map day-of-week to slot

| `%u` | Slot ID |
|------|---------|
| 1 | `01-mon-set-the-tone` |
| 2 | `02-tue-member-story` |
| 3 | `03-wed-value-trust` |
| 4 | `04-thu-kids-family` |
| 5 | `05-fri-community` |
| 6 | `06-sat-social-proof` |
| 7 | `07-sun-leader-voice` |

### 3. Compute target ISO week

- Target's ISO week: `TZ='Asia/Manila' date -d 'tomorrow' +%G-W%V`
- e.g. `2026-W19`

### 4. Check if draft already exists

- Look at `content/<iso_week>/<slot_id>/drafts/draft.json`.
- If it exists, REPORT: "Draft for tomorrow's slot (<slot.day> <slot.name>) already exists. Edit URL: <canva_edit_url>. Re-run with `produce <slot-id> regenerate` if you want a fresh draft."
- Stop here. Don't regenerate silently.

### 5. Run produce-post

- If no draft exists, invoke `produce-post` with `slot_id` and `iso_week`.
- Wait for it to complete.
- Surface its output back to the user.

### 6. Optional: catch up on today

- After tomorrow's slot is handled, check today's slot too.
- If today's draft exists but is still in `drafts/` (not yet `approved/`), remind: "TODAY's slot (<slot.day> <slot.name>) is still in drafts. Drop time is <slot.drop_time_pht> PHT. Approve and post when ready."

### 7. Optional: stories nudge

If today's `content/<iso_week>/stories/<today>.json` doesn't exist, remind: "Stories pack for today not yet generated. Run `stories-pack` to produce 5–10 daily stories — these are non-negotiable per CLAUDE.md."

## Output

A single status block:

```
Daily check — <today's PHT date>

TOMORROW: <slot.day> <slot.name> (<slot_id>)
  Status: <created | already exists>
  Canva: <edit_url>
  Caption: <first line>...
  Path: content/<iso_week>/<slot_id>/

TODAY: <slot.day> <slot.name>
  Status: <draft | approved | posted | missing>

STORIES TODAY: <count generated> / 5–10 target

Next nudge: <action item>
```

## Failure modes

Inherits all `produce-post` failure modes. Adds:

| Failure | Surface to user |
|---------|-----------------|
| `date` command unavailable on system | Fall back to JS-based date math; surface to user as a warning. |
| Slot ID lookup fails | Inspect `templates.json` directly — there should be exactly 7 slots with day fields. |

## Operator notes

- Run this **once per morning**, ~9–10 AM Manila. That gives you ~10 hours to review, polish, and approve before the 7 PM PHT drop.
- If you skip a day, the next day's run won't auto-catch-up. Handle missed days manually by invoking `produce-post <slot-id>` directly.
- For full automation, point a Windows Task Scheduler / system cron at this command. (Outside the scope of this skill — a future Step 8.)
