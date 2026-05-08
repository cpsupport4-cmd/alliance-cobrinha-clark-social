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

### 7. Branch on slot mode

Read `slot.mode` from `templates.json`. Two paths:

#### 7A. `mode: "registered-master"` — Mon-Fri

This slot has a master template page in `slot.master_template`. **Path validated 2026-05-08** against For Clark V2 (DAHJC_QKr0U) page 5 — every tool call below is confirmed working with the current Canva MCP.

1. **Read master config.** From `slot.master_template`: `design_id` (e.g. `DAHJC_QKr0U`), `page_index` (1–N), and `default_overlay_text`.

2. **Duplicate master page into a new design** — single tool call:
   ```
   merge-designs(
     type: "create_new_design",
     title: "<slot.day>-<iso_week>-<slug>",      // e.g. "FRI-2026-W19-train-grow-laugh"
     operations: [{
       type: "insert_pages",
       source: {
         type: "design",
         design_id: <master.design_id>,
         page_numbers: [<master.page_index>]      // single-element array — only this page
       }
     }]
   )
   ```
   Response: `job.result.design.id` is the new working design ID. `urls.edit_url` is the editable URL. `page_count` should be 1.

3. **Open editing transaction** on the new design:
   ```
   start-editing-transaction(design_id: <new_design_id>)
   ```
   Response includes:
   - `transaction_id` — keep for subsequent operations
   - `fills[]` — array of image/video fills with `element_id` and current `asset_id`
   - `richtexts[]` — text elements with `element_id`, current text content, and position/dimension
   - `pages[]` — page metadata; required for `perform-editing-operations`

4. **Identify the swap targets in the response:**
   - **Photo element** — typically the only image fill: `fills[0]` where `type === "image"`. Capture `fills[0].element_id`.
   - **Main overlay text** — the WIDEST text element in `richtexts[]` (decorative bullet separators like `·` show up as narrow text elements; ignore them). Heuristic: pick the `richtexts[i]` whose `containerElement.dimension.width` is largest. Capture its `element_id`.

5. **Determine the new overlay text:**
   - If `slot.brief.md` contains a `force_overlay:` or operator-specified phrase from `slot.master_template.approved_alternative_overlays`, use it.
   - Else use `slot.master_template.default_overlay_text` (e.g. `TRAIN • GROW • LAUGH` for FRI). Keeping the default is the consistent-week-over-week behavior; that's the point of registered-master mode.
   - If the new text equals the current text, skip the text replacement operation entirely (saves a write).

6. **Apply the swaps** in a single `perform-editing-operations` call:
   ```
   perform-editing-operations(
     transaction_id: <transaction_id>,
     page_index: 1,
     pages: <pages array from start-editing-transaction response>,
     operations: [
       { type: "update_fill",
         element_id: <photo_element_id>,
         asset_type: "image",
         asset_id: <newly_uploaded_canva_asset_id from Step 6>,
         alt_text: "<descriptive alt text for the new photo>"
       },
       // Only include this if text needs to change (see Step 5):
       { type: "replace_text",
         element_id: <text_element_id>,
         text: "<new_overlay_text>"
       }
     ]
   )
   ```

7. **Commit** to save:
   ```
   commit-editing-transaction(transaction_id: <transaction_id>)
   ```

8. **Move** the new design to the Alliance Clark folder:
   ```
   move-item-to-folder(item_id: <new_design_id>, folder_id: "FAHFlJsvwyo")
   ```

9. Capture the final `design_id` and `edit_url` for the report. Done — registered-master path complete, identical layout to master with new photo and (optionally) new overlay text.

**Fallback contract.** Fall back to 7B (fresh-generate) ONLY if a tool returns an error — not because the path looks complex. The 7A flow above is proven; an unexpected error means something genuinely broke and merits surfacing to the operator. If 7A succeeds, do NOT also run 7B.

**Transaction TTL — important.** Editing transactions expire if too much time passes between `start-editing-transaction`, `perform-editing-operations`, and `commit-editing-transaction`. Validated 2026-05-08 against design DAHJEaANkc4: a transaction returned "transaction not found" on commit when minutes elapsed between operations (likely due to internal TTL plus interleaved non-Canva tool calls). Mitigation: **keep steps 3–7 in tight succession with no intervening non-Canva work.** If a commit fails with "transaction not found":

