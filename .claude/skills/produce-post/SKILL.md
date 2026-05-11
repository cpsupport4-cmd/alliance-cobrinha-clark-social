---
name: produce-post
description: Produce 4 Canva draft variants + caption + hashtags for a single slot in the current week. Pulls newest matching asset from Drive, generates 4 Canva designs with brand kit, saves draft URLs and copy to repo. Run when user says "produce <slot-id> [for this week]" or as part of daily-check.
---

# produce-post

The workhorse skill. Takes one slot ID, produces one complete review-ready package with **4 design variants** so Vinz can pick the strongest layout.

## Output policy: 4 designs per slot (locked 2026-05-09)

Every produce-post run materializes **4 Canva designs** in the Alliance Clark folder, not 1. Surfaced in `draft.json → canva_designs[]` and the operator report.

- **`mode: "fresh-generate"` (7B)** — Canva returns 4 candidates from one `generate-design` call; materialize all 4. They're genuinely different (different crops, layouts, text positions).
- **`mode: "registered-master"` (7A)** — call `merge-designs` 4 times to produce 4 working copies of the master page. Apply the same photo + overlay edits to each. The duplicates start identical, so Vinz can edit each independently in Canva (different crops, alternate overlay phrasings, etc.) without overwriting the others.

The first design (index 0) is the default pick for `post-approve` if the operator doesn't override.

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

**Run steps 1–9 below FOUR TIMES** (loop `variant_index` from 0 to 3) to produce 4 working-copy designs per the output policy. Each variant gets a distinct title suffix (`-v1`, `-v2`, `-v3`, `-v4`) and is moved into the Alliance Clark folder. Track each variant's `design_id` and `edit_url`; collect them into a `canva_designs[]` array for Step 10. If any single variant errors out, log the error against that variant index but continue with the remaining variants — partial success is acceptable as long as at least one variant lands.

1. **Read master config.** From `slot.master_template`: `design_id` (e.g. `DAHJC_QKr0U`), `page_index` (1–N), and `default_overlay_text`.

2. **Duplicate master page into a new design** — single tool call:
   ```
   merge-designs(
     type: "create_new_design",
     title: "<slot.day>-<iso_week>-<slug>-v<variant_index+1>",      // e.g. "FRI-2026-W19-train-grow-laugh-v1"
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

9. Capture the variant's final `design_id` and `edit_url`, append to the running `canva_designs[]` array as `{ index: <variant_index>, design_id, edit_url, view_url, status: "ok" }`. End of one loop iteration — return to step 2 with `variant_index += 1` until 4 variants exist.

After all 4 iterations: registered-master path complete with 4 working-copy designs, all sharing the same layout/photo/overlay but as independent designs Vinz can edit in parallel.

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
- **Materialize ALL 4 candidates** per the output policy. For each candidate (index 0-3):
  1. Call `create-design-from-candidate(job_id, candidate_id)`. Capture `design_id` and `edit_url`.
  2. **Banned-phrase post-check (mandatory).** Call `get-design-content(design_id, content_types: ["richtexts"])`. Aggregate all returned text, lowercase it. For each phrase in `brand/caption-pool.json → banned_phrases`, check `phrase.lower() in design_text.lower()`.
     - If clean: append to `canva_designs[]` as `{ index: <candidate_index>, design_id, edit_url, view_url, status: "ok" }`.
     - If a banned phrase is detected: append as `{ index: <candidate_index>, design_id, edit_url, status: "banned_phrase", offending_phrase: "<phrase>" }`. Do NOT skip — surface the variant in the report so the operator can decide whether to delete it from Canva. The other candidates may still be clean.
  3. Move the design into the `Alliance Clark` folder via `move-item-to-folder`.
- After all 4 materializations: if **all 4 hit banned phrases**, FAIL with `"All 4 generated candidates contain banned phrases. Canva's generate-design + brand kit ignored the prompt's banned-phrase instructions across the board. Re-run with a tighter generation_prompt that explicitly forbids the leaked phrases, or open one of the designs and edit manually."` Surface — don't silently proceed.
- If at least one variant is clean, proceed to Step 9. The clean variants are valid drafts; the dirty ones are flagged in `draft.json` for operator awareness.
- This check exists because the W19 FRI run (commit `0af2d40` aftermath) leaked "Join us:" into the design itself. The caption-library banned-phrase filter only covers `caption.md`; this check covers what `generate-design` puts INTO the visual.

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
    "mode_used": "registered-master | fresh-generate",
    "canva_designs": [
      { "index": 0, "design_id": "<id>", "edit_url": "<url>", "view_url": "<url>", "status": "ok", "is_primary": true },
      { "index": 1, "design_id": "<id>", "edit_url": "<url>", "view_url": "<url>", "status": "ok" },
      { "index": 2, "design_id": "<id>", "edit_url": "<url>", "view_url": "<url>", "status": "ok" },
      { "index": 3, "design_id": "<id>", "edit_url": "<url>", "view_url": "<url>", "status": "ok" }
    ],
    "canva_design_id": "<primary design_id — same as canva_designs[0].design_id; kept for backward-compat with post-approve>",
    "canva_edit_url": "<primary edit_url — same as canva_designs[0].edit_url; kept for backward-compat>",
    "source_asset": {
      "drive_file_id": "<fileId>",
      "drive_file_name": "<filename>",
      "canva_asset_id": "<asset_id>"
    },
    "brief_override_used": "<text or null>",
    "status": "draft"
  }
  ```
  Each entry's `status` is one of: `"ok"` (clean and ready), `"banned_phrase"` (materialized but contains banned text — review manually), `"error"` (creation failed; include an `error_message` field). The first variant with `status: "ok"` is marked `is_primary: true`. `post-approve` reads the primary unless the operator passes `--variant-index N` to override.
