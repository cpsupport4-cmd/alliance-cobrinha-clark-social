# V2 Improvement Plan — Alliance Cobrinha Clark Social Automation

**Status:** Planned. Not implemented as of commit `c9345b7`. Resume here when ready.
**Last updated:** 2026-05-08 (W19)

---

## Where the system is today

After commit `c9345b7` ("Hybrid mode"):

- 7 slots configured, hybrid operating mode (Mon-Thu registered-master, Fri-Sun fresh-generate)
- 6 skills built: `produce-post`, `daily-check`, `weekly-status`, `caption-library`, `stories-pack`, `post-approve`
- Theme signature locked from observed published practice (`For Clark V2` page 4)
- One real produce-post run completed (W19 FRI Community)
- `For Clark V2` (`DAHJC_QKr0U`) registered as the master template document for Mon-Thu pages 1-4

The system is operational but has gaps that will surface as the team uses it weekly. This plan addresses the two highest-priority gaps the operator flagged, plus a prioritized list of additional improvements.

---

## Feature 1 — Used-asset archival in Drive

### Technical feasibility (verified 2026-05-08)

**Possible — with one mechanism adjustment from the original spec.**

Drive MCP tools confirmed available: `copy_file`, `create_file` (used for folders too), `search_files`, `get_file_metadata`, `get_file_permissions`.

Drive MCP tools NOT exposed: `delete_file`, `update_file_metadata` (can't change parents). This means we **can't truly move** a file — only copy. Original stays in the source folder.

**Mechanism adjustment:** the dated archive folder under each pillar still gets built (via `copy_file` + `create_file`), but it serves as a **human-facing organizational copy**, not the dedup mechanism. The actual "this asset has been used" check reads from the **repo** — every `content/*/approved/*/draft.json` already records `source_asset.drive_file_id`. Aggregating those gives a complete used-IDs set. `produce-post` filters its Drive search against that set.

Net user-visible behavior matches the original spec; only the under-the-hood data flow changes.

### Why it matters

`produce-post` currently picks the **newest** file from each Drive subfolder. After a post is published, the asset stays in the source folder. Two problems compound over time:

1. The same asset could be picked again on a future run if no newer file has been added — risk of accidental repeat posts
2. Source folders grow indefinitely; impossible to scan for "what's still fresh" vs "already used"

The team needs visibility into posting history at the asset level.

### What gets built

In every Drive pillar subfolder (`Community`, `Member Spotlights`, `Coach-Student`, `Kids & Family`, `Events / Group Photos`, `Leader Voice`), introduce an `archive/` container. Inside, date-named subfolders hold copies of assets that were used in approved posts:

```
Community/
├── archive/
│   ├── 2026-05-04/
│   │   └── photo_class_arrival.jpg     ← used in W19 MON post
│   ├── 2026-05-08/
│   │   └── photo_2026-05-08_10-09-58.jpg  ← used in W19 FRI post
│   └── ...
├── (active assets — not yet posted, available for next produce-post run)
└── ...
```

### Hook point

`post-approve` skill — when a draft is moved from `drafts/` to `approved/`, it also archives the source asset(s).

### Implementation steps (when ready to build)

1. **Add archival config to `templates.json`** under a new top-level key:
   ```json
   "archival": {
     "mode": "copy_only",
     "archive_subfolder_name": "archive",
     "date_folder_format": "YYYY-MM-DD",
     "dedup_source": "repo",
     "skip_archive_for_pillars": []
   }
   ```
   `mode: "copy_only"` is locked — the Drive MCP doesn't expose a delete operation, so move semantics aren't available. `dedup_source: "repo"` makes explicit that the used-IDs check reads from the repo, not from Drive folder structure.

2. **Update `.claude/skills/post-approve/SKILL.md`** with new step between current Step 5 (copy draft → approved) and Step 6 (drop-time reminder):

   - Read `draft.json → source_asset.drive_file_id`
   - Locate the asset's parent folder (the slot's pillar subfolder)
   - Check if `<parent>/archive/<YYYY-MM-DD>/` exists; create if not (use Drive `create_file` with mimeType `application/vnd.google-apps.folder`)
   - Copy the asset into the date folder via `copy_file`
   - Write `archived_assets` list back into `approved/draft.json` so the dedup logic in step 3 can find it