1. Open a fresh transaction with `start-editing-transaction`
2. Re-apply the same operations via `perform-editing-operations`
3. Commit immediately

The retry pattern is inexpensive — the duplicated design from step 2 still exists; only the in-flight edit state is lost. Don't restart from `merge-designs`.

#### 7B. `mode: "fresh-generate"` — Sat-Sun (and fallbacks from 7A)

- Call Canva `list-brand-kits` if `templates.json → canva.brand_kit_id_resolved` is not yet cached. Find the Alliance Cobrinha Clark kit. Cache the ID.
- Call Canva `generate-design` with:
  - `brand_kit_id`: resolved above
  - `prompt`: the slot's `generation_prompt` from `templates.json` (or `fresh_generate_fallback_prompt` if this is a fallback from 7A), with `brief_override` appended if present
  - `assets`: `[asset_id]`
  - `dimensions`: from `slot.dimensions`
- Receive 4 candidates.
- Call `create-design-from-candidate` on candidate index 0.
- Capture `design_id` and `edit_url`.
- **Banned-phrase post-check (mandatory).** After the design is materialized, call `get-design-content(design_id, content_types: ["richtexts"])`. Aggregate all returned text. Lowercase it. For each phrase in `brand/caption-pool.json → banned_phrases`, check `phrase.lower() in design_text.lower()`.
  - If a banned phrase is detected:
    1. Try once: call `create-design-from-candidate` on a different candidate index (1, 2, or 3 from the original `generate-design` response). Re-run the post-check.
    2. If still hit OR no more candidates: FAIL with `"Generated design contains banned phrase '<phrase>' in its visible text. Canva's generate-design + brand kit ignored the prompt's banned-phrase instructions. Falling back to manual review — open the design URL and either edit the offending text in Canva, or re-run with a tighter generation_prompt that explicitly forbids the leaked phrase."` Do NOT auto-fall-back to a different generation strategy — surface the issue.
  - This check exists because the W19 FRI run (commit `0af2d40` aftermath) leaked "Join us:" into the design itself. The caption-library banned-phrase filter only covers `caption.md`; this check covers what `generate-design` puts INTO the visual.
- Move design into the `Alliance Clark` folder.

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
| `merge-designs` returns error (7A step 2) | Surface the error verbatim. Common causes: master design_id is wrong, master was deleted, page_numbers references a page that no longer exists. Halt — don't fall back. Confirm `templates.json → slots[N].master_template.design_id` and `page_index` are current. |
| `start-editing-transaction` fails on duplicated design (7A step 3) | Surface the error. The duplicate from step 2 succeeded, so the design exists; transaction failure is rare. May be a transient API issue — retry once before falling back. |
| Element ID detection ambiguous (7A step 4-5) | If `fills[]` has multiple image fills or `richtexts[]` has multiple wide text elements, the heuristic can pick wrong. Surface to operator: "Master page <N> has unexpected element structure (M image fills, N wide text elements). Inspect the master to confirm it has one hero photo and one main overlay text element. Skill picked element_id `<picked>` — operator can override via `--photo-element-id` and `--text-element-id` arguments." |
| Banned phrase in fresh-generate output (7B post-check) | "Generated design contains banned phrase '<phrase>' in its visible text. Tried regenerating from candidate index 1; still hit. Open the design URL and either edit the offending text in Canva, or re-run with a tighter generation_prompt." Halt — operator decides how to proceed. |
| Master template page not found at index | "Master design <id> doesn't have page <N>. Confirm For Clark V2 (DAHJC_QKr0U) page count and the master_template.page_index in templates.json." Halt — config mistake. |

## Notes for the operator

- Test with image-based slots first (`04-thu-kids-family` or `05-fri-community`). Video slots have an extra Drive URL edge case (`webContentLink` vs `lh3`).
- After the first successful run, update `templates.json → canva.brand_kit_id_resolved` and `canva.destination_folder_id_resolved` so subsequent runs skip the lookup.
- After 2–3 weeks of drafts, observe what your brand kit actually produces and update `templates.json → theme_signature`. Then rewrite each slot's `generation_prompt` to lock to that theme (LA pattern — see the original LA conversation transcript referenced in `docs/strategy.md`).
