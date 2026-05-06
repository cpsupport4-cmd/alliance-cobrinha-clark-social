# Skills catalog

Each skill lives in `.claude/skills/<name>/SKILL.md`. Claude Code reads them automatically when this repo is open.

The skills are designed to run in a Claude session that has **Canva** and **Google Drive** MCPs connected (e.g. claude.ai with both connectors enabled). The skill files themselves are pure markdown — Claude follows them as instructions.

---

## Catalog

| Skill | Purpose | Run when |
|-------|---------|----------|
| [`produce-post`](produce-post/SKILL.md) | Produces one Canva draft + caption + hashtags for a single slot | "produce 04-thu-kids-family for this week" |
| [`daily-check`](daily-check/SKILL.md) | Morning entry point — finds tomorrow's slot and runs `produce-post` | "daily check" — every morning, 9–10 AM PHT |
| [`weekly-status`](weekly-status/SKILL.md) | Read-only dashboard: state of all 7 slots in current week | "weekly status" — anytime |
| [`caption-library`](caption-library/SKILL.md) | Generates one on-brand caption + ~15 hashtags for a pillar | invoked by `produce-post`, or directly to refresh copy |
| [`stories-pack`](stories-pack/SKILL.md) | Generates a 5–10 story pack from recent Drive assets (CLAUDE.md says non-negotiable) | "stories pack" — every day |
| [`post-approve`](post-approve/SKILL.md) | Moves draft → approved, builds paste-ready post.md, surfaces drop-time reminder | "approve 04-thu-kids-family" — after Jeff/Adrian/Ram sign off |

---

## Daily flow (typical day)

```
~9 AM PHT     daily-check
              → reads tomorrow's slot
              → pulls newest asset from Drive
              → generates Canva draft
              → drafts caption + hashtags
              → drops everything in content/<week>/<slot>/drafts/

morning       Vhinz reviews draft in Canva, sends to Vinz for design polish

afternoon     Vinz polishes design in Canva
              Vhinz sends draft URL to approval channel (Jeff / Adrian / Ram)

approval      approve <slot-id>
              → moves to approved/, builds paste-ready post.md

7 PM PHT      Vhinz posts manually from phone or desktop
              touches .posted marker (or runs mark-posted)

throughout    stories-pack (run once a day, post the 5–10 stories on rolling schedule)
```

---

## Conventions

- **Read `CLAUDE.md` for strategy.** Skills must never duplicate strategy text — reference it.
- **Read `templates.json` for slot config.** Slot ID, Drive subfolder, generation prompt, drop time all live there.
- **Read `brand/caption-pool.json` for copy + hashtag config.** Editable without touching skill code.
- **Surface failure modes with actionable messages.** Each SKILL.md has a "Failure modes" table — keep it honest.
- **Don't silently overwrite drafts.** Ask before regenerating.

---

## Run prerequisites (for the operator)

1. **Canva MCP** connected with full design scopes (`generate-design`, `create-design-from-candidate`, `upload-asset-from-url`, etc.)
2. **Google Drive MCP** connected with read access to folder `1wCB3ZwUhdMGCXUQvC48bUsp6aWcjL5_L`
3. Drive folder sharing: **"Anyone with the link → Viewer"**
4. Brand kit at `https://canva.link/9dcx2ovypw69gig` accessible to the connected Canva account

If any of these are missing, the skills will fail with clear error messages — they don't try to recover silently.
