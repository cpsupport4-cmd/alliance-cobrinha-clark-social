---
name: produce-post
description: Produce one Canva draft + caption + hashtags for a single slot in the current week. Pulls newest matching asset from Drive, generates Canva design with brand kit, saves draft URL and copy to repo. Run when user says "produce <slot-id> [for this week]" or as part of daily-check.
---

# produce-post

The workhorse skill. Takes one slot ID, produces one complete review-ready package.

## Inputs

- **Slot ID** (required): one of `01-mon-set-the-tone`, `02-tue-member-story`, `03-wed-value-trust`, `04-thu-kids-family`, `05-fri-community`, `06-sat-social-proof`, `07-sun-leader-voice`
- **Week** (optional, defaults to current ISO week): e.g. `2026-W19`

## Required tools (run-time)

- Canva MCP: `generate-design`, `create-design-from-candidate`, `upload-asset-from-url`, `move-design-to-folder`, `list-brand-kits`, `create-folder` (or equivalents)
- Google Drive MCP: `search_files`, `get_file_metadata`
- File system: `Read`, `Write`, `Edit`, `Bash`

## Steps

### 1. Read context

- Read `CLAUDE.md` (strategy + voice).
- Read `templates.json` and find the slot config matching the slot ID.
- Read `brand/caption-pool.json` (for caption-library invocation later).

### 2. Resolve week folder

- Compute current ISO week if not supplied: `<year>-W<week>` (e.g. `2026-W19`).
- If `content/<year>-W<week>/` doesn't exist, copy `content/_template/` to it.
- Define `slot_dir = content/<year>-W<week>/<slot-id>/`.
- If `slot_dir/drafts/draft.json` already exists, ASK the user: "Draft already exists for this slot. Regenerate (y/n)?" Default: stop. Don't silently overwrite.

### 3. Read brief override

- If `slot_dir/brief.md` has content beyond the template default, capture it as `brief_override`. Use it to weight caption generation in step 8.
- If empty / template-default, no override.

### 4. Find newest Drive asset

- Use Drive `search_files` to list contents of folder named exactly `<slot.drive_subfolder>` inside parent folder ID `1wCB3ZwUhdMGCXUQvC48bUsp6aWcjL5_L`.
- Filter by `slot.prefers`:
  - `image` → `mimeType contains 'image/'`
  - `video` → `mimeType contains 'video/'`
  - `either` → no filter
- Sort by `modifiedTime desc`, pick the first.
- If no files match, FAIL with: `No assets found in Drive subfolder "<slot.drive_subfolder>" matching prefers="<slot.prefers>". Ask Ram or Steph to drop a file in this folder, then re-run.`

### 5. Verify file is link-shareable

- Call `get_file_metadata` with `fields=permissions,name,mimeType`.
- If permissions don't include `anyone with link viewer` (or higher), FAIL with: `File "<filename>" is not link-shared. Right-click in Drive → Share → "Anyone with the link → Viewer". Then re-run.`

### 6. Upload asset to Canva

- For images, build URL: `https://lh3.googleusercontent.com/d/<fileId>=w2000`. (Drive's `uc?id=X&export=download` returns the interstitial page; the `lh3` host serves direct content.)
- For videos, use the Drive `webContentLink` from metadata.
- Call Canva `upload-asset-from-url`. Capture the returned `asset_id`.
- If upload fails with non-200 from the URL, retry once with the alternate URL pattern. If still failing, FAIL with the exact URL that didn't work and ask the user to verify Drive sharing.

### 7. Generate Canva design

- Call Canva `list-brand-kits`. Find the Alliance Cobrinha Clark brand kit (match by name or use cached ID from `templates.json → canva.brand_kit_id_resolved`).
- Call Canva `generate-design` with:
  - `brand_kit_id`: resolved above
  - `prompt`: the slot's `generation_prompt` from `templates.json`, with `brief_override` appended if present
  - `assets`: `[asset_id]`
  - `dimensions`: from `slot.dimensions`
- Receive 4 candidates.

### 8. Materialize first candidate

- Call `create-design-from-candidate` on candidate index 0.
- Capture `design_id` and `edit_url`.
- Find or create Canva folder named `Alliance Cobrinha Clark` (cache ID in `templates.json → canva.destination_folder_id_resolved` after first creation). Move design into it.

### 9. Generate caption + hashtags

- Invoke the `caption-library` skill with:
  - `slot_id`
  - `pillar` = `slot.pillar`
  - `iso_week` = current ISO week number (integer, used for hashtag rotation)
  - `brief_override` if present
- Receive `caption_text` (1–2 lines, banned-word verified) and `hashtags_list` (~15 tags).

### 10. Write outputs to repo

Write three files into `slot_dir/drafts/`:

- `draft.json`:
  ```json
  {
    "slot_id": "<slot.id>",
    "iso_week": "<year>-W<week>",
    "generated_at_utc": "<iso8601>",
    "canva_design_id": "<design_id>",
    "canva_edit_url": "<edit_url>",
    "source_asset": {
      "drive_file_id": "<fileId>",
      "drive_file_name": "<filename>",
      "canva_asset_id": "<asset_id>"
    },
    "brief_override_used": "<text or null>",
    "status": "draft"
  }
  ```
- `caption.md`: just the caption text (no frontmatter, ready to copy/paste)
- `hashtags.md`: hashtags one per line OR space-separated single line — match what IG paste-friendly looks like

### 11. Report to user

Surface back:

- Slot + week
- Canva edit URL (clickable)
- Caption preview
- First 5 hashtags + total count
- File path of the slot dir for further edits

## Failure modes

| Failure | Surface to user |
|---------|-----------------|
| No Drive subfolder match | "Drive subfolder '<name>' not found. Verify exact folder name in Drive matches templates.json." |
| No assets in subfolder | "No <prefers> assets in '<name>'. Ram/Steph need to drop one." |
| File not link-shared | "File not link-shared — fix sharing in Drive then re-run." |
| Canva URL fetch fails | Show exact URL that returned non-200; suggest alternate URL pattern check. |
| Brand kit not found | "Alliance Cobrinha Clark brand kit not in this Canva account. Confirm the brand kit URL in templates.json points to a kit accessible to the connected Canva account." |
| `generate-design` returns 0 candidates | "Canva returned no candidates — usually a transient. Re-run; if it fails twice, simplify the generation_prompt in templates.json." |
| Existing draft, user says no | Stop cleanly. Don't write anything. Report path to existing draft. |

## Notes for the operator

- Test with image-based slots first (`04-thu-kids-family` or `05-fri-community`). Video slots have an extra Drive URL edge case (`webContentLink` vs `lh3`).
- After the first successful run, update `templates.json → canva.brand_kit_id_resolved` and `canva.destination_folder_id_resolved` so subsequent runs skip the lookup.
- After 2–3 weeks of drafts, observe what your brand kit actually produces and update `templates.json → theme_signature`. Then rewrite each slot's `generation_prompt` to lock to that theme (LA pattern — see the original LA conversation transcript referenced in `docs/strategy.md`).
