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

> If the actual Drive subfolder names differ from this list, update `templates.json` (Step 4) — don't rename the Drive.

---

## Voice rules (for captions)

Source: [`../CLAUDE.md`](../CLAUDE.md) — single source of truth. Highlights:

- 1–2 lines max
- No voice overs in videos (silent clips + text)
- Banned: "Join now" · "Sign up" · "Limited slots" · generic fitness hype
- Real > polished · Faces > empty gym

The `caption-library` skill (Step 6) enforces banned-word filtering automatically.

---

## To be filled in (Step 2)

- [ ] Primary color (hex)
- [ ] Secondary color (hex)
- [ ] Accent color (hex)
- [ ] Headline font name
- [ ] Body font name
- [ ] Logo placement rule (corner / size / safe zone)
- [ ] Photo treatment (frame / full-bleed / shape mask)
- [ ] Theme signature description (decorative motifs, layout pattern)
