# Brand reference

The single source of truth for the Alliance Cobrinha Clark visual + voice system. Every skill in `.claude/skills/` reads from here.

---

## Canva brand kit

<https://canva.link/9dcx2ovypw69gig>

Auto-applies during Canva `generate-design` calls. Provides colors, typography, and logo placement. **Step 2** of the build will inspect this kit and lock concrete tokens (hex codes, font names, logo rules) into this file so they're available to skills without an MCP round-trip.

---

## Asset library — Google Drive

Parent folder: <https://drive.google.com/drive/folders/1wCB3ZwUhdMGCXUQvC48bUsp6aWcjL5_L>

**Sharing must be:** *Anyone with the link → Viewer.* Canva needs a publicly fetchable URL to upload assets.

### Subfolder mapping (working assumption)

| Subfolder | Used by slot(s) |
|-----------|----------------|
| Community | MON · Set the Tone, FRI · Community |
| Member Spotlights | TUE · Member Story |
| Coach-Student | WED · Value / Trust |
| Kids & Family | THU · Kids / Family |
| Events / Group Photos | SAT · Social Proof |
| Leader Voice | SUN · Leader Voice |

> Subfolder names confirmed against the live Drive (May 2026).

---

## Voice rules (for captions)

Source: [`../CLAUDE.md`](../CLAUDE.md) — single source of truth. Highlights:

- 1–2 lines max
- No voice overs in videos (silent clips + text)
- Banned: "Join now" · "Sign up" · "Limited slots" · generic fitness hype
- Real > polished · Faces > empty gym

The `caption-library` skill (Step 6) enforces banned-word filtering automatically.

---

## Visual identity — TWO LAYERS

This system has two visual identities to be aware of. **Practice supersedes documentation.**

### Layer 1 — Brand kit documentation (intent)

The Cobrinha Clark Brand Kit doc (Canva design `DAHGJQJqIGc`) describes a **black + gold + Helvetica** identity:

| Role | Token | Hex |
|------|-------|-----|
| Signature accent | Gold | `#FED52E` |
| Primary background | Black | `#000000` |
| Accent — near-black | Charcoal | `#0a0a06` |
| Accent — dark slate | Slate | `#26343b` |

Headlines: Helvetica Now. Subheads: Montserrat. Both sans-serif.

**This is the brand's stated intent.** The Canva brand kit `kAGdeHDeWjQ` is supposed to auto-apply these tokens during `generate-design`.

### Layer 2 — Published practice (reality)

What actually gets published is **radically simpler** — the canonical reference is `For Clark V2` (`DAHJC_QKr0U`), the team's working master design used for Mon–Thu carousel covers. Page 4 was published as the THU 2026-05-07 kids/family post.

**The published aesthetic:**

- **Full-bleed photo** — photo occupies 100% of canvas, edge to edge
- **No frames, no panels, no decorative shapes**
- **Text overlay** — white sans-serif, uppercase, stacked, bottom-right corner. 1–3 short lines max
- **No gold visible** — the documented signature color does not appear in published work
- **No graphic logo added** — brand presence comes from the gym wall wordmark visible in the photo itself, plus the IG account handle in the platform UI
- **Editorial / documentary** aesthetic — Magnum Photos meets restrained athletic brand. The photo is the design.

**Practice supersedes documentation.** When generating new posts, match Layer 2.

### Why the gap matters

The auto-apply Canva brand kit `kAGdeHDeWjQ` is shared between Clark and the LA build. It produces black + tan + serif (the LA aesthetic), not Clark's documented gold + black + Helvetica, and not Clark's published practice (full-bleed + minimal sans-serif overlay).

Confirmed in the W19 first-draft test — the Friday community post came back with a black frame + serif "Train. Laugh. Grow." headline, neither the documented nor the practiced aesthetic.

**Fix path (locked in `templates.json`):**

- For the high-leverage slots (Mon–Thu), use **registered-master mode** with For Clark V2 pages 1–4. The system duplicates the master and edits photo + text. Auto-apply kit is bypassed.
- For the remaining slots (Fri–Sun), use **fresh-generate** with prompts that explicitly forbid the auto-apply kit's defaults: "NO frames, NO gold, NO serif fonts, NO graphic logo." Override at the prompt level.

### Wordmark

`ALLIANCE JIU JITSU CLARK` — composed as `ALLIANCE JIU JITSU` + `by` + `D'Cobrinha` lockup. The `CLARK` badge is the dominant unit. **Used in the gym wall, not added to social posts.**

### Logo placement on social posts

- **No graphic logo added in design.** The published pattern relies on the wordmark visible in the gym (when the photo includes the wall) plus the IG account handle in the platform UI.
- The IG handle `@alliancecobrinhaclark` is NOT added to the design itself — it's already in the IG post UI.
- Safe zone: 80px on all edges of 1080×1350 frames.

### Photo treatment

- Full-bleed, edge-to-edge.
- No vignettes, no borders, no shape masks (no rounded corners, no circles).
- Composition must leave clean negative space (typically lower-right or lower-left) for the text overlay.
- Photo selection must match the slot's pillar — kids/family for THU, post-class warmth for FRI, full-room scale for SAT, leadership/wide-shot for SUN.

### Theme signature (locked from published practice, May 2026)

```
Background:        Photo is the background. Full-bleed.
Decorative:        None. Photo carries all visual weight.
Text overlay:      White, sans-serif (Helvetica), uppercase, stacked.
                   Bottom-right or bottom-left. 1-3 lines max.
                   No background panel — text directly on photo.
Logo:              None added in design. Brand from photo + IG UI.
Color:             None graphic. Photo provides all color.
Aesthetic:         Editorial / documentary. Anti-design.
```

For the structured version that skills read at runtime, see `templates.json → theme_signature`.
