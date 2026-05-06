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
