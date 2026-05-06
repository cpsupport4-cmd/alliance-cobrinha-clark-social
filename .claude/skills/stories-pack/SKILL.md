---
name: stories-pack
description: Generate a daily pack of 5–10 IG stories from recent Drive assets. Stories are non-negotiable per the Clark plan — this is where conversions happen. Run when user says "stories pack" or as part of daily-check.
---

# stories-pack

Bulk-light-touch counterpart to `produce-post`. Stories don't go through Canva — they're raw assets with a one-line text overlay suggestion. Less polish, much higher cadence.

## Inputs

- **Date** (optional, defaults to today PHT): `YYYY-MM-DD`
- **Count** (optional, defaults to 7, range 5–10)

## Required tools (run-time)

- Google Drive MCP: `search_files`, `get_file_metadata`
- File system: `Read`, `Write`, `Bash`

## Steps

### 1. Resolve date and count

- Default date: `TZ='Asia/Manila' date +%Y-%m-%d`.
- Default count: 7.
- Resolve target ISO week: `TZ='Asia/Manila' date -d <date> +%G-W%V`.

### 2. Pull recent assets across all pillars

For stories, we want VARIETY across pillars in a single day's pack. Strategy:

- Pull 2–3 most recently modified items from EACH of the 6 Drive subfolders in `templates.json → drive.subfolders`.
- Combine into one candidate list.
- Sort all candidates by `modifiedTime desc`.
- Take the top `count` items.

This guarantees the day's stories span community + member + coach + kids + events + leader voice, instead of all coming from one bin.

### 3. Verify each is link-shareable

- For each candidate, call `get_file_metadata` and check sharing.
- If any candidate isn't link-shared, either skip it OR (if it would drop count below 5) FAIL with "Only <n> of the day's candidates are link-shared. Drive sharing must be 'Anyone with the link → Viewer' on the parent."

### 4. Generate one-line overlay per asset

For each selected asset, produce a story-overlay caption matching its source pillar:

- **Community** → "Mat is open." / "Showing up." / "Tuesday training."
- **Member Spotlights** → "<First name>'s journey." / "Three months in."
- **Coach-Student** → "Posture beats power." / "Today's drill."
- **Kids & Family** → "Confidence in motion." / "Discipline starts here."
- **Events / Group Photos** → "Team training." / "Built together."
- **Leader Voice** → "What we're building." / "Built together."

Keep overlays under 5 words. Apply the same banned-phrase filter from `brand/caption-pool.json`.

### 5. Write the day's pack

Write to `content/<iso_week>/stories/<date>.json`:

```json
{
  "date": "2026-05-06",
  "iso_week": "2026-W19",
  "count": 7,
  "generated_at_utc": "<iso8601>",
  "stories": [
    {
      "order": 1,
      "drive_file_id": "<id>",
      "drive_file_name": "<name>",
      "source_pillar": "community_daily",
      "overlay_text": "Mat is open.",
      "drive_view_url": "https://drive.google.com/file/d/<id>/view"
    },
    ...
  ],
  "post_window_pht": ["07:00–09:00", "12:00–13:00", "19:00–22:00"]
}
```

Also write `content/<iso_week>/stories/<date>.md` — a human-readable summary Vhinz can use as a posting checklist:

```
Stories — 2026-05-06 (Tuesday)

[ ] 1. community_daily — "Mat is open."
       ./IMG_4520.JPG (Drive: <link>)

[ ] 2. coach_student — "Posture beats power."
       ./Coach demo.mov (Drive: <link>)

...

Suggested post windows (PHT):
  Morning:  7–9 AM
  Midday:   12–1 PM
  Evening:  7–10 PM
```

### 6. Report

Print the count + list of pillars covered + path to the markdown file.

## Output

```
Stories pack — 2026-05-06 (Tue, week 2026-W19)

7 stories selected across pillars:
  community_daily x 2
  coach_student x 1
  kids_family x 1
  member_spotlight x 1
  events_groups x 1
  leader_voice x 1

Posting checklist: content/2026-W19/stories/2026-05-06.md
Raw data:          content/2026-W19/stories/2026-05-06.json
```

## Failure modes

| Failure | Surface to user |
|---------|-----------------|
| Fewer than 5 link-shared candidates | "Only <n> of today's candidates are link-shared. Fix Drive sharing or drop more recent assets." |
| Drive subfolder missing | "Subfolder '<name>' not found — check templates.json mapping." |
| Already generated for this date | Ask: "Stories pack for <date> already exists. Append (add more) / Replace (regenerate fresh) / Cancel?" |

## Operator notes

- Stories are RAW. The point isn't polish — it's cadence. 5–10 a day, every day, even on weekends.
- This skill DOESN'T touch Canva. Vhinz posts directly from phone using Drive (download → IG story upload → text overlay using IG's own tools).
- If you want Canva-templated story frames later, that's a future skill (`stories-pack-canva`). Don't build it before you've confirmed the cadence is sustainable raw.
