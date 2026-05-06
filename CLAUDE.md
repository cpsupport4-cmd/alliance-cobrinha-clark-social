# Alliance Cobrinha Clark — Social Media Automation

Project context for Claude Code. Read this before doing anything in this repo.

---

## Mission

Grow **Alliance Cobrinha Clark** (Clark, Pampanga, Philippines) from **42 → 150 paid members** through community-first content. Word of mouth is the engine. Every post should make Clark feel like a place worth talking about.

- 65 active in Gymdesk · 42 paying · 23 active-but-not-paid (conversion target)
- 108 paid members still needed · 20–25 new paid / month target · 5–6 new paid / week

@alliancecobrinhaclark on Instagram.

---

## Voice & tone

Community-first. Not transactional. "Built Together."

- Short, punchy, warm captions — **1–2 lines max**
- No essays, no hype
- Real > polished · Faces > empty gym · Interaction > technique
- **No voice overs on videos** — let the footage breathe; silent clips with text captions only

### Banned phrases (never use)

- "Join now"
- "Sign up"
- "Limited slots"
- Generic fitness hype ("transform your body", "level up", etc.)
- Anything that smells like a sales pitch

### Replace with

- "This is what we're building."
- "This is how we train."
- "This is our community."
- "The mat is open. Come see what we're building."
- "42 members built this together. Come be part of what's next."

---

## Audience

50/50 split — every week's content must serve both.

- **Adults (50%)** — active professionals in their 30s, working parents, beginners with zero experience, expats and locals in the Clark area
- **Kids 6–12 (50%)** — discipline, confidence, focus. Parents are the conversion target — they watch from the sideline and decide

---

## The 4 pillars

Every piece of content maps to one of these.

1. **Community Content** — daily. Real people, real interactions. Show belonging in action.
2. **Member Spotlights** — 2–3× per week. Short, raw, honest member stories. Converts better than ads.
3. **Referral System** — ongoing. "Train Together" week — members can bring 1 friend / 1 parent / 1 sibling. No pressure, just invitation.
4. **Weekly Community Event** — 1× per week, rotating: Outdoor activity → Kids + Parents Day → Fundamentals Workshop → Community Roll + Coffee

---

## 7-day content calendar

The repeating template. Every week looks like this.

| Day | Slot | Pillar | Format | Goal |
|-----|------|--------|--------|------|
| MON | Set the Tone | Community | Class photo / raw video | Consistency + presence |
| TUE | Member Story | Spotlight | Short story or quote card | Relatability → conversion |
| WED | Value / Trust | Community | Coach talking — silent clip | Authority without intimidation |
| THU | Kids / Family | Community | Photo / event poster | Parent conversion (CRITICAL) |
| FRI | Community | Community | Raw photo, no voice over | Belonging |
| SAT | Social Proof | Community | Group photo, packed class | FOMO |
| SUN | Leader Voice | Community | 15–30 sec silent clip | Trust + leadership |

### Stories — non-negotiable

**5–10 IG stories every day.** Class clips, people arriving, small wins, kids moments, post-training conversations. Stories are where conversions actually happen.

---

## Asset library — Google Drive

Parent folder: <https://drive.google.com/drive/folders/1wCB3ZwUhdMGCXUQvC48bUsp6aWcjL5_L>

Six pillar-keyed subfolders. Slot → subfolder mapping:

| Slot | Drive subfolder |
|------|----------------|
| MON · Set the Tone | Community |
| TUE · Member Story | Member Spotlights |
| WED · Value / Trust | Coach-Student |
| THU · Kids / Family | Kids & Family |
| FRI · Community | Community |
| SAT · Social Proof | Events / Group Photos |
| SUN · Leader Voice | Leader Voice |

> Subfolder names confirmed against Drive (May 2026). Mixed media (images + videos) live in each pillar folder; per-slot format preference is set in `templates.json`.

Sharing must be **"Anyone with the link → Viewer"** so Canva can fetch assets via URL.

---

## Brand kit

Canva brand kit: <https://canva.link/9dcx2ovypw69gig>

Auto-applied during Canva generation. Captions inherit the brand voice from this file (`CLAUDE.md`), not from the brand kit.

---

## Roles

- **Ram & Steph** — Content & Media. Capture from the gym floor, drop into the right Drive subfolder.
- **Vinz** — Design. Polishes Canva drafts produced by the automation, edits reels.
- **Jeff / Adrian / Ram** — Approval. Final sign-off before any post goes live.
- **Vhinz (you)** — Operator. Runs Claude Code daily, reviews drafts, sends for approval.

Pipeline: **Content & Media → Design → Approval → Deploy**

---

## Daily workflow (D-3 → D-0)

- **D-3** — Ram / Steph drop raw assets in the matching Drive subfolder
- **D-2** — Run `daily-check` in Claude Code → produces Canva draft + caption + hashtags for tomorrow's slot
- **D-1** — Vinz polishes the Canva draft; Vhinz sends to approval channel
- **D-0** — Jeff / Adrian / Ram approve → Vhinz posts at the Manila drop time

### Drop times (Manila / PHT, UTC+8)

- Feed posts: **7:00 PM PHT** (evening peak — most members & prospects on phone)
- Stories: throughout the day, especially 7–9 AM and 7–10 PM

> First 4 weeks: track post performance and adjust. The 7 PM default is a starting point, not gospel.

---

## Operating mode

**Fresh-generate.** Every weekly run calls Canva's `generate-design` from scratch with the brand kit + a per-slot prompt. No registered master templates yet.

Tradeoff: layout varies week-to-week (~10–30%). Once Vinz settles on a layout he likes from the early runs, we'll convert that slot to a registered master and lock its visual.

Theme signature, generation prompts, and per-slot format preferences live in `templates.json` (built in Step 4).

---

## Effectiveness checkpoints

### Gymdesk (member & payment data)

- **Weekly:** new paid this week · total active in Gymdesk · churn / lapsed · active-vs-paid gap
- **Monthly:** total paid count vs 150 target · net new paid · retention rate vs prior month

### Meta Business Suite (content & reach data)

- **Weekly:** reach & impressions per post · saves per post (strongest signal) · DM inquiries from content · follower growth
- **Monthly:** best content type (Community / Spotlight / Event) · engagement rate trend · which posts drove inquiries

---

## When in doubt

- Real beats polished
- Faces beat empty gym
- Community beats technique
- Strip out anything that smells like sales
- The mat sells itself — the content's job is to make people show up

---

## Skills (built incrementally)

Lives in `.claude/skills/`. Catalog:

- `produce-post` — Drive → Canva → draft URL + caption + hashtags for one slot
- `daily-check` — entry point; finds tomorrow's slot, calls `produce-post`
- `weekly-status` — read-only dashboard of the current week
- `caption-library` — pillar-aware captions, banned-word filter, Clark hashtag pool
- `stories-pack` — generates 5–10 story-format drafts daily (Clark-specific)
- `post-approve` — moves draft → approved, schedules drop-time reminder

Each skill reads this file for context — don't restate strategy in skills, reference it.
