---
name: post-approve
description: Move a slot's draft into approved state, render the final paste-ready post text, and surface a drop-time reminder. Run when user says "approve <slot-id>" after Jeff/Adrian/Ram have signed off on the Canva draft.
---

# post-approve

The handoff between draft and live. Doesn't post to Instagram (no IG MCP yet) — it preps everything so Vhinz can post by hand at the right time.

## Inputs

- `slot_id` (required) — e.g. `04-thu-kids-family`
- `iso_week` (optional, defaults to current ISO week in PHT)
- `caption_edits` (optional) — if provided, overrides the existing caption.md before approval (lets you tweak copy without re-running caption-library)

## Required tools

- `Read`, `Write`, `Edit`, `Bash`. No MCPs needed.

## Steps

### 1. Resolve paths

- `slot_dir = content/<iso_week>/<slot_id>/`
- `drafts_dir = slot_dir/drafts/`
- `approved_dir = slot_dir/approved/`

### 2. Verify draft exists

- Must have `drafts/draft.json`, `drafts/caption.md`, `drafts/hashtags.md`.
- If anything missing, FAIL with: "Draft incomplete for <slot_id> — missing <file>. Run `produce-post <slot_id>` first."

### 3. Apply caption edits (if any)

If `caption_edits` was supplied:

- Re-run banned-phrase filter from `brand/caption-pool.json` against the edits.
- If clean, overwrite `drafts/caption.md` with the edits.
- If dirty, FAIL with the offending phrase surfaced — don't silently strip.

### 4. Build paste-ready post text

Compose `approved/post.md`:

```
<caption from caption.md>

.
.
.

<all hashtags from hashtags.md, space-separated, single line>
```

The three `.` lines on their own create the IG-style "scroll past" gap before hashtags. (Standard convention.)

### 5. Copy draft data into approved/

- Copy `drafts/draft.json` to `approved/draft.json`, with these field updates:
  - `status`: `"approved"`
  - `approved_at_utc`: current ISO8601
  - `approved_caption_path`: `approved/post.md`

### 6. Compute drop-time reminder

- Read `slot.drop_time_pht` from `templates.json` (default `19:00`).
- Compute the target datetime: target date (slot's day in current `iso_week`) at the drop time PHT.
- If target is in the past (we're approving same-day after the drop window), flag it: "DROP WINDOW ALREADY PASSED — post immediately or roll to next week."
- Else compute `time_until_drop_minutes`.

### 7. Write a `.posted` placeholder check

Don't write `.posted` yet. That marker is created when the post goes live. For now, write `approved/.pending` containing the planned drop time — `weekly-status` reads this for the dashboard.

### 8. Report to user

```
Approved — <slot.day> <slot.name> (<slot_id>, week <iso_week>)

Canva edit URL: <url>
Drop time:       <slot.day> 19:00 PHT (<absolute_datetime>)
Time until drop: <X hours Y minutes> | OR | DROP WINDOW PASSED

Paste-ready post:
  content/<iso_week>/<slot_id>/approved/post.md

Next steps for Vhinz:
  1. Open IG/Meta Business Suite at <drop_time_pht> PHT
  2. Upload the Canva-exported asset
  3. Paste post.md content as caption
  4. Publish
  5. Touch content/<iso_week>/<slot_id>/approved/.posted (or run `mark-posted <slot_id>`) so weekly-status reflects state
```

## Failure modes

| Failure | Surface to user |
|---------|-----------------|
| Draft files missing | Tell user which file; suggest re-running `produce-post`. |
| Caption edits hit banned phrase | Show the offending phrase; ask user to revise. |
| Drop window passed | Flag clearly — don't auto-roll to next week. Ask user. |
| Already approved | Ask: "Already approved at <timestamp>. Re-approve (overwrites paste-ready post.md)?" |

## Operator notes

- This skill assumes manual posting. When/if you wire up an IG/Meta Business Suite MCP later, add a step 8b that calls schedule-post with the drop time. The rest of the pipeline doesn't change.
- The `post.md` format is paste-ready for IG specifically. For other platforms (FB Page, TikTok), add a separate skill that re-formats the same approved data — don't change post-approve.
- If captions need a second sign-off from Cobrinha (the brand owner), add an intermediate `caption-approve` skill before this one. Current pipeline assumes Vinz + Jeff/Adrian/Ram approve the *visual* and Vhinz handles the copy.
