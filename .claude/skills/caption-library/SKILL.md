---
name: caption-library
description: Generate one on-brand caption + ~15 hashtags for a given slot and pillar. Reads brand/caption-pool.json. Enforces banned-word filter. Returns text. Invoked by produce-post; can also be called directly to refresh just the copy on an existing draft.
---

# caption-library

Pure copywriting. No MCPs. Reads config, writes text.

## Inputs

- `slot_id` (required) — e.g. `04-thu-kids-family`
- `pillar` (required) — one of `community_daily`, `member_spotlight`, `value_trust`, `kids_family`, `social_proof`, `leader_voice`
- `iso_week_number` (required) — integer 1–53, used for hashtag rotation
- `brief_override` (optional) — override text from the slot's `brief.md`

## Required tools

- `Read` only. Pure local.

## Steps

### 1. Read inputs

- Read `CLAUDE.md` (voice rules).
- Read `brand/caption-pool.json` (the editable config).
- Read the slot's row in `templates.json` (for `goal` field, useful as anchor).

### 2. Generate caption

Compose 1–2 lines that:

1. Match `pillar.tone_notes` from `caption-pool.json`
2. Reference the slot's `goal` from `templates.json` (e.g. parent conversion for `kids_family`)
3. **Do NOT contain any string from `banned_phrases`** — case-insensitive substring check
4. **Do NOT exceed 2 lines** (split by `\n` or sentence)
5. **Do NOT include hashtags** (those are separate)
6. **Do NOT include emojis** unless the brief explicitly asks for them
7. If `brief_override` is supplied, lean into it heavily — that's the user telling you what *this specific* post is about. Otherwise, draw inspiration from the pillar's `examples` (don't copy verbatim).

### 3. Banned-word filter (HARD)

- Lowercase the candidate caption.
- For each phrase in `banned_phrases`, check `phrase.lower() in caption.lower()`.
- If ANY match: regenerate. Try up to 3 times. After 3 failures, FAIL with the offending phrase surfaced and ask the user for guidance.

### 4. Generate hashtags

Use the `rotation_strategy` from `caption-pool.json`. Default values:
- 4 brand_anchors (always all)
- 5 from `bjj_general`
- 3 from `local`
- 3 from `by_pillar[<pillar>]`
- Total: 15

**Rotation formula** (avoids repeating the same set week-over-week, which IG flags):

For each rotated pool, with `n` items and `take` slots:
```
start_index = (iso_week_number * 7) mod n
selected = pool[start_index : start_index + take]
if not enough items remaining, wrap to start
```

This guarantees a different selection each week while staying in-pool.

### 5. Format outputs

- `caption_text`: final caption string, ready to paste
- `hashtags_list`: array of hashtag strings

If invoked by `produce-post`, return as structured data (don't write files — caller writes them). If invoked directly by the user on an existing draft, write to:
- `content/<iso_week>/<slot_id>/drafts/caption.md`
- `content/<iso_week>/<slot_id>/drafts/hashtags.md`

## Output (when called directly)

```
Caption (slot 04-thu-kids-family, week 2026-W19):

  Confidence. Listening. A safe place to learn.

Hashtags (15):
  #AllianceCobrinhaClark #BuiltTogether #BJJClark #JiuJitsuPampanga
  #JiuJitsuLifestyle #JiuJitsuFamily #TeamCobrinha #AllianceJiuJitsu #OssBrother
  #ClarkPampanga #BJJPhilippines #AngelesCity
  #KidsBJJ #BJJKids #DisciplineConfidenceFocus

Files written:
  content/2026-W19/04-thu-kids-family/drafts/caption.md
  content/2026-W19/04-thu-kids-family/drafts/hashtags.md
```

## Failure modes

| Failure | Surface to user |
|---------|-----------------|
| 3 banned-word retries fail | Show the offending phrase; ask user if it should be added/removed from `banned_phrases` or if a different pillar tone is needed. |
| Pillar key not in `caption-pool.json` | "Pillar '<key>' not configured — add it to brand/caption-pool.json." |
| Hashtag pool empty | "Pool '<name>' is empty in caption-pool.json — populate before regenerating." |

## Operator notes

- Edit `brand/caption-pool.json` freely. The skill re-reads it every run.
- If a particular pillar's voice keeps drifting wrong, expand the `examples` list — generation leans heavily on examples.
- If IG starts flagging hashtag repetition (rare but possible), increase `pool_size` for the rotated categories so the modulo math has more variety.
