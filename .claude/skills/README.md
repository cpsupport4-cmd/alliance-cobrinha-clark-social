# Skills catalog

Each skill is a folder under `.claude/skills/<name>/` containing a `SKILL.md`. Claude Code reads these automatically when this repo is open.

---

## Planned skills (built in Step 5+)

| Skill | Purpose | Step |
|-------|---------|------|
| `produce-post` | Drive → Canva → draft URL + caption + hashtags for one slot | 5 |
| `daily-check` | Finds tomorrow's slot, calls `produce-post` | 5 |
| `weekly-status` | Read-only dashboard for the current week | 5 |
| `caption-library` | Pillar-aware captions, banned-word filter | 6 |
| `stories-pack` | Generates 5–10 story-format drafts daily | 6 |
| `post-approve` | Moves draft → approved, schedules drop-time reminder | 7 |

Skills aren't built yet. Step 1 only scaffolds the project.

---

## Conventions for future skills

- Read `CLAUDE.md` for strategy — never duplicate strategy in a skill
- Read `templates.json` for slot config (Drive subfolder, generation prompt, format preference)
- Read `brand/caption-pool.json` for caption examples + hashtag pools (built in Step 6)
- Surface failure modes back to the user with actionable messages — don't fail silently
