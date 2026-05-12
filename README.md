# Alliance Cobrinha Clark — Social Media Automation

Community-first social media for Alliance Cobrinha Clark (Clark, Pampanga). Built to scale the team from 42 → 150 paid members through Instagram. @alliancecobrinhaclark

This repo holds:

- The strategy ([CLAUDE.md](CLAUDE.md))
- A 7-day content template ([content/_template/](content/_template/))
- Brand reference ([brand/](brand/))
- Claude Code skills that automate Canva drafts + captions + hashtags ([.claude/skills/](.claude/skills/))

---

## Team

| Role | Person | Responsibility |
|------|--------|----------------|
| Content & Media | Ram, Steph | Capture from the gym floor → drop in Drive |
| Design | Vinz | Polish Canva drafts, edit reels |
| Approval | Jeff, Adrian, Ram | Final sign-off before posting |
| Operator | Vhinz | Runs Claude Code daily, sends drafts for approval |

---

## Daily workflow

```
Ram & Steph drop assets in Drive
        │
        ▼
Vhinz runs `daily-check` in Claude Code (D-2)
        │
        ▼
Canva draft + caption + hashtags → ready for review
        │
        ▼
Vinz polishes (D-1)
        │
        ▼
Jeff / Adrian / Ram approve
        │
        ▼
Vhinz posts at 7 PM PHT (D-0)
```

---

## Quick start (Vhinz / operator)

1. Clone the repo: `git clone https://github.com/cpsupport4-cmd/alliance-cobrinha-clark-social.git`
2. Open the folder in Claude Code
3. Make sure both **Canva** and **Google Drive** MCP connectors are enabled in your Claude Code project
4. Say: `weekly status` — confirms the system is alive
5. Say: `produce 04-thu-kids-family for this week` — generates a Thursday draft end-to-end (image-based slot, safest first test)

Strategy lives in [CLAUDE.md](CLAUDE.md). Anything Claude needs to do its job, that's the source.

---

## Repo conventions

- One folder per ISO week under `content/` (e.g. `content/2026-W19/`)
- Inside each week, the 7 day slots from `_template/` are copied in
- Raw assets in `raw/`, finished drafts in `drafts/`, approved posts in `approved/`
- Raw videos and exports are gitignored — they live in Drive

---

## What gets tracked in git

The repo is the **system** + the **audit trail of published posts**. Not drafts, not stories, not raw media. Locked 2026-05-12.

### ✅ Tracked (committed)

| Path | Why |
|------|-----|
| `CLAUDE.md` | Strategy + voice + workflow spec |
| `README.md` | Team-facing quick start (this file) |
| `.gitignore` | Ignore rules |
| `templates.json` | Per-slot config — Drive folder, master template, drop time, prompts |
| `brand/README.md` | Brand reference (colors, fonts, theme signature) |
| `brand/caption-pool.json` | Pillar tones, banned phrases, hashtag pools |
| `.claude/skills/*/SKILL.md` | The 6 skills that run the system |
| `docs/strategy.md` | Full PPTX strategy as structured markdown |
| `docs/improvement-plan.md` | V2 roadmap |
| `content/_template/*` | Per-day brief templates |
| `content/<week>/<slot>/approved/*` | **Audit trail of published posts** |
| `scripts/*` | Helper tooling (e.g. `weekly-status.sh`) |

### ❌ Not tracked (local-only, gitignored)

| Path | Why |
|------|-----|
| `content/<week>/<slot>/drafts/*` | Transient — regenerable via `produce-post` |
| `content/<week>/stories/*` | Daily story packs — transient |
| `content/<week>/<slot>/raw/*` | Raw media lives in Drive, not git |
| `content/_status_cache.json` | Local-only state |
| Canva exports (`.mp4`, `.mov`, etc.) | Ephemeral |

### Commit-and-push policy

**Only one skill in the system touches git: `post-approve`.** When a draft is approved, that skill commits the `approved/*` files for that one slot and pushes. Every other skill writes locally and stops — no auto-commit, no auto-push.

This keeps git history clean: one commit per published post, instead of churning with every produce-post run.

If the operator wants to commit something else (config changes, README edits, etc.), they run git themselves.
