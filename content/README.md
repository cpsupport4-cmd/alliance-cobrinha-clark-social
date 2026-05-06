# Content

Each ISO week gets its own folder. Copy `_template/` to `<year>-W<week>/` every Monday.

```
content/
├── _template/                ← copy this each week
│   ├── 01-mon-set-the-tone/
│   ├── 02-tue-member-story/
│   ├── 03-wed-value-trust/
│   ├── 04-thu-kids-family/
│   ├── 05-fri-community/
│   ├── 06-sat-social-proof/
│   └── 07-sun-leader-voice/
└── 2026-W19/                 ← example: this week's slate
    ├── 01-mon-set-the-tone/
    │   ├── brief.md          ← optional steering input
    │   ├── raw/              ← raw assets (gitignored — pulled from Drive)
    │   ├── drafts/           ← Canva draft URL + caption + hashtags
    │   └── approved/         ← final approved version (post-approve skill writes here)
    └── ...
```

Skills will read/write under each slot folder. The `_template/` is what they clone.
