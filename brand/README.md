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

## Visual identity (observed from brand kit doc `DAHGJQJqIGc`, May 2026)

### Wordmark

`ALLIANCE JIU JITSU CLARK` — composed as `ALLIANCE JIU JITSU` + `by` + `CLARK` lockup. The `CLARK` badge is the dominant logo unit on social posts.

### Colors

| Role | Token | Hex |
|------|-------|-----|
| Signature accent | Gold | `#FED52E` |
| Primary background | Black | `#000000` |
| Inverted background | White | `#FFFFFF` |
| Accent — near-black | Charcoal | `#0a0a06` |
| Accent — dark slate | Slate | `#26343b` |

The signature color is **gold (#FED52E) on black**. White is the inverted variant. Slate (#26343b) is for secondary surfaces/cards. Use sparingly — the gold is the brand.

### Typography

| Role | Font |
|------|------|
| Headline | **Helvetica Now** |
| Subheadline / body | **Montserrat** |

Both sans-serif. No serif anywhere. Modern, athletic, clean — consistent with the BJJ + community-first positioning, not the LA build's serif aesthetic.

### Notes for generation

- Canva brand kit ID auto-applies during `generate-design`. ID: `kAGdeHDeWjQ` (unnamed kit, the only one besides "Nazareth Consulting" in this account).
- The brand kit may contain different visual tokens than the documentation design — when the first `produce-post` run lands, compare its output against this section and patch if drift is observed (LA pattern).
- If generate-design produces black + gold output: documentation matches the auto-apply kit.
- If it produces black + tan/beige (LA's aesthetic): the auto-apply kit is shared with LA and Clark's gold isn't actually configured in Canva. Fix would be to either configure Clark colors in the kit, OR add explicit color references to each slot's `generation_prompt` in `templates.json`.

### Logo placement (working assumption — refine after first draft)

- Bottom-right corner of every post: `@alliancecobrinhaclark` text mark
- Wordmark / CLARK badge: top-left or top-center on hero designs (Saturday social proof, Sunday leader voice especially)
- Safe zone: 80px on all edges of 1080×1350 / 1080×1920 frames

### Photo treatment

- Hero image dominates the composition (60–70% of canvas)
- Black or slate borders / vignettes acceptable
- Gold should appear as text accent or small decorative element, NOT large fill (loud at scale)

### Theme signature (locked May 2026 — pre-first-draft)

```
Background:        Black dominant, slate accents on cards
Decorative motifs: Gold rule lines, gold underlines on key headlines
Headline:          HELVETICA NOW, white or gold, top-left or top-center
Subhead:           MONTSERRAT, white at 70% opacity
Photo:             Hero photo full-bleed or large frame, no shape masks
Logo:              CLARK wordmark or @handle bottom-right
```

Refine after observing the first 2–3 generated drafts.
