---
name: caption-library
description: Generate text in one of two modes — (1) "caption" mode produces an Instagram post caption + ~15 hashtags; (2) "overlay" mode produces shape-constrained text for replacing a master template's overlay during produce-post. Both modes share pillar tones, banned-phrase filter, and the same caption-pool.json config.
---

# caption-library

Pure copywriting. No MCPs. Reads config, writes text. Two modes.

## Inputs

- `slot_id` (required) — e.g. `04-thu-kids-family`
- `pillar` (required) — one of `community_daily`, `member_spotlight`, `value_trust`, `kids_family`, `social_proof`, `leader_voice`
- `iso_week_number` (required) — integer 1–53, used for hashtag rotation
- `mode` (optional, defaults to `"caption"`) — `"caption"` for IG post caption + hashtags; `"overlay"` for on-design text replacement
- `brief_override` (optional) — override text from the slot's `brief.md`
- `concept` (optional) — short description of the day's concept ("Santi's stripe ceremony", "Monday after long weekend", "kids learning closed guard") — drives both modes
- `master_text_shape` (required when `mode == "overlay"`) — describes the shape of the master's existing text so the replacement fits:
  ```json
  {
    "lines": 3,
    "max_chars_per_line": 28,
    "current_text": "Confidence\nListening\nSAFE PLACE TO LEARN",
    "current_style_notes": "Title-case first two lines, all-caps third line; serif"
  }
  ```
  This comes from `produce-post`'s `start-editing-transaction` response (read element's current text + dimensions).

## Required tools

- `Read` only. Pure local.

## Steps

### 1. Read inputs

- Read `CLAUDE.md` (voice rules).
- Read `brand/caption-pool.json` (the editable config).
- Read the slot's row in `templates.json` (for `goal` field, useful as anchor).

### 2. Branch on mode

Read `mode` input. Default is `"caption"`.

- **`mode: "caption"`** → continue to Step 2A (Instagram post caption generation)
- **`mode: "overlay"`** → jump to Step 2B (master-overlay text generation)

### 2A. Generate IG post caption (mode: caption)

Compose 1–2 lines that:

1. Match `pillar.tone_notes` from `caption-pool.json`
2. Reference the slot's `goal` from `templates.json` (e.g. parent conversion for `kids_family`)
3. **Do NOT contain any string from `banned_phrases`** — case-insensitive substring check
4. **Do NOT exceed 2 lines** (split by `\n` or sentence)
5. **Do NOT include hashtags** (those are separate)
6. **Do NOT include emojis** unless the brief explicitly asks for them
7. If `brief_override` is supplied, lean into it heavily — that's the user telling you what *this specific* post is about. Otherwise, draw inspiration from the pillar's `examples` (don't copy verbatim).
8. If `concept` is supplied, the caption should reference or extend the concept without literally repeating it. The IG caption complements the overlay; they shouldn't say the same thing.

### 2B. Generate master-overlay text (mode: overlay)

The output of this mode REPLACES the master template's existing overlay text in `produce-post`. Goal: same layout, same typography zone, **new text aligned with the day's concept**.

Compose new overlay text that:

1. **Matches the master's shape** as defined in `master_text_shape`:
   - Same number of lines (don't add or drop a line — the master's typography is calibrated for that count)
   - Each line at most `max_chars_per_line` characters (including spaces) — measure carefully; longer lines will wrap or overflow the typography zone
   - Preserve the case pattern from `current_style_notes` (if master is mixed case, output mixed case; if master is all-caps, output all-caps)
2. **Matches `pillar.tone_notes`** — same voice rules as caption mode
3. **Is concept-driven, not template-recycled.** If `concept` or `brief_override` is provided, the overlay must reference it. If neither is provided, generate from the pillar tone + slot goal — but never just reuse the master's `current_text` verbatim. The master's text is a SHAPE reference, not a content default.
4. **Passes banned-phrase filter** — same hard check as Step 3
5. **No emojis, no hashtags, no @handles** in overlay text. The design carries the brand presence; overlay text is content.
6. **No URLs, no calls-to-action like "click", "DM us", "book"** — banned for overlays specifically (a stricter superset of the global banned list). Overlay text should never sound like an ad.

If the master text is part of the brand's canonical signature (e.g. FRI's "TRAIN • GROW • LAUGH" or a tagline the team uses every week) AND the operator wants to preserve it, they opt in via `brief.md` `keep_master_overlay: true`. In that case, this mode SHOULD NOT run — `produce-post` skips the overlay generation step entirely. Default behavior is: regenerate.

After generation, return as structured data:

```json
{
  "mode": "overlay",
  "overlay_text": "<new text with line breaks>",
  "overlay_lines": ["line1", "line2", "line3"],
  "concept_referenced": "<what the operator gave or what the skill inferred>",
  "kept_master": false,
  "alternatives": ["<2-3 alternative phrasings the operator can swap in via brief.md>"]
}
```

The `alternatives` field gives Vinz options to A/B test in Canva without re-running the skill.

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