- `caption.md`: just the caption text (no frontmatter, ready to copy/paste)
- `hashtags.md`: hashtags one per line OR space-separated single line — match what IG paste-friendly looks like

### 11. Report to user

Surface back:

- Slot + week + mode used (registered-master vs fresh-generate)
- **All 4 Canva edit URLs**, in a numbered list, with the primary (`is_primary: true`) marked. Include each variant's status (`ok` / `banned_phrase` / `error`); flag dirty variants explicitly so the operator doesn't approve one by accident.
- Caption preview
- First 5 hashtags + total count
- File path of the slot dir for further edits
- Hint: "Vinz picks the strongest of the 4 in Canva. If the primary isn't the winner, run `/post-approve <slot-id> --variant-index <0..3>` to approve a different one."

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
| Banned phrase in fresh-generate output (7B post-check) | Per-variant: append `status: "banned_phrase"` to the variant's entry in `canva_designs[]`, surface in the report, but DO NOT halt — clean variants are still useful. Only halt if all 4 variants are dirty: "All 4 generated candidates contain banned phrases. Re-run with a tighter generation_prompt that explicitly forbids the leaked phrase, or open one design and edit manually." |
| Variant fails partway in 7A loop (`merge-designs` / transaction error on iteration N) | Append `status: "error"` with `error_message` to that variant's entry; continue with the remaining variants. Only halt if **all 4** iterations failed — surface the underlying cause (master deleted, transaction TTL, API outage). |
| Master template page not found at index | "Master design <id> doesn't have page <N>. Confirm For Clark V2 (DAHJC_QKr0U) page count and the master_template.page_index in templates.json." Halt — config mistake. |

## Notes for the operator

- Test with image-based slots first (`04-thu-kids-family` or `05-fri-community`). Video slots have an extra Drive URL edge case (`webContentLink` vs `lh3`).
- After the first successful run, update `templates.json → canva.brand_kit_id_resolved` and `canva.destination_folder_id_resolved` so subsequent runs skip the lookup.
- After 2–3 weeks of drafts, observe what your brand kit actually produces and update `templates.json → theme_signature`. Then rewrite each slot's `generation_prompt` to lock to that theme (LA pattern — see the original LA conversation transcript referenced in `docs/strategy.md`).
- **4-variant rate-limit awareness.** Each produce-post now makes ~4× the Canva API calls of the old single-design flow (4 `merge-designs` + 4 transactions in 7A; 4 `create-design-from-candidate` + 4 `get-design-content` + 4 `move-item-to-folder` in 7B). If you hit Canva rate limits during a busy week, drop the variant count to 2 in this file rather than 4. Don't drop to 1 — single-design output was the old failure mode that prompted this change.
- **Downstream impact: `post-approve`.** With 4 variants, `post-approve` needs a `--variant-index` argument (default 0 = primary). If the operator hasn't picked, the primary is approved. Update the post-approve skill to read `canva_designs[variant_index]` instead of `canva_design_id` directly. The legacy `canva_design_id` field is kept in `draft.json` for backward compatibility but should be considered an alias for `canva_designs[0]`.
- **Cleanup of unused variants.** When `post-approve` runs, the 3 unselected variants still live in the Alliance Clark Canva folder. They're useful as a record of what was generated, but clutter accumulates over time. A future `cleanup-variants` skill or a weekly cron could delete unselected variants older than 14 days.