3. **Update `.claude/skills/produce-post/SKILL.md` Step 4 (Drive asset search) — the dedup logic:**
   - Before searching Drive, scan the repo: walk all `content/*/approved/*/draft.json` files (with `Glob` + `Read`), collect every `source_asset.drive_file_id` into a `used_ids` set
   - Drive search returns candidate files; filter the candidate list to drop any whose `id` is in `used_ids`
   - ALSO filter out any candidate whose `path` includes `/archive/` (defense in depth — keeps human-archived copies out of the running too)
   - Pick newest of what's left

4. **New skill: `unarchive`** for accidental archival. Inputs: slot ID + week. Removes the matching entry from `approved/draft.json → archived_assets` (so the asset re-enters the dedup-eligible pool) and optionally deletes the Drive copy in `archive/<date>/` via `copy_file` to a trash location (since no `delete_file`, manual cleanup may be needed).

5. **Optional one-shot: `bulk-archive-history`** — walks past `content/*/approved/` directories, collects every `source_asset.drive_file_id`, populates `archived_assets` lists retroactively, and copies the originals into dated archive folders in Drive. Useful when first turning the feature on so the slate isn't blank.

6. **No-op for `weekly-status`**: the read-only dashboard doesn't need to know about archival. The dedup logic is internal to `produce-post`. Optional enhancement: show "N assets used in 2026-W19" as a stat.

### Open questions for the operator

- **Date format?** `YYYY-MM-DD` is the working assumption. ISO-week format (`2026-W19`) would group archives by week instead of day — cleaner for weekly review. Worth deciding before backfilling.
- **Carousel posts (see Feature 2):** if a single post uses 5 assets, archive all 5? Yes — the `archived_assets` field in `approved/draft.json` becomes a list.
- **Unarchive cleanup:** when un-archiving, do we leave the Drive copy in `archive/<date>/` or rely on the operator to delete it manually via the Drive UI? Lacking `delete_file`, fully-clean unarchive isn't possible from the skill. Recommend: leave the Drive copy alone; only update the repo's `archived_assets` field. Drive copy clutter is a minor cosmetic problem, not a functional one.
- **What if Drive folder structure changes?** If Ram/Steph reorganize the pillar subfolders, the `archive/<date>/` folders inside might get orphaned. Detection: a quick sanity check in `weekly-status` that looks for archive folders in unexpected parents.

### Effort estimate

~3 hours of skill writing + testing. Most of the work is in `post-approve` (~50 lines added — the dated-folder creation + copy is straightforward) and `produce-post` Step 4 (~20 lines for the repo-scan + filter). One real-post test to confirm the archive folder gets created correctly and the next produce-post run skips the used asset.

---

## Feature 2 — Carousel skill (`produce-carousel`)

### Technical feasibility (verified 2026-05-08)

**Possible — with one piece needing run-time validation.**

Canva MCP tools confirmed available: `generate-design`, `generate-design-structured`, `create-design-from-candidate`, `start-editing-transaction`, `perform-editing-operations`, `commit-editing-transaction`, `get-design-pages`, `merge-designs`, `import-design-from-url`, `upload-asset-from-url`, `move-item-to-folder`, `resize-design`.

The clear-path pieces work:
- Cover slide via existing `registered-master` flow (already proven to be invocable in this MCP set)
- Each support slide via `generate-design` + `create-design-from-candidate` (proven by W19 FRI run)

**The one uncertainty:** `merge-designs` exists, but its actual behavior for combining a master-derived cover + multiple fresh-generated support slides into a single ordered multi-page Canva design hasn't been tested. Specifically:

- Does it preserve page order based on the input array?
- Does it handle the cover (which may have been derived from `For Clark V2` page N) plus N independently-generated 1-page designs?
- What's the resulting design's editability — is it one editable design, or a flattened/locked combination?

**Fallback if `merge-designs` doesn't behave as needed:** output each slide as its own Canva design, return the list of design IDs to the operator, and the team manually combines them in the Canva editor (drag-and-drop pages from the design list panel — Canva's UI supports this). That's still 70-80% automation vs. today's "build the whole carousel by hand."

So both branches are viable; the merge-designs branch is the prettier outcome but the slide-list fallback is reliably implementable today.

### Why it matters

The current `produce-post` skill makes a **single-slide** post. But the team's actual published pattern (Mon-Thu) is **multi-slide carousels** — `For Clark V2` is the cover page; the supporting slides are designed elsewhere or added manually. The system covers ~20% of the actual post construction work. Carousels are where:

- Member spotlights breathe (cover + 3-4 photos of the member's journey)
- Kids/Family posts show a class arc (cover + photos through the lesson)
- Value/Trust slots tell a longer story (cover + technique breakdown across slides)

Without carousel automation, Vinz manually composes 80% of every Mon-Thu post.

### What gets built

A new skill `produce-carousel` that produces a complete N-slide design (cover + supporting slides) for a single slot, given a concept brief.

### Inputs

- `slot_id` (required) — same 7 slot IDs as produce-post
- `concept` (required) — short brief like "Santi's first stripe ceremony" or "kids learning the closed guard"
- `slide_count` (optional, default 5) — total slides including cover, range 3-10
- `selection_mode` (optional, default `"concept-match"`) — one of:
  - `"concept-match"` — AI picks N most-relevant assets from the pillar subfolder based on concept brief
  - `"session-batch"` — pick all assets from the same shoot date (group by EXIF or modifiedTime cluster)
  - `"manual"` — operator provides a list of `drive_file_ids`

### Output structure

```
content/<iso-week>/<slot-id>/drafts/
├── draft.json                    ← carousel metadata, all slide refs
├── carousel/
│   ├── slide-1-cover.json        ← cover slide design ID + asset refs
│   ├── slide-2.json
│   ├── slide-3.json
│   └── ...
├── caption.md                    ← single caption for the whole carousel
└── hashtags.md
```

`draft.json` extended with:
```json
{
  "post_type": "carousel",
  "slide_count": 5,
  "concept": "...",
  "selection_mode": "concept-match",
  "slides": [
    {"index": 1, "role": "cover", "design_id": "...", "drive_file_id": "..."},
    {"index": 2, "role": "support", "design_id": "...", "drive_file_id": "..."},
    ...
  ]
}
```

### Two paths for slides 2-N

**Path A — Photo-only supporting slides (simpler).**

Cover comes from the registered master (For Clark V2 page N). Slides 2-N are full-bleed photos with optional minimal text overlay (1-2 word captions). This is what most BJJ Instagram carousels actually do.

Implementation: a single template page for "support slide" — full-bleed photo, optional bottom-right text overlay. Generated fresh each carousel.

**Path B — Designed supporting slides (richer).**

Slides 2-N use additional master pages — e.g., "stat callout slide" (large number + label), "quote slide" (centered pull quote), "before/after slide" (split layout). Requires the team to extend `For Clark V2` with these layouts.

Implementation: a `support_slide_templates` array in `templates.json` mapping slide roles to design IDs.

**Recommendation:** Start with Path A. Once the system is stable, add Path B for the slot types where richer supporting slides clearly beat photo-only (Member Spotlights especially).

### Implementation steps (when ready to build)

1. **Schema additions to `templates.json`**:
   - `slot.carousel_config`: { default_slide_count, support_slide_template_id, allow_concept_brief }
   - Top-level `carousel`: { default_selection_mode, max_slide_count, support_slide_aesthetic_prompt }

2. **Create `.claude/skills/produce-carousel/SKILL.md`** with steps:
   - Read slot config + concept brief
   - Search Drive for candidate assets matching concept (use `search_files` with concept keywords + filter to pillar subfolder)
   - Rank candidates: prefer link-shared, recent, distinct (no near-duplicates), variety of subjects
   - Pick top N
   - **Cover slide:** invoke produce-post-style logic, but force `slot.master_template` use (cover always uses master)
   - **Support slides:** for each, generate a single page via `generate-design` with the support_slide_aesthetic_prompt + uploaded asset
   - Combine into a single multi-page Canva design via `merge-designs` (if available) or as a folder of separate designs (fallback)
   - Generate one caption that frames the whole carousel
   - Write outputs

3. **Update `.claude/skills/post-approve/SKILL.md`** to handle carousel mode:
   - Approval applies to the whole carousel, not per-slide
   - Archive all source assets (Feature 1 integration)
   - Paste-ready post text references the multi-page design

4. **Update `.claude/skills/daily-check/SKILL.md`** to optionally invoke `produce-carousel` instead of `produce-post` when `slot.default_post_type == "carousel"`. Mon-Thu would default to carousel; Fri-Sun stay single-slide.

5. **New brief field in `_template/<slot>/brief.md`**: a `carousel_concept:` line where the operator can specify the day's concept ahead of time. If empty, the skill picks based on what's freshest in Drive.

### Open questions for the operator

- **Slide count default:** 5? 7? Depends on what your carousels typically are. If most are 4-5 slides, lock that default.
- **Concept brief — required or optional?** Required gives better results; optional lets the operator skip when there's no specific story. Recommend optional with a sensible default behavior.
- **Cover slide always from master, or optional?** Recommend always from master for Mon-Thu (consistency), free generate for Fri-Sun (no master exists yet — see Tier 1 #1).
- **Support slide template:** does the team want to design specific support templates (Path B), or are full-bleed photo slides enough for now (Path A)?
- **`merge-designs` test (technical):** before fully implementing, run a one-shot test: generate 3 single-page designs, call `merge-designs` on them, inspect whether the result is a single 3-page design with preserved order and editable elements. ~10 minutes of investigation. The answer determines whether we go full-merge or fall back to slide-list output. Do this before writing `produce-carousel/SKILL.md`.

### Effort estimate

Path A:
- ~10 min: `merge-designs` smoke test (resolves the uncertainty)
- ~4-6 hours: skill implementation + test run on one real slot

Path B: add another 2-4 hours for designing support templates and skill changes.

---

## Additional improvements (prioritized)

Beyond the two features above, here's a ranked list of other valuable additions. Format: `[effort] [impact] — name — what it does — why it matters`.

### Tier 1 — High impact, low effort (build these first)

1. **`[2h] [HIGH] Extend For Clark V2 to 7 pages.** Add Page 5 (FRI), Page 6 (SAT), Page 7 (SUN) masters to `For Clark V2`. Update `templates.json` to switch all 7 slots to `registered-master` mode. Result: zero-polish output for the entire week. Currently FRI/SAT/SUN are fresh-generate variability. **This is the single biggest win for visual consistency.**

2. **`[1h] [HIGH] Member roster JSON (`members.json`).** Holds every Clark member's name, journey hook, photo refs, last-featured date. TUE Member Story slot picks via rotation, never repeats within 2 months. Eliminates "who do we feature this week" guessing. Foundation for Feature 2's concept-match selection.

3. **`[1h] [HIGH] Brief-prefill via daily-check.** Currently `brief.md` overrides are optional and require operator typing them. Improvement: when daily-check runs, auto-pre-fill the brief based on context — newest member, upcoming event, recent milestone — leaving operator to confirm or adjust. Cuts brief-writing time to 30 seconds.

4. **`[1h] [HIGH] Content gap detector in `weekly-status`.** Warn when a Drive subfolder hasn't received new assets in N days. "Kids & Family folder hasn't seen a fresh photo in 5 days — Ram/Steph need a kids' class shoot before THU." Catches asset drought before it derails the system.

### Tier 2 — High impact, medium effort

5. **`[3h] [HIGH] Auto-export to Drive (`exports/`).** After `produce-post` completes, also export the design as a 1080x1350 PNG/JPG and save to `<drive_pillar_subfolder>/exports/<YYYY-MM-DD>/`. Two benefits: (1) team has a Drive-based archive of every post that doesn't depend on Canva uptime; (2) the export can be used directly as the IG asset without touching Canva at posting time.

6. **`[4h] [MEDIUM-HIGH] Performance feedback loop (Meta Business Suite integration).** When a Meta MCP becomes available, weekly: pull metrics for each posted slot (reach, saves, DM inquiries), tag winners in `approved/draft.json`, surface trends in `weekly-status`. Closes the loop between content and outcomes.

7. **`[3h] [MEDIUM] Multilingual caption support.** Add `language_mix` config to `caption-pool.json`. Per-pillar percentage of Tagalog vs English (e.g. SAT social proof might be 30% Tagalog for community signal, FRI community 100% English). Approved Tagalog phrases per pillar. Boosts local connection without losing English-audience reach.

8. **`[3h] [MEDIUM] Stories auto-export.** Currently `stories-pack` produces a Drive-link checklist. Improvement: also generate a 1080x1920 Canva story for each, export, and write to `content/<week>/stories/<date>/exports/`. Operator posts in 2 taps from phone instead of building stories from scratch.

### Tier 3 — Quality of life

9. **`[2h] [MEDIUM] Caption A/B variants.** `caption-library` produces 2-3 caption candidates per post. `produce-post` writes them all to `drafts/captions/`. Operator picks the winner during review. Track which voice patterns drive engagement (when feedback loop exists).

10. **`[2h] [LOW-MEDIUM] Cross-platform export.** Same approved post auto-formatted for Facebook Page (1:1), TikTok carousel, and Threads. Not all platforms are equally important for Clark, but extending reach for zero extra work is a win.

11. **`[1h] [LOW-MEDIUM] Weekly digest skill (`weekly-digest`).** Sunday auto-run. Pulls last week's metrics, identifies the best-performing post, suggests 1-2 tweaks for next week's plan. Becomes the input for Monday's daily-check.

12. **`[3h] [LOW-MEDIUM] Asset auto-tagging on Drive arrival.** Detect people (kids vs adults), activity (sparring vs technique vs hangout), composition (portrait vs group). Tag in Drive metadata. produce-post selection becomes much more accurate. Requires either a Drive trigger (cloud function) or a periodic batch skill.

### Tier 4 — Nice-to-have

13. **`[2h] [LOW] Theme rotation.** Once you have 3+ alternate aesthetics designed, randomly rotate weekly to avoid feed monotony while staying on-brand. Useful only after the master template library is rich.

14. **`[3h] [LOW] Auto-translate captions for Tagalog members.** When a member story features a Tagalog speaker, generate the English subtitle for English-only audience. Useful for ~20% of TUE Member Spotlight posts.

15. **`[6h] [LOW] IG/Meta scheduling.** When IG MCP supports scheduling, post-approve schedules the post at the slot's drop time automatically. Eliminates the manual posting step. Currently the human-in-the-loop is fine; only worth it if the operator finds posting at exactly 19:00 PHT a friction point.

---

## Recommended build order

If we resume this in one focused session:

1. **First:** Tier 1 #1 (extend For Clark V2 to 7 pages) — biggest win, fastest.
2. **Then:** Feature 1 (used-asset archival) — clear scope, durable improvement.
3. **Then:** Tier 1 #2 (members.json) — foundation for Feature 2.
4. **Then:** Feature 2 (produce-carousel, Path A only) — biggest behavior change.
5. **Then:** Tier 1 #3 + #4 (brief-prefill + content gap detector) — quality of life.
6. **Defer until after a month of operations:** Tier 2 onward. Real usage data should drive what's next.

---

## Notes for the operator

- **Test before building.** Each weekly run will reveal what's actually painful vs theoretically painful. Before implementing Feature 2, run the system for 2-3 weeks with the current single-slide skill and the manual carousel-completion-by-Vinz workflow. If carousel-completion is genuinely the time sink, build Feature 2. If something else (caption generation, drop-time scheduling, performance review) is the bigger drag, build that first instead.
- **Token budget.** This plan is the spec; implementation will burn tokens. Budget ~30-50k tokens per Tier 1 feature, ~80-150k for Feature 1 or Feature 2. Plan accordingly.
- **Rollback safety.** Every change should ship as its own commit so if something breaks, `git revert` is clean. The repo is the source of truth.
- **Skip what's not painful.** A feature that sounds good but doesn't address a real friction point is just complexity. The system you actually use beats the system you almost-built.
